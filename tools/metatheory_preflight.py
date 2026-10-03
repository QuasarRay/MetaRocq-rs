#!/usr/bin/env python3
"""Audit actual pinned source; this executable does not prove the metatheory."""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    lock = json.loads((ROOT / 'spec/toolchain.lock.json').read_text())
    inventory = json.loads((ROOT / 'spec/source-inventory.json').read_text())
    refs = {}
    for name in ('metarocq', 'peregrine'):
        root = ROOT / '.aegis/references' / name
        if root.is_symlink() or any(p.is_symlink() for p in root.parents if p != ROOT.parent):
            raise ValueError('redirected source checkout')
        commit = subprocess.check_output(['git', '-C', str(root), 'rev-parse', 'HEAD'], text=True).strip()
        dirty = subprocess.check_output(['git', '-C', str(root), 'status', '--porcelain'], text=True).strip()
        if commit != lock['repositories'][name]['commit'] or dirty:
            raise ValueError('source pin mismatch or dirty upstream checkout')
        refs[name] = root
    tracked = set(subprocess.check_output(['git', '-C', str(refs['metarocq']), 'ls-files', '-z']).decode().split('\0')) - {''}
    if inventory['commit'] != lock['repositories']['metarocq']['commit'] or tracked != {f['path'] for f in inventory['files']}:
        raise ValueError('upstream inventory is incomplete or stale')
    for entry in inventory['files']:
        if sha(refs['metarocq'] / entry['path']) != entry['sha256']:
            raise ValueError('upstream inventory byte mismatch')
    findings = []
    probes = [
        ('peregrine', 'theories/backends/CakeMLBackend.v', 'Admitted.', 'admitted-cakeml-wrapper-obligation'),
        ('peregrine', 'theories/backends/CakeMLBackend.v', 'Axiom trust_coq_kernel', 'unproved-cakeml-pipeline-precondition'),
        ('metarocq', 'safechecker-plugin/theories/Extraction.v', 'Axiom fake_abstract_guard_impl_properties', 'assumed-guard-correctness')]
    for name, path, needle, obligation in probes:
        source = refs[name] / path
        lines = [i for i, line in enumerate(source.read_text().splitlines(), 1) if needle in line]
        if not lines:
            raise ValueError('source assumption audit changed; inspect before updating the audit')
        findings.append({'id': obligation, 'repository': name, 'path': path,
                         'sha256': sha(source), 'lines': lines, 'status': 'OPEN'})
    output = {
        'schema': 1, 'source_identity': 'MATCHED', 'inventory_files': len(tracked),
        'source_pins': {k: lock['repositories'][k]['commit'] for k in refs},
        'tools': {k: bool(shutil.which(k)) for k in ('rocq', 'peregrine', 'cake', 'Holmake', 'cargo-kani')},
        'findings': findings, 'metatheory_complete': False, 'implementation_allowed': False,
        'proof_retention': 'Existing Type-level quotation retains syntax; generic semantic preservation and replay remain OPEN.',
        'cake_ml': 'Use untyped LambdaBox. Retaining proof data alone does not discharge the wrapper precondition.',
        'next_task': 'original-source-and-checker',
        'blockers': ['qualified independent original checker and provenance',
                     'untyped proof-retention preservation theorem', 'CakeML wrapper obligations and exact binary trust closure',
                     'Rust-aware shared formal specification and full metatheory equivalence theorem'],
        'claim': 'source audit only; no theorem checked and no bootstrap completion'}
    destination = ROOT / 'metatheory/evidence/source-audit.json'
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(output, indent=2) + '\n')
    print(json.dumps(output, sort_keys=True))


if __name__ == '__main__':
    main()
