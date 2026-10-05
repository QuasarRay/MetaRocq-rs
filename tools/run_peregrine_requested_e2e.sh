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
grep -Fq 'replay_peregrine_runtime_program' \
  metatheory/peregrine-selfhost/PeregrineRuntimeReplay.v

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

COMPILE_THEORY="$ROOT/formal/hol4/PeregrineGeneratedCompileTheory.dat"
test -s "$COMPILE_THEORY"
test -s "$PEREGRINE_MACHINE_ASM"
grep -Fq 'peregrine_machine_code'   "$ROOT/formal/hol4/PeregrineGeneratedCompileScript.sml"

# The .S file is an exported representation.  The byte-level compiler result
# itself is the HOL constant [peregrine_machine_code], backed by the checked
# PeregrineGeneratedCompile theory.  Hash both so the trace preserves that
# distinction instead of calling assembler text "machine code".
sha256sum   "$GEN/peregrine-selfhost.ast"   "$GEN/peregrine-selfhost.cakeml"   "$COMPILE_THEORY"   "$PEREGRINE_MACHINE_ASM"   > "$GEN/hol4/exact-artifacts.sha256"

cat > "$GEN/hol4/exact-machine-code-binding.txt" <<EOF
HOL theory: $COMPILE_THEORY
Exact code object: PeregrineGeneratedCompile.peregrine_machine_code
Compiler theorem: PeregrineGeneratedCompile.peregrine_selfhost_compiled
Assembler export: $PEREGRINE_MACHINE_ASM
The assembler export is not substituted for the HOL byte object.
EOF

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
The exact generated CakeML AST was compiled inside HOL. The checked compiler
theory retains PeregrineGeneratedCompile.peregrine_machine_code as the exact
byte-level compiler output and also emits an assembler representation. No
source-to-machine verification claim is made until the final HOL4 composition
theorem exists and is kernel-checked.
EOF
  cat "$GEN/hol4/final-source-machine.blocked" >&2
  exit 42
fi

(
  cd "$ROOT/formal/hol4"
  "$HOLDIR/bin/Holmake" PeregrineSelfHostE2ETheory.dat
)
test -s "$ROOT/formal/hol4/PeregrineSelfHostE2ETheory.dat"
