#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
GEN="$ROOT/generated/peregrine-selfhost/tactician"
mkdir -p "$GEN"
SWITCH="$ROOT/.aegis/opam"
if [[ ! -x "$SWITCH/_opam/bin/rocq" ]] || ! command -v opam >/dev/null; then
  printf 'BLOCKED: reuse requires the installed pinned Rocq switch.\n' | tee "$GEN/blocked.txt" >&2
  exit 69
fi
export OPAMROOT="${OPAMROOT:-$ROOT/.aegis/opam-root}"
eval "$(opam env --switch "$SWITCH" --set-switch)"
python3 - "$ROOT" <<'PY'
import json, pathlib, subprocess, sys
root=pathlib.Path(sys.argv[1]); pin=json.loads((root/'spec/original-proof-automation.lock.json').read_text())['tactician']
source=root/'.aegis/references/tactician'
if not source.exists():
 subprocess.run(['git','clone',pin['repository'],str(source)],check=True)
 subprocess.run(['git','-C',str(source),'checkout','--detach',pin['commit']],check=True)
head=subprocess.check_output(['git','-C',str(source),'rev-parse','HEAD'],text=True).strip()
if head!=pin['commit'] or subprocess.check_output(['git','-C',str(source),'status','--porcelain','--untracked-files=no']):
 raise SystemExit('Tactician source differs from its exact release-compatible pin')
(root/'generated/peregrine-selfhost/tactician/source-identity.json').write_text(json.dumps(pin,indent=2)+'\n')
PY
opam pin add --switch "$SWITCH" --no-action --yes coq-tactician.dev \
  "$ROOT/.aegis/references/tactician"
opam install --switch "$SWITCH" --yes --jobs="${OPAMJOBS:-2}" \
  coq-tactician.dev coq-core.9.1.1 rocq-core.9.1.1 rocq-stdlib.9.0.0
opam switch export --switch "$SWITCH" "$GEN/opam-switch.export"
source="$ROOT/metatheory/original-selfhost/OriginalTacticianQualification.v"
destination="$GEN/OriginalTacticianQualification.v"
if [[ -e "$destination" ]] && ! cmp -s "$source" "$destination"; then
  echo 'Preserve the previous Tactician qualification; choose a fresh generated run.' >&2
  exit 1
fi
cp "$source" "$destination"
rocq compile -Q "$GEN" MetaRocqRs.OriginalSelfHost "$destination" \
  2>&1 | tee "$GEN/qualification.log"
test -s "$GEN/OriginalTacticianQualification.vo"
rg -Fx 'Closed under the global context' "$GEN/qualification.log" >/dev/null
rocq --version > "$GEN/rocq-version.txt"
sha256sum "$destination" "$GEN/OriginalTacticianQualification.vo" \
  "$GEN/source-identity.json" "$GEN/opam-switch.export" "$GEN/qualification.log" \
  "$GEN/rocq-version.txt" spec/original-proof-automation.lock.json \
  tools/run_original_tactician_probe.sh > "$GEN/qualified-inputs.sha256"
printf 'Tactician generated a Rocq-checked coverage proof and quoted proof-term data.\nQualification only; complete replay and machine refinement remain open.\n' \
  > "$GEN/qualification.txt"
