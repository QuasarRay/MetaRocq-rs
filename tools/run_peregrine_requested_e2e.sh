#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
GEN="$ROOT/generated/peregrine-selfhost"
mkdir -p "$GEN/hol4"

if [[ ! -s "$GEN/peregrine-selfhost.cakeml" ]]; then
  bash tools/peregrine_selfhost_pipeline.sh
fi

test -s "$GEN/peregrine-selfhost.ast"
test -s "$GEN/peregrine-selfhost.cakeml"
test -s metatheory/peregrine-selfhost/PeregrineRuntimeReplay.v
grep -Fq 'replay_peregrine_runtime_program'   metatheory/peregrine-selfhost/PeregrineRuntimeReplay.v

bash tools/prepare_peregrine_hol4.sh

export HOL4_DIR="${HOL4_DIR:-$ROOT/.aegis/references/hol4}"
export CAKEML_DIR="${CAKEML_DIR:-$ROOT/.aegis/references/cakeml}"
export HOLDIR="$HOL4_DIR"
export CAKEMLDIR
export PATH="$HOLDIR/bin:$PATH"
export PEREGRINE_CAKEML_SEXP="$GEN/peregrine-selfhost.cakeml"
export PEREGRINE_MACHINE_ASM="$GEN/hol4/peregrine-selfhost.S"

rm -f "$PEREGRINE_MACHINE_ASM"
(
  cd "$ROOT/formal/hol4"
  "$HOLDIR/bin/Holmake" PeregrineGeneratedCompileTheory.dat
)

test -s "$ROOT/formal/hol4/PeregrineGeneratedCompileTheory.dat"
test -s "$PEREGRINE_MACHINE_ASM"

sha256sum   "$GEN/peregrine-selfhost.ast"   "$GEN/peregrine-selfhost.cakeml"   "$PEREGRINE_MACHINE_ASM"   > "$GEN/hol4/exact-artifacts.sha256"

# Kernel-check the repository's fail-closed qualification theorem as well.
(
  cd "$ROOT/formal/hol4"
  "$HOLDIR/bin/Holmake" PeregrineSelfHostContractTheory.dat
)
test -s "$ROOT/formal/hol4/PeregrineSelfHostContractTheory.dat"

# The final composition theorem is intentionally not synthesized here. Astra
# remains the authority for the canonical formalization. This engineering lane
# only composes existing fragments and must fail closed when the source-to-
# machine theorem is absent.
FINAL="$ROOT/formal/hol4/PeregrineSelfHostE2EScript.sml"
if [[ ! -s "$FINAL" ]]; then
  cat > "$GEN/hol4/final-source-machine.blocked" <<'EOF'
BLOCKED: formal/hol4/PeregrineSelfHostE2EScript.sml is absent.
Exact CakeML compiler-in-HOL evaluation and exact emitted assembly were
attempted before this gate. No source-to-machine verification claim is made.
EOF
  cat "$GEN/hol4/final-source-machine.blocked" >&2
  exit 42
fi

(
  cd "$ROOT/formal/hol4"
  "$HOLDIR/bin/Holmake" PeregrineSelfHostE2ETheory.dat
)
test -s "$ROOT/formal/hol4/PeregrineSelfHostE2ETheory.dat"
