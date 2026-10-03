#!/usr/bin/env python3
"""Deploy an exact committed Aegis tree into an absent target .agents directory."""
import argparse
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import subprocess
import tarfile

ROOT = Path(__file__).resolve().parents[1]


def main():
    p = argparse.ArgumentParser()
    p.add_argument('target', type=Path)
    p.add_argument('--commit', default='HEAD')
    args = p.parse_args()
    target = args.target.resolve(strict=True)
    commit = subprocess.check_output(['git', '-C', str(ROOT), 'rev-parse', args.commit], text=True).strip()
    archive = subprocess.check_output(['git', '-C', str(ROOT), 'archive', commit])
    dest = target / '.agents'
    if dest.exists() or dest.is_symlink():
        raise ValueError('deployment must be absent; preserve existing data before any upgrade')
    entries = {}
    with tarfile.open(fileobj=io.BytesIO(archive)) as bundle:
        for member in bundle.getmembers():
            path = PurePosixPath(member.name)
            if path.is_absolute() or '..' in path.parts or not (member.isdir() or member.isfile()):
                raise ValueError('unsafe archive member')
            if member.isfile():
                entries[member.name] = (bundle.extractfile(member).read(), member.mode)
    for name, (content, mode) in entries.items():
        path = dest / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)
        path.chmod(mode)
    record = {'schema': 1, 'repository': 'https://github.com/QuasarRay/Aegis.git', 'commit': commit,
              'files': {name: hashlib.sha256(content).hexdigest() for name, (content, _) in entries.items()},
              'mutable_path': 'data/', 'claim': 'exact deployment integrity; not formal verification'}
    (target / 'spec/aegis-deployment.json').write_text(json.dumps(record, indent=2, sort_keys=True) + '\n')
    print(json.dumps({'deployed_commit': commit, 'files': len(entries)}))


if __name__ == '__main__':
    main()
