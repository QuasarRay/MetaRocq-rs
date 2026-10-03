#!/usr/bin/env python3
"""Compile and independently recheck the conditional original-checker theorem.

This command produces observations, never Aegis proof acceptance. It deliberately
does not implement or bypass the roadmap's missing independent replay adapter.
Run inside the pinned opam switch. Every compiler byte is saved, including errors.
Set AEGIS_TASK_DSN to additionally stream exposed events to the task-owned Store.
"""
from __future__ import annotations

import base64
from dataclasses import asdict
import hashlib
import json
import os
from pathlib import Path
import shutil
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT / '.agents'), str(ROOT / '.agents/infra')]
from agentinfra.process import run_process

OUT = ROOT / '.aegis/original-checker'
THEORY = ROOT / 'metatheory/bootstrap'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    records = []
    store = None
    if os.environ.get('AEGIS_TASK_DSN'):
        from database.store import Store
        store = Store(os.environ['AEGIS_TASK_DSN'], ROOT / '.agents',
                      'original-source-and-checker')
        store.exclusive()
    event_file = (OUT / 'events.jsonl').open('wb')

    def event(value):
        raw = (json.dumps(value, sort_keys=True) + '\n').encode()
        event_file.write(raw)
        event_file.flush()
        os.fsync(event_file.fileno())
        if store:
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
        # rocq chk replays proof objects and transitive library dependencies in
        # a separate checker process; it does not trust the compiler exit code.
        command('kernel-replay', [rocq, 'chk', *flags,
                'MetaRocqRs.Bootstrap.OriginalChecker',
                'MetaRocqRs.Bootstrap.CheckerExamples'])
        # A negative proof-source control must fail under the same compiler.
        invalid = OUT / 'InvalidProof.v'
        invalid.write_text('Theorem invalid : False. Proof. exact I. Qed.\n')
        command('reject-invalid-proof', [rocq, 'compile', str(invalid)], success=False)
        # Corrupt only an isolated copy; never mutate the successful artifact.
        damaged = OUT / 'damaged'
        damaged.mkdir(exist_ok=True)
        target = damaged / 'OriginalChecker.vo'
        target.write_bytes((THEORY / 'OriginalChecker.vo').read_bytes()[:32])
        command('reject-damaged-object', [rocq, 'chk', '-Q', str(damaged),
                'MetaRocqRs.Bootstrap', 'MetaRocqRs.Bootstrap.OriginalChecker'], success=False)
        for path in THEORY.glob('*.vo'):
            shutil.copy2(path, OUT / path.name)
        status = 'CONDITIONAL_KERNEL_REPLAY_SUCCEEDED'
    finally:
        manifest = {
            'schema': 1, 'status': status,
            'task_status': 'BLOCKED',
            'claim': 'Conditional upstream-checker theorem and finite regressions only.',
            'not_claimed': ['Discharged guard or normalization obligations',
                            'Qualified Aegis proof acceptance',
                            'Complete dependency source provenance',
                            'Extraction or CakeML machine-code correctness'],
            'commands': records,
            'sources': {p.relative_to(ROOT).as_posix(): digest(p)
                        for p in [THEORY / 'OriginalChecker.v', THEORY / 'CheckerExamples.v',
                                  ROOT / 'spec/toolchain.lock.json',
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
        if store:
            store.release()
            store.close()


if __name__ == '__main__':
    main()
