#!/usr/bin/env python3
"""Restore the committed Aegis history in Actions; export it before teardown.

Administration is confined to init. Replay/export use the existing task login,
Store, append-only schema and sequential lock. Upload is pending publication,
never a durable-Git receipt or permission to advance the formalization roadmap.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import secrets
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
FRAMEWORK = ROOT / '.agents'
OUT = ROOT / '.aegis/original-checker'
TASK = 'original-source-and-checker'
PRINCIPAL = 'aegis_mr_original_source_and_checker'
sys.path[:0] = [str(FRAMEWORK), str(FRAMEWORK / 'infra')]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def identity():
    git = lambda *args: subprocess.check_output(['git', *args], cwd=ROOT, text=True).strip()
    value = {'source_commit': git('rev-parse', 'HEAD'),
             'source_tree': git('rev-parse', 'HEAD^{tree}'),
             'aegis_commit': json.loads((ROOT / 'spec/aegis-deployment.json').read_text())['commit']}
    if os.environ.get('GITHUB_ACTIONS') == 'true':
        if value['source_commit'] != os.environ['AEGIS_CHECKER_SOURCE_SHA']:
            raise RuntimeError('checkout does not match the requested replay source')
        value.update(workspace='github-actions', repository=os.environ['GITHUB_REPOSITORY'],
                     run_id=os.environ['GITHUB_RUN_ID'], run_attempt=os.environ['GITHUB_RUN_ATTEMPT'],
                     workflow_ref=os.environ['GITHUB_WORKFLOW_REF'],
                     workflow_commit=os.environ['GITHUB_WORKFLOW_SHA'])
    else:
        value['workspace'] = 'local'
    return value


def initialize():
    if os.environ.get('GITHUB_ACTIONS') != 'true':
        raise RuntimeError('CI provisioning requires an Actions workspace')
    source = identity()
    if list((FRAMEWORK / 'data/pending').rglob('*.json')):
        raise RuntimeError('unpublished outbox must be recovered before CI provisioning')
    before = {p: digest(p) for p in (FRAMEWORK / 'data').rglob('*') if p.is_file()}
    # Reuse the supervisor entrypoint: exact historical actors/UUIDs and the
    # complete snapshot chain are checked by database.admin.restore.
    for args in (['init'], ['restore', str(FRAMEWORK)]):
        subprocess.run([sys.executable, '-B', str(FRAMEWORK / 'database/admin.py'), *args], check=True)
    import psycopg
    from psycopg import sql
    from psycopg.conninfo import make_conninfo
    from database.store import Store
    password = secrets.token_urlsafe(32)
    with psycopg.connect(os.environ['AEGIS_ADMIN_DSN'], autocommit=True) as connection:
        if not connection.execute('SELECT pg_try_advisory_lock(7351,1)').fetchone()[0]:
            raise RuntimeError('another sequential worker is active')
        connection.execute(sql.SQL('ALTER ROLE {} PASSWORD {}').format(
            sql.Identifier(PRINCIPAL), sql.Literal(password)))
    dsn = make_conninfo(os.environ['AEGIS_ADMIN_DSN'], user=PRINCIPAL, password=password)
    # Make failure-path recovery available before the first new event write.
    # Credentials are ephemeral, masked, and never recorded in events/files.
    print('::add-mask::' + password)
    print('::add-mask::' + dsn)
    with open(os.environ['GITHUB_ENV'], 'a') as environment:
        environment.write('AEGIS_TASK_DSN=' + dsn + '\n')
    store = Store(dsn, FRAMEWORK, TASK)
    try:
        store.exclusive()
        restored = store.export()
        if any(digest(p) != checksum for p, checksum in before.items()):
            raise RuntimeError('restore/export changed committed history')
        store.append({'kind': 'ci_runtime_started', 'identity': source,
                      'restored_heads': restored['heads'], 'restored_events': restored['events'],
                      'restored_manifest_sha256': before[FRAMEWORK / 'data/manifest.json'],
                      'runtime': 'Actions-backed PostgreSQL; local workspace unavailable',
                      'claim': 'persistence activation only; formal task remains blocked'})
    finally:
        store.close()
    print(json.dumps({'status': 'ACTIVE', 'identity': source, 'restored_events': restored['events']}))


def export():
    from database.store import Store
    source = identity()
    store = Store(os.environ['AEGIS_TASK_DSN'], FRAMEWORK, TASK)
    try:
        store.exclusive()
        store.recover()
        replay_manifest = OUT / 'manifest.json'
        store.append({'kind': 'ci_export_pending_publication', 'identity': source,
                      'job_status': os.environ['AEGIS_JOB_STATUS'],
                      'replay_manifest_sha256': digest(replay_manifest) if replay_manifest.is_file() else None,
                      'task_status': 'BLOCKED', 'publication_status': 'PENDING_GIT_IMPORT',
                      'claim': 'No subsequent formal task may start before complete export publication'})
        snapshot = store.export()
        OUT.mkdir(parents=True, exist_ok=True)
        receipt = {'schema': 1, 'identity': source, 'events': snapshot['events'],
                   'heads': snapshot['heads'],
                   'snapshot_sha256': digest(FRAMEWORK / 'data/manifest.json'),
                   'publication_status': 'PENDING_GIT_IMPORT', 'task_status': 'BLOCKED',
                   'claim': 'Complete logical Aegis export; artifact upload is not Git publication'}
        (OUT / 'persistence.json').write_text(json.dumps(receipt, indent=2) + '\n')
        print(json.dumps(receipt))
    finally:
        store.close()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=('init', 'export'))
    args = parser.parse_args()
    try:
        {'init': initialize, 'export': export}[args.command]()
    except Exception as error:
        # PostgreSQL connection diagnostics may contain credential material.
        print(json.dumps({'status': 'BLOCKED', 'error_type': type(error).__name__,
                          'reason': 'CI persistence failed; no formalization advancement'}), file=sys.stderr)
        raise SystemExit(2)
