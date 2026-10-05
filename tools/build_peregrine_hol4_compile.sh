#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
source tools/hol4_artifacts.sh

GEN="$ROOT/generated/peregrine-selfhost"
HOLGEN="$GEN/hol4"
INPUT="$GEN/peregrine-selfhost.checked.cakeml"
SNAPSHOT="$HOLGEN/compiler-input.sexp"
RECEIPT="$HOLGEN/compile-artifacts.sha256"
export PEREGRINE_MACHINE_ASM="$HOLGEN/peregrine-selfhost.S"
THEORY="PeregrineGeneratedCompileTheory"
HOLMAKE="${HOL4_DIR:-$ROOT/.aegis/references/hol4}/bin/Holmake"
mkdir -p "$HOLGEN"
test -s "$INPUT"
sha256sum --check "$HOLGEN/compiler-preparation-inputs.sha256"
if [[ -s "$HOLGEN/proof-automation.env" ]]; then
  sha256sum --check "$HOLGEN/proof-automation-inputs.sha256"
  source "$HOLGEN/proof-automation.env"
fi

# A receipt binds cached outputs to the exact serialized bytes and recipe,
# including the theory bytes themselves. File modification times are not an
# input identity. These hashes authorize reuse only, not semantic acceptance.
if [[ -s "$RECEIPT" && -s "$PEREGRINE_MACHINE_ASM" ]] &&
   sha256sum --check --status "$RECEIPT" &&
   cmp -s "$INPUT" "$SNAPSHOT" &&
   hol4_artifact_path "$ROOT/formal/hol4/$THEORY.dat" >/dev/null; then
  printf '%s\n' 'Reusing exact in-HOL compiler artifacts; input receipt matches.'
  exit 0
fi

# Preserve the prior proof objects before invalidating this application theory.
# Compiler/kernel dependency theories remain reusable by Holmake.
if [[ -s "$RECEIPT" ]]; then
  key="$(sha256sum "$RECEIPT" | cut -d' ' -f1)"
  PRIOR="$HOLGEN/previous-compilations/$key"
  mkdir -p "$PRIOR"
  cp -n "$RECEIPT" "$PRIOR/"
  for file in "$SNAPSHOT" "$PEREGRINE_MACHINE_ASM"; do
    [[ ! -f "$file" ]] || cp -n "$file" "$PRIOR/"
  done
  for directory in "$ROOT/formal/hol4" "$ROOT/formal/hol4/.hol/objs"; do
    for extension in dat uo ui sml sig; do
      file="$directory/$THEORY.$extension"
      [[ ! -f "$file" ]] || cp -n "$file" "$PRIOR/"
    done
  done
fi
rm -f "$RECEIPT" "$PEREGRINE_MACHINE_ASM"
for directory in "$ROOT/formal/hol4" "$ROOT/formal/hol4/.hol/objs"; do
  for extension in dat uo ui sml sig; do
    rm -f "$directory/$THEORY.$extension"
  done
done
cp "$INPUT" "$SNAPSHOT"
(
  cd "$ROOT/formal/hol4"
  "$HOLMAKE" PeregrineGeneratedCompileTheory.dat
)
COMPILE_THEORY="$(hol4_artifact_path "$ROOT/formal/hol4/$THEORY.dat")"
test -s "$PEREGRINE_MACHINE_ASM"
cmp "$INPUT" "$SNAPSHOT"
sha256sum "$INPUT" "$SNAPSHOT" "$COMPILE_THEORY" \
  "$PEREGRINE_MACHINE_ASM" spec/toolchain.lock.json \
  formal/hol4/PeregrineGeneratedCompileScript.sml formal/hol4/Holmakefile \
  formal/hol4/CompilerOutputAutomationLib.sml formal/hol4/CompilerOutputAutomationLib.sig \
  tools/prepare_original_proof_automation.sh spec/original-proof-automation.lock.json \
  tools/build_peregrine_hol4_compile.sh tools/hol4_artifacts.sh \
  "$HOLGEN/compiler-preparation-inputs.sha256" \
  "$HOLGEN/cakeml-context-compat.json" "$HOLGEN/toolchain.env" > "$RECEIPT"
sha256sum --check "$RECEIPT"
