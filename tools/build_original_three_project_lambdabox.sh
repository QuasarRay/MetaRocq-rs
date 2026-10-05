#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
GEN="$ROOT/generated/peregrine-selfhost/three-project-replay"
mkdir -p "$GEN"
python3 tools/materialize_original_source_bundle.py --fetch \
  --evidence-dir "$GEN/sources" 2>&1 | tee "$GEN/source-materialization.log"
BUNDLE="$(python3 - "$GEN/sources/latest.json" <<'PY'
import json, sys
print(json.load(open(sys.argv[1]))['source_bundle'])
PY
)"
RUNTIME="$BUNDLE/selfhost/runtime"
GENERATED="$BUNDLE/selfhost/generated"
mkdir -p "$RUNTIME"
# Copy the explicit Gallina overlay into the containing MetaRocq source tree.
# Never replace edited progress; use a new recipe-addressed bundle instead.
python3 - "$RUNTIME" <<'PY'
from pathlib import Path
import sys
target = Path(sys.argv[1])
for name in ('DeclarationReplayInventory.v', 'UnifiedReplayRootInventory.v',
             'UnifiedRetainedReplay.v', 'ExtractUnifiedRetainedReplay.v'):
    content = (Path('metatheory/original-selfhost') / name).read_bytes()
    destination = target / name
    if destination.exists() and destination.read_bytes() != content:
        raise SystemExit('Refusing to overwrite an edited Gallina overlay: ' + str(destination))
    destination.write_bytes(content)
PY
command -v rocq >/dev/null || {
  printf 'BLOCKED: pinned Rocq/MetaRocq/Peregrine installation unavailable.\n' | tee "$GEN/blocked.txt" >&2
  exit 69
}
command -v peregrine >/dev/null
Q=(-Q "$RUNTIME" MetaRocqRs.OriginalSelfHost
   -Q "$GENERATED" MetaRocqRs.UnifiedGenerated)
compile() {
  local file="$1" key
  key="$(basename "$file" .v)"
  local log="$GEN/$key.log"
  set +e
  /usr/bin/time -v -o "$GEN/$key.time-memory.txt" \
    rocq compile "${Q[@]}" "$file" 2>&1 | tee "$log"
  local status=("${PIPESTATUS[@]}")
  set -e
  printf 'rocq=%s capture=%s\n' "${status[0]}" "${status[1]}" > "$GEN/$key.status.txt"
  [[ "${status[0]}" -eq 0 && "${status[1]}" -eq 0 ]]
}
compile "$GENERATED/UnifiedModuleManifest.v"
compile "$GENERATED/UnifiedLoadAll.v"
compile "$RUNTIME/DeclarationReplayInventory.v"
compile "$RUNTIME/UnifiedReplayRootInventory.v"
python3 tools/materialize_peregrine_replay_roots.py \
  "$GEN/UnifiedReplayRootInventory.log" \
  --manifest "$GENERATED/UnifiedModuleManifest.v" \
  --output-dir "$GENERATED" --output-name UnifiedReplayAllGlobals.v \
  --module-list unified_modules --marker-prefix UNIFIED_REPLAY \
  --root-prefix unified --coverage-ledger \
  --import-module MetaRocqRs.UnifiedGenerated.UnifiedLoadAll
compile "$GENERATED/UnifiedReplayAllGlobals.v"
compile "$RUNTIME/UnifiedRetainedReplay.v"
compile "$RUNTIME/ExtractUnifiedRetainedReplay.v"
AST="$GEN/retained-three-projects.ast"
test -s "$AST"
sha256sum "$AST" "$GENERATED/replay-root-inventory.json" \
  "$GENERATED/source-inventory.json" > "$GEN/retained-image-inputs.sha256"
peregrine cakeml "$AST" -o "$GEN/retained-three-projects.cakeml"
test -s "$GEN/retained-three-projects.cakeml"
sha256sum "$GEN/retained-three-projects.cakeml" >> "$GEN/retained-image-inputs.sha256"
printf 'RETAINED CANDIDATE ONLY: verified replay and source-to-machine refinement remain open.\n' \
  | tee "$GEN/candidate-boundary.txt"
