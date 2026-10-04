#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
trace="${E2E_TRACE_DIR:?E2E_TRACE_DIR is required}"
[[ "$trace" == .o11y/* && -d "$trace" && ! -e "$trace/FINALIZED" ]] || {
  echo "refusing to capture into an invalid or finalized trace" >&2
  exit 1
}
out="$trace/generated-checkpoint"
[[ ! -e "$out" ]] || { echo "checkpoint already exists: $out" >&2; exit 1; }
mkdir "$out"

# Keep produced proof data and compiler objects when a later gate fails. The
# installed dependency toolchain belongs in the Actions cache; it is not
# copied into the public trace. Archive members remain relative to the repo.
python3 - "$out" <<'PY'
from pathlib import Path
import hashlib, json, os, subprocess, sys
out=Path(sys.argv[1])
files=[]
roots=[Path('generated/peregrine-selfhost'),Path('generated/original-selfhost'),
       Path('generated/original-metarocq-selfhost')]
for root in roots:
 if root.is_dir():
  files.extend(p for p in root.rglob('*') if p.is_file() or p.is_symlink())
for root in (Path('metatheory/peregrine-selfhost'),Path('metatheory/original-selfhost'),Path('formal/hol4')):
 if root.is_dir():
  files.extend(p for p in root.iterdir() if p.is_file() and
               (p.suffix in {'.v','.vo','.vos','.vok','.glob','.dat','.uo','.ui','.sig'} or
                p.name.endswith('Script.sml') or p.name.endswith('Theory.sml')))
files=sorted(set(files))
records=[]
for p in files:
 if p.is_symlink():
  records.append({'path':p.as_posix(),'symlink':os.readlink(p)})
 else:
  digest=hashlib.sha256()
  with p.open('rb') as f:
   for chunk in iter(lambda:f.read(1024*1024),b''): digest.update(chunk)
  records.append({'path':p.as_posix(),'bytes':p.stat().st_size,'sha256':digest.hexdigest()})
(out/'members.nul').write_bytes(b''.join(os.fsencode(p)+b'\0' for p in files))
(out/'members.json').write_text(json.dumps({'schema':1,'files':records,
 'claim':'exact captured producer artifacts; no theorem or proof acceptance is inferred'},indent=2)+'\n')
(out/'source-head.txt').write_text(subprocess.check_output(['git','rev-parse','HEAD'],text=True))
PY

sha256sum spec/toolchain.lock.json spec/peregrine-selfhost-e2e.json \
  spec/source-inventory.json tools/peregrine_selfhost_pipeline.sh \
  tools/run_peregrine_requested_e2e.sh > "$out/input-identities.sha256"

# Fixed headers make the archive reproducible. Split it below GitHub's blob
# limit so a large retained proof corpus can still use the append-only sync.
tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
  --null --files-from "$out/members.nul" -cf - | gzip -n > "$out/checkpoint.tmp.gz"
split -b 64M -d -a 4 "$out/checkpoint.tmp.gz" "$out/checkpoint.tar.gz.part-"
rm "$out/checkpoint.tmp.gz" "$out/members.nul"
sha256sum "$out"/checkpoint.tar.gz.part-* > "$out/archive-parts.sha256"
printf 'captured producer objects; HOL4 semantic qualification remains separate\n' > "$out/complete.txt"
