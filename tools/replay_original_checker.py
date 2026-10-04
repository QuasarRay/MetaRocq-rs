#!/usr/bin/env python3
"""Compile and independently recheck the conditional original-checker theorem.

This command produces observations, never Aegis proof acceptance. It deliberately
does not implement or bypass the roadmap's missing independent replay adapter.
Run inside the pinned opam switch. Every compiler byte is saved, including errors.
AEGIS_TASK_DSN is required: replay streams exposed events to the task-owned Store.
"""
from __future__ import annotations

import base64
from dataclasses import asdict
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import sys
import threading

from checker_ci_persistence import identity

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT / '.agents'), str(ROOT / '.agents/infra')]
from agentinfra.process import run_process

OUT = ROOT / '.aegis/original-checker'
THEORY = ROOT / 'metatheory/bootstrap'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def assumptions():
    """Retain exact Print Assumptions text; the name index is not a proof gate."""
    theorems = {'OriginalChecker': ['checker_acceptance_sound'],
                'CheckerExamples': ['accepts_prop', 'rejects_unbound_rel',
                                    'rejects_missing_constant', 'rejects_missing_set_universe']}
    result = {}
    for module, names in theorems.items():
        path = OUT / ('compile-' + module + '.stdout')
        blocks = re.split(r'(?m)^Axioms:\n', path.read_text())[1:]
        if len(blocks) != len(names):
            raise RuntimeError('unexpected Print Assumptions output; inspect ' + path.name)
        for theorem, block in zip(names, blocks):
            result[theorem] = {'report': block, 'report_sha256': hashlib.sha256(block.encode()).hexdigest(),
                               'names': re.findall(r'(?m)^([\w.]+)\s*:', block),
                               'compiler_output': path.name, 'compiler_output_sha256': digest(path)}
    (OUT / 'assumptions.json').write_text(json.dumps({
        'schema': 1, 'theorems': result,
        'explicit_premises': ['checker_flags and normalizing_flags',
                              'abstract_guard_impl including guard_correct',
                              'forall Sigma, wf_ext Sigma -> NormalizationIn Sigma'],
        'claim': 'Exact compiler-reported assumptions, not discharged obligations',
    }, indent=2) + '\n')


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    records = []
    if not os.environ.get('AEGIS_TASK_DSN'):
        raise RuntimeError('AEGIS_TASK_DSN is required; restore Aegis before replay')
    from database.store import Store
    store = Store(os.environ['AEGIS_TASK_DSN'], ROOT / '.agents',
                  'original-source-and-checker')
    store.exclusive()
    store.recover()
    source = identity()
    event_file = (OUT / 'events.jsonl').open('wb')
    event_lock = threading.RLock()

    def event(value):
        value = dict(value, identity=source)
        raw = (json.dumps(value, sort_keys=True) + '\n').encode()
        with event_lock:
            event_file.write(raw)
            event_file.flush()
            os.fsync(event_file.fileno())
            store.append(value)

    def command(name, argv, *, timeout=1800, success=True):
        event({'kind': 'command_started', 'name': name, 'argv': argv,
               'cwd': str(ROOT), 'timeout': timeout})
        with (OUT / (name + '.stdout')).open('wb') as stdout, \
             (OUT / (name + '.stderr')).open('wb') as stderr:
            def capture(stream, chunk):
                target = stdout if stream == 'stdout' else stderr
                target.write(chunk)
                target.flush()
                os.fsync(target.fileno())
                event({'kind': 'command_output', 'name': name, 'stream': stream,
                       'encoding': 'base64', 'data': base64.b64encode(chunk).decode()})
            result = run_process(argv, cwd=ROOT, timeout=timeout,
                                 event_sink=capture, capture_limit=65536)
        record = asdict(result)
        record.pop('stdout')
        record.pop('stderr')
        record.update(name=name, expected_success=success)
        records.append(record)
        event({'kind': 'command_finished', **record})
        print(f'{name}: exit {result.returncode}', flush=True)
        if result.returncode:
            print(result.stderr[-8000:], flush=True)
        if result.timed_out or (result.returncode == 0) != success:
            raise RuntimeError(f'{name}: unexpected command result')
        return result

    status = 'FAILED'
    try:
        event({'kind': 'replay_started', 'task_status': 'BLOCKED'})
        rocq = shutil.which('rocq')
        if not rocq:
            raise RuntimeError('rocq is missing; use the pinned opam switch')
        command('rocq-version', [rocq, '-v'])
        # No -vos, -vok, -admit, -impredicative-set or disabled universe checks.
        flags = ['-Q', str(THEORY), 'MetaRocqRs.Bootstrap']
        for module in ('OriginalChecker', 'CheckerExamples'):
            for suffix in ('.vo', '.vos', '.vok', '.glob'):
                (THEORY / (module + suffix)).unlink(missing_ok=True)
            command('compile-' + module, [rocq, 'compile', *flags,
                    str(THEORY / (module + '.v'))])
        assumptions()
        # rocq check replays proof objects and transitive library dependencies in
        # a separate checker process; it does not trust the compiler exit code.
        command('kernel-replay', [rocq, 'check', *flags,
                'MetaRocqRs.Bootstrap.OriginalChecker',
                'MetaRocqRs.Bootstrap.CheckerExamples'], timeout=3600)
        # A negative proof-source control must fail under the same compiler.
        invalid = OUT / 'InvalidProof.v'
        invalid.write_text('Theorem invalid : False. Proof. exact I. Qed.\n')
        command('reject-invalid-proof', [rocq, 'compile', str(invalid)], success=False)
        # Corrupt only an isolated copy; never mutate the successful artifact.
        damaged = OUT / 'damaged'
        damaged.mkdir(exist_ok=True)
        target = damaged / 'OriginalChecker.vo'
        target.write_bytes((THEORY / 'OriginalChecker.vo').read_bytes()[:32])
        command('reject-damaged-object', [rocq, 'check', '-Q', str(damaged),
                'MetaRocqRs.Bootstrap', 'MetaRocqRs.Bootstrap.OriginalChecker'], success=False)
        for path in THEORY.glob('*.vo'):
            shutil.copy2(path, OUT / path.name)
        status = 'CONDITIONAL_KERNEL_REPLAY_SUCCEEDED'
    finally:
        manifest = {
            'schema': 1, 'status': status,
            'identity': source,
            'runtime': 'task-scoped PostgreSQL required; events pending Git publication',
            'task_status': 'BLOCKED',
            'claim': 'Conditional upstream-checker theorem and finite regressions only.',
            'not_claimed': ['Discharged guard, normalization, equality or primitive assumptions',
                            'Qualified Aegis proof acceptance',
                            'Complete dependency source provenance',
                            'Extraction or CakeML machine-code correctness'],
            'commands': records,
            'sources': {p.relative_to(ROOT).as_posix(): digest(p)
                        for p in [THEORY / 'OriginalChecker.v', THEORY / 'CheckerExamples.v',
                                  ROOT / 'spec/toolchain.lock.json',
                                  ROOT / 'spec/aegis-deployment.json',
                                  ROOT / 'metatheory/evidence/original-checker-trust.json',
                                  ROOT / 'tools/replay_original_checker.py',
                                  ROOT / 'tools/checker_ci_persistence.py',
                                  ROOT / '.github/workflows/original-checker.yml',
                                  ROOT / 'tools/install_extraction.sh']},
            'artifacts': {p.relative_to(OUT).as_posix(): digest(p)
                          for p in sorted(OUT.rglob('*')) if p.is_file()
                          and p.name not in ('manifest.json', 'events.jsonl')},
            'capture': 'Full stdout/stderr plus append-only exposed event stream; no private reasoning.',
        }
        (OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
        event({'kind': 'replay_observation', 'outcome': status,
               'manifest_sha256': digest(OUT / 'manifest.json'), 'task_status': 'BLOCKED'})
        event_file.close()
        store.close()


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        print(json.dumps({'status': 'BLOCKED', 'error_type': type(error).__name__,
                          'reason': 'replay or persistence failed; inspect retained observations'}), file=sys.stderr)
        raise SystemExit(2)
