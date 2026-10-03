"""Validate a runtime DAG and invalidate observations when their inputs change."""
from __future__ import annotations

import json
from pathlib import Path, PurePosixPath
import re

from database.store import canonical, sha
from agentinfra.security import confined_path


def relative(name):
    if not isinstance(name, str) or not name or '\\' in name:
        raise ValueError('expected canonical relative path')
    p = PurePosixPath(name)
    if p.is_absolute() or '..' in p.parts or p.as_posix() != name or name == '.':
        raise ValueError('expected canonical relative path')
    return name


def load(path):
    doc = json.loads(Path(path).read_text())
    policy = doc['policy']
    if doc['schema'] != 1 or policy['max_active_agents'] != 1 or policy['reasoning_effort'] != 'max':
        raise ValueError('sequential maximum-effort policy required')
    if policy['formalization_model'] != 'gpt-6-astra':
        raise ValueError('formalization requires the authorized model')
    tasks = doc['tasks']
    by_id = {}
    for task in tasks:
        if not re.fullmatch('[a-z][a-z0-9-]{0,95}', task['id']) or task['id'] in by_id:
            raise ValueError('invalid or duplicate task id')
        if task['kind'] not in {'bootstrap', 'formalization', 'roadmap', 'implementation'}:
            raise ValueError('unsupported task kind')
        if 'status' in task or 'verified' in task:
            raise ValueError('roadmap cannot self-certify completion')
        command = task['command']
        if command is not None and (not isinstance(command, list) or not command or
                not all(isinstance(x, str) and x and '\0' not in x for x in command)):
            raise ValueError('commands must be argv arrays or null')
        acceptance = task['acceptance']
        if acceptance['kind'] not in {'process', 'proof'}:
            raise ValueError('unknown acceptance kind')
        if acceptance['kind'] == 'proof' and not acceptance['required_theorems']:
            raise ValueError('proof acceptance requires nonempty theorem obligations')
        if acceptance['kind'] == 'process' and acceptance['required_theorems']:
            raise ValueError('process acceptance cannot establish theorems')
        if not acceptance['required_artifacts']:
            raise ValueError('empty completion inventory')
        for name in task['inputs'] + acceptance['required_artifacts']:
            relative(name)
        if len(set(task['depends_on'])) != len(task['depends_on']):
            raise ValueError('duplicate dependency')
        by_id[task['id']] = task
    gate = policy['implementation_gate']
    if gate not in by_id or by_id[gate]['acceptance']['kind'] != 'proof':
        raise ValueError('implementation gate must require proof replay')
    visiting, visited, ordered = set(), set(), []
    def visit(key):
        if key not in by_id or key in visiting:
            raise ValueError('unknown dependency or cyclic roadmap')
        if key in visited:
            return
        visiting.add(key)
        for parent in by_id[key]['depends_on']:
            visit(parent)
        visiting.remove(key)
        visited.add(key)
        ordered.append(by_id[key])
    for task in tasks:
        visit(task['id'])
    def ancestors(key):
        return {p for d in by_id[key]['depends_on'] for p in ({d} | ancestors(d))}
    for task in tasks:
        if task['kind'] in {'roadmap', 'implementation'} and gate not in ancestors(task['id']):
            raise ValueError('implementation and implementation-roadmap tasks must depend on proof gate')
    return doc, ordered


def identities(root, names):
    result = {}
    for name in names:
        path = confined_path(root, relative(name))
        result[name] = sha(path.read_bytes()) if path.is_file() else None
    return result


def identity(root, doc, task, runtime, dependencies=None):
    return sha(canonical({'roadmap': doc, 'runtime': runtime,
                         'dependencies': dependencies or {},
                         'inputs': identities(root, task['inputs'])}).encode())


def states(root, doc, ordered, events, runtime):
    results = {}
    for task in ordered:
        key = task['id']
        deps = [x for x in task['depends_on'] if results[x]['status'] != 'OBSERVED']
        reason = None
        if deps:
            reason = 'dependencies not completed: ' + ', '.join(deps)
        elif task['acceptance']['kind'] == 'proof':
            reason = 'qualified independent proof replay adapter is not implemented'
        elif task['kind'] in {'formalization', 'roadmap', 'implementation'}:
            reason = 'provider-authenticated sequential agent adapter is not implemented'
        elif task['command'] is None:
            reason = 'task has no executable implementation'
        elif any(v is None for v in identities(root, task['inputs']).values()):
            reason = 'required input artifact is missing'
        status = 'BLOCKED' if reason else 'READY'
        fingerprint = identity(root, doc, task, runtime,
                               {p: results[p]['identity'] for p in task['depends_on']})
        if not reason:
            observations = [e for e in events if e.get('kind') == 'task_finished' and
                            e.get('task') == key and e.get('identity') == fingerprint]
            if observations:
                last = observations[-1]
                outputs = identities(root, task['acceptance']['required_artifacts'])
                if last.get('outcome') == 'OBSERVED' and all(outputs.values()) and last.get('outputs') == outputs:
                    status = 'OBSERVED'
                elif last.get('outcome') != 'OBSERVED':
                    status, reason = 'BLOCKED', 'unchanged failed attempt; diagnose and change inputs before retry'
            elif any(e.get('kind') == 'task_started' and e.get('task') == key and
                     e.get('identity') == fingerprint for e in events):
                status, reason = 'BLOCKED', 'interrupted attempt; diagnose and change inputs before retry'
        results[key] = {'status': status, 'reason': reason, 'identity': fingerprint,
                        'blockers': task.get('blockers', [])}
    return results
