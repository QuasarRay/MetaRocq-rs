#!/usr/bin/env python3
"""Run observable bootstrap processes; missing formal evidence always blocks."""
from __future__ import annotations

import argparse
import base64
from dataclasses import asdict
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import subprocess
import sys

FRAMEWORK = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(FRAMEWORK), str(FRAMEWORK / 'infra')]
from agentinfra.process import run_process
from database.store import Store
from database.codec import canonical, sha
from pipelines import roadmap
from pipelines.publish import publish


def runtime_identity():
    files = {}
    for directory in ('database', 'pipelines', 'infra/agentinfra'):
        for p in sorted((FRAMEWORK / directory).glob('*.py')):
            files[p.relative_to(FRAMEWORK).as_posix()] = sha(p.read_bytes())
    files['database/schema.sql'] = sha((FRAMEWORK / 'database/schema.sql').read_bytes())
    return sha(canonical(files).encode())


def status(root, doc, tasks, store):
    external = {}
    # References are deliberately outside tracked target source; bind their live
    # revision and cleanliness so a changed source checkout cannot reuse an audit.
    for source in doc.get('sources', []):
        path = root / '.aegis/references' / source['id']
        try:
            external[source['id']] = [subprocess.check_output(
                ['git', '-C', str(path), *args], stderr=subprocess.DEVNULL).decode().strip()
                for args in (['rev-parse', 'HEAD'], ['status', '--porcelain', '--untracked-files=all'])]
        except (OSError, subprocess.CalledProcessError):
            external[source['id']] = None
    runtime = sha(canonical({'code': runtime_identity(), 'external': external, 'python': sys.version}).encode())
    result = roadmap.states(root, doc, tasks, store.events(), runtime)
    gate = result[doc['policy']['implementation_gate']]
    return {'roadmap': doc['id'], 'metatheory_complete': False,
            'implementation_allowed': False, 'gate': gate, 'tasks': result,
            'claim': 'process observations never establish metatheory equivalence'}


def execute(root, doc, tasks, store, task_id, timeout):
    current = status(root, doc, tasks, store)['tasks'][task_id]
    if current['status'] != 'READY':
        return current
    task = next(t for t in tasks if t['id'] == task_id)
    fingerprint = current['identity']
    now = lambda: datetime.now(timezone.utc).isoformat()
    # Full declared context is captured automatically; input files need no agent narration.
    context = {name: base64.b64encode((root / name).read_bytes()).decode() for name in task['inputs']}
    old_outputs = {name: base64.b64encode((root / name).read_bytes()).decode()
                   for name in task['acceptance']['required_artifacts'] if (root / name).is_file()}
    store.append({'kind': 'task_started', 'task': task_id, 'identity': fingerprint,
                  'time': now(), 'roadmap': doc, 'context_base64': context,
                  'previous_artifacts_base64': old_outputs, 'argv': task['command']})
    # Prior bytes have already been durably captured. Require a fresh output set.
    for name in old_outputs:
        (root / name).unlink()
    try:
        def sink(stream, chunk):
            store.append({'kind': 'process_output', 'task': task_id, 'identity': fingerprint,
                          'time': now(), 'stream': stream, 'base64': base64.b64encode(chunk).decode()})
        result = run_process(task['command'], cwd=root, timeout=timeout, event_sink=sink)
        outputs = roadmap.identities(root, task['acceptance']['required_artifacts'])
        unchanged = fingerprint == status(root, doc, tasks, store)['tasks'][task_id]['identity']
        ok = result.returncode == 0 and not result.timed_out and all(outputs.values()) and unchanged
        observation = {'kind': 'task_finished', 'task': task_id, 'identity': fingerprint, 'time': now(),
                       'outcome': 'OBSERVED' if ok else 'FAILED', 'outputs': outputs,
                       'process': asdict(result), 'inputs_unchanged': unchanged,
                       'claim': 'declared process completed; no formal theorem was accepted'}
        store.append(observation)
        return observation
    except BaseException:
        # Already-read output survives in the durable outbox if the DB failed.
        # An unmatched task_started is an interrupted attempt, never a completion.
        raise


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', required=True, type=Path)
    parser.add_argument('--roadmap', type=Path, default=FRAMEWORK / 'roadmaps/metarocq-bootstrap.json')
    subs = parser.add_subparsers(dest='command', required=True)
    subs.add_parser('validate')
    subs.add_parser('gate')
    subs.add_parser('status')
    recovery = subs.add_parser('recover')
    recovery.add_argument('--task', required=True)
    run = subs.add_parser('run')
    run.add_argument('--task', required=True)
    run.add_argument('--timeout', type=int, default=120)
    capture = subs.add_parser('capture-host')
    capture.add_argument('--task', required=True)
    capture.add_argument('--events', type=Path, required=True,
                         help='host-exported public event JSONL; no private reasoning channel')
    args = parser.parse_args(argv)
    root = args.root.resolve(strict=True)
    doc, tasks = roadmap.load(args.roadmap)
    if args.command == 'validate':
        print(canonical({'valid': True, 'tasks': len(tasks), 'implementation_allowed': False}))
        return 0
    if args.command == 'gate':
        print(canonical({'implementation_allowed': False, 'status': 'BLOCKED',
                         'gate': doc['policy']['implementation_gate'],
                         'reason': 'qualified independent proof replay adapter is not implemented'}))
        return 2
    # DSN stays in this supervisor process; it is not propagated to workers.
    task_id = getattr(args, 'task', None)
    store = Store(os.environ['AEGIS_DATABASE_DSN'], FRAMEWORK, task=task_id)
    try:
        store.exclusive()
        if task_id:
            store.recover()
        else:
            store.export()
        outputs = sorted({p for t in tasks for p in t['acceptance']['required_artifacts'] if (root / p).exists()})
        if args.command == 'status':
            out = status(root, doc, tasks, store)
        elif args.command == 'capture-host':
            for line in args.events.read_text().splitlines():
                packet = json.loads(line)
                if packet.get('channel') not in {'user', 'assistant_final', 'assistant_commentary', 'tool', 'action', 'context'}:
                    raise ValueError('only exposed host event channels may be captured')
                store.append({'kind': 'host_event', 'task': task_id, 'event': packet})
            out = {'captured': True}
        elif args.command == 'recover':
            out = {'recovered': True}
        else:
            # Publication of all prior writes is a prerequisite to new work.
            publish(FRAMEWORK, root, outputs)
            out = execute(root, doc, tasks, store, task_id, args.timeout)
            outputs = sorted(set(outputs) | {p for t in tasks for p in t['acceptance']['required_artifacts'] if (root / p).exists()})
        store.export()
        receipt = publish(FRAMEWORK, root, outputs)
        print(canonical({'result': out, 'publication': receipt}))
        return 2 if out.get('outcome') == 'FAILED' or out.get('status') == 'BLOCKED' else 0
    finally:
        store.close()  # PostgreSQL releases the global session lock on disconnect.


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (Exception,) as exc:
        # Connection diagnostics can contain DSNs; do not persist or print credentials.
        print(canonical({'status': 'BLOCKED', 'error_type': type(exc).__name__,
                         'reason': 'execution or persistence gate failed; no advancement'}), file=sys.stderr)
        raise SystemExit(2)
