#!/usr/bin/env python3
"""Restore, export and automatically publish Aegis history from Actions.

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
import tempfile
import zipfile

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


def publication_target(source):
    """Only the same-repository PR head may receive this run's records."""
    if os.environ.get('GITHUB_ACTIONS') != 'true' or os.environ.get('GITHUB_EVENT_NAME') != 'pull_request':
        raise RuntimeError('automatic publication requires a pull-request Actions workspace')
    repository = os.environ['GITHUB_REPOSITORY']
    branch = os.environ['AEGIS_PUBLICATION_BRANCH']
    if (os.environ['AEGIS_PUBLICATION_REPOSITORY'] != repository
            or branch == os.environ['AEGIS_PUBLICATION_BASE']
            or not branch.startswith('metarocq/')):
        raise RuntimeError('publication is restricted to the same-repository metarocq PR head')
    from pipelines.publish import git
    git(ROOT, 'check-ref-format', 'refs/heads/' + branch)
    remote = git(ROOT, 'remote', 'get-url', 'origin')
    if remote.removesuffix('.git') != 'https://github.com/' + repository:
        raise RuntimeError('unexpected publication remote')
    observed = git(ROOT, 'ls-remote', '--exit-code', 'origin', 'refs/heads/' + branch).split()[0]
    if observed != source['source_commit']:
        raise RuntimeError('PR head advanced; preserve artifacts for exact-history recovery')
    return branch


def publish_records():
    """Reuse Aegis's non-forcing publisher; no model-written logging or commits."""
    from agentinfra.security import confined_path
    from pipelines.publish import git, publish
    source = identity()
    branch = publication_target(source)
    receipt = json.loads((OUT / 'persistence.json').read_text())
    if (receipt['identity'] != source
            or receipt['snapshot_sha256'] != digest(FRAMEWORK / 'data/manifest.json')):
        raise RuntimeError('publication receipt does not bind this exact source and snapshot')
    snapshot = json.loads((FRAMEWORK / 'data/manifest.json').read_text())
    for name, checksum in snapshot['files'].items():
        if digest(confined_path(FRAMEWORK, name, must_exist=True)) != checksum:
            raise RuntimeError('logical export changed before publication')
    if list((FRAMEWORK / 'data/pending').rglob('*.json')):
        raise RuntimeError('pending database writes block publication acceptance')
    if not os.environ.get('GH_TOKEN'):
        raise RuntimeError('publication credential unavailable')
    run = source['run_id']
    attempt = source['run_attempt']
    if not run.isdigit() or not attempt.isdigit():
        raise RuntimeError('invalid run identity')
    archive = ROOT / 'metatheory/evidence' / f'checker-run-{run}-{attempt}.zip'
    if archive.exists():
        raise RuntimeError('run archive already exists; do not overwrite history')
    with zipfile.ZipFile(archive, 'x', compression=zipfile.ZIP_DEFLATED) as bundle:
        for path in sorted(OUT.rglob('*')):
            if path.is_symlink():
                raise RuntimeError('redirected replay artifact')
            if path.is_file():
                bundle.write(path, path.relative_to(OUT).as_posix())
    # checkout deliberately used the exact source SHA, so attach a local branch
    # only after verifying the remote is still at that SHA. Push stays non-forcing.
    git(ROOT, 'switch', '-c', branch)
    git(ROOT, 'config', 'user.name', 'github-actions[bot]')
    git(ROOT, 'config', 'user.email', '41898282+github-actions[bot]@users.noreply.github.com')
    with tempfile.TemporaryDirectory(prefix='aegis-askpass-') as folder:
        askpass = Path(folder) / 'askpass'
        # The helper contains no credential and Git receives it via its private
        # authentication pipe. Checkout never persists the token in repository config.
        askpass.write_text('#!/bin/sh\ncase "$1" in\n*Username*) printf "%s\\n" x-access-token ;;\n*) printf "%s\\n" "$GH_TOKEN" ;;\nesac\n')
        askpass.chmod(0o700)
        names = ('GIT_ASKPASS', 'GIT_TERMINAL_PROMPT', 'GIT_CONFIG_COUNT', 'GIT_CONFIG_KEY_0', 'GIT_CONFIG_VALUE_0')
        before = {name: os.environ.get(name) for name in names}
        os.environ.update(GIT_ASKPASS=str(askpass), GIT_TERMINAL_PROMPT='0',
                          GIT_CONFIG_COUNT='1', GIT_CONFIG_KEY_0='credential.helper', GIT_CONFIG_VALUE_0='')
        try:
            published = publish(FRAMEWORK, ROOT, [archive.relative_to(ROOT).as_posix()])
        finally:
            for name, value in before.items():
                if value is None:
                    os.environ.pop(name, None)
                else:
                    os.environ[name] = value
    result = {'schema': 1, 'identity': source, **published,
              'snapshot_sha256': receipt['snapshot_sha256'], 'archive_sha256': digest(archive),
              'task_status': 'BLOCKED', 'claim': 'Exact Git publication only; no formal proof acceptance'}
    # No database event follows publication: that would require another push.
    (OUT / 'publication.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps(result))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=('init', 'export', 'publish'))
    args = parser.parse_args()
    try:
        {'init': initialize, 'export': export, 'publish': publish_records}[args.command]()
    except Exception as error:
        # PostgreSQL connection diagnostics may contain credential material.
        print(json.dumps({'status': 'BLOCKED', 'error_type': type(error).__name__,
                          'reason': 'CI persistence failed; no formalization advancement'}), file=sys.stderr)
        raise SystemExit(2)
