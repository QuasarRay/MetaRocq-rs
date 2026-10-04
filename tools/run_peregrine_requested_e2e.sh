#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
source tools/hol4_artifacts.sh
GEN="$ROOT/generated/peregrine-selfhost"
mkdir -p "$GEN/hol4"

# The controller already attempted candidate generation in this run. Retain
# its partial objects and diagnostics instead of executing that same failed
# generation a second time from the workflow's always() lane.
if [[ -n "${E2E_TRACE_DIR:-}" &&
      -s "$E2E_TRACE_DIR/stages/03/status.txt" ]] &&
   ! grep -Fxq 'exit=0' "$E2E_TRACE_DIR/stages/03/status.txt"; then
  printf '%s\n' 'BLOCKED: stage 03 failed; preserved producer checkpoints must be inspected before retry.' >&2
  exit 44
fi

if [[ ! -s "$GEN/peregrine-selfhost.cakeml" ||
      ! -s "$GEN/peregrine-selfhost.checked.cakeml" ||
      ! -s "$GEN/checked-native-cakeml-equality.txt" ||
      ! -s "$GEN/producer-inputs.sha256" ]]; then
  bash tools/peregrine_selfhost_pipeline.sh
fi

sha256sum --check "$GEN/producer-inputs.sha256"

test -s "$GEN/peregrine-selfhost.ast"
test -s "$GEN/peregrine-selfhost.cakeml"
test -s "$GEN/peregrine-selfhost.checked.cakeml"
grep -Fxq 'byte-identical' "$GEN/checked-native-cakeml-equality.txt"
cmp -s "$GEN/peregrine-selfhost.cakeml" "$GEN/peregrine-selfhost.checked.cakeml"
test -s metatheory/peregrine-selfhost/PeregrineRuntimeReplay.v
grep -Fq 'replay_peregrine_runtime_program' \
  metatheory/peregrine-selfhost/PeregrineRuntimeReplay.v

bash tools/prepare_peregrine_hol4.sh

export HOL4_DIR="${HOL4_DIR:-$ROOT/.aegis/references/hol4}"
export CAKEML_DIR="${CAKEML_DIR:-$ROOT/.aegis/references/cakeml}"
export HOLDIR="$HOL4_DIR"
export CAKEMLDIR
export PATH="$HOLDIR/bin:$PATH"
# Compile the checked-adapter bytes directly.  The producer pipeline has
# already required byte-for-byte equality with the native Peregrine candidate.
bash tools/build_peregrine_hol4_compile.sh
export PEREGRINE_CAKEML_SEXP="$GEN/hol4/compiler-input.sexp"
export PEREGRINE_MACHINE_ASM="$GEN/hol4/peregrine-selfhost.S"
COMPILE_THEORY="$(hol4_artifact_path "$ROOT/formal/hol4/PeregrineGeneratedCompileTheory.dat")"
grep -Fq 'peregrine_machine_code'   "$ROOT/formal/hol4/PeregrineGeneratedCompileScript.sml"

# The .S file is an exported representation.  The byte-level compiler result
# itself is the HOL constant [peregrine_machine_code], backed by the checked
# PeregrineGeneratedCompile theory.  Hash both so the trace preserves that
# distinction instead of calling assembler text "machine code".
sha256sum   "$GEN/peregrine-selfhost.ast"   "$GEN/peregrine-selfhost.cakeml" \
  "$GEN/peregrine-selfhost.checked.cakeml" \
  "$GEN/checked-native-cakeml-equality.txt" \
  "$COMPILE_THEORY"   "$PEREGRINE_MACHINE_ASM"   > "$GEN/hol4/exact-artifacts.sha256"

cat > "$GEN/hol4/exact-machine-code-binding.txt" <<EOF
HOL theory: $COMPILE_THEORY
CakeML input: $PEREGRINE_CAKEML_SEXP
Native cross-check: $GEN/peregrine-selfhost.cakeml
Equality gate: $GEN/checked-native-cakeml-equality.txt
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
hol4_artifact_path "$ROOT/formal/hol4/PeregrineSelfHostContractTheory.dat" >/dev/null

# This Original-Peregrine bootstrap is authorized independently of the Astra
# restriction on canonical Rust-native MetaRocq-rs formalization. Authorization
# does not supply a missing mathematical theorem: actual source-to-machine
# composition must exist and be checked before qualification can pass.
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
hol4_artifact_path "$ROOT/formal/hol4/PeregrineSelfHostE2ETheory.dat" >/dev/null
