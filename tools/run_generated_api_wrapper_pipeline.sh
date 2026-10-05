#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

: "${HOL4_SRC:?Set HOL4_SRC to the pinned HOL4 checkout}"
: "${CAKEML_SRC:?Set CAKEML_SRC to the CakeML v3400 checkout}"
: "${CAKEML_BIN_DIR:?Set CAKEML_BIN_DIR to a v3400 compiler bundle containing cake and basis_ffi.c}"
: "${HOLDIR:?Set HOLDIR to the HOL4 build used for kernel checking}"

SPEC="$ROOT/spec/generated-sml-api-wrapper-pipeline.json"
OUT="$ROOT/generated/api-wrapper"
mkdir -p "$OUT"

expected_hol="$(python3 -c 'import json; print(json.load(open("'"$SPEC"'"))["inputs"]["hol4"]["commit"])')"
expected_cake="$(python3 -c 'import json; print(json.load(open("'"$SPEC"'"))["inputs"]["cakeml"]["commit"])')"
actual_hol="$(git -C "$HOL4_SRC" rev-parse HEAD)"
actual_cake="$(git -C "$CAKEML_SRC" rev-parse HEAD)"
[[ "$actual_hol" == "$expected_hol" ]] || { echo "HOL4 pin mismatch" >&2; exit 64; }
[[ "$actual_cake" == "$expected_cake" ]] || { echo "CakeML pin mismatch" >&2; exit 65; }

# Reuse PR #59's qualified HOL4/MCP/Z3 environment rather than recreating it.
if [[ -x "$ROOT/.aegis/tools/original-proof-automation/bin/python" ]]; then
  "$ROOT/.aegis/tools/original-proof-automation/bin/python"     "$ROOT/.agents/scripts/check_hol4.py"     > "$OUT/reused-hol4-qualification.log" 2>&1
fi

python3 tools/extract_sml_public_api.py   --hol4-root "$HOL4_SRC"   --config "$SPEC"   --out "$OUT/canonical-api.json"   --strict

python3 tools/render_api_contract_cml.py   "$OUT/canonical-api.json"   "$OUT/GeneratedApiContractData.cml"

cat "$OUT/GeneratedApiContractData.cml"     pipeline/cakeml/api-wrapper/ApiWrapperGenerator.cml     > "$OUT/ApiWrapperGeneratorInput.cml"

CAKE="$CAKEML_BIN_DIR/cake"
FFI="$CAKEML_BIN_DIR/basis_ffi.c"
[[ -x "$CAKE" ]] || { echo "missing CakeML compiler: $CAKE" >&2; exit 66; }
[[ -f "$FFI" ]] || { echo "missing CakeML basis_ffi.c: $FFI" >&2; exit 67; }

# Compile the generator with CakeML itself, then execute that machine code.
"$CAKE" < "$OUT/ApiWrapperGeneratorInput.cml" > "$OUT/ApiWrapperGenerator.S"
cc -O2 -o "$OUT/api-wrapper-generator" "$OUT/ApiWrapperGenerator.S" "$FFI"

"$OUT/api-wrapper-generator" cakeml > "$OUT/GeneratedApiWrappers.cml"
"$OUT/api-wrapper-generator" sml > "$OUT/GeneratedApiAdapter.sml"

# Type-check and compile the generated CakeML facade.  This is engineering
# evidence only; the authoritative exact-code theorem is produced in HOL4.
"$CAKE" --types < "$OUT/GeneratedApiWrappers.cml" > "$OUT/GeneratedApiWrappers.types"
"$CAKE" < "$OUT/GeneratedApiWrappers.cml" > "$OUT/GeneratedApiWrappers.S"

export GENERATED_API_WRAPPER_CML="$OUT/GeneratedApiWrappers.cml"
export GENERATED_API_WRAPPER_ASM="$OUT/GeneratedApiWrapper-hol.S"

(
  cd formal/hol4/api-wrapper
  "$HOLDIR/bin/Holmake"
)

# Fail closed unless all required theory artifacts exist.
for theory in   GeneratedApiWrapperModelTheory.dat   GeneratedApiWrapperCompileTheory.dat   GeneratedApiWrapperQualificationTheory.dat
do
  [[ -s "formal/hol4/api-wrapper/$theory" ]] || {
    echo "missing HOL4 qualification artifact: $theory" >&2
    exit 68
  }
done

python3 - "$OUT" <<'PY'
import hashlib, json, pathlib, sys
out=pathlib.Path(sys.argv[1])
files=sorted(p for p in out.iterdir() if p.is_file())
manifest={
  "schema":1,
  "status":"KERNEL_ARTIFACTS_PRESENT",
  "files":{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in files},
}
(out/"manifest.json").write_text(json.dumps(manifest,indent=2,sort_keys=True)+"\n")
PY

echo "Generated API wrapper pipeline completed with HOL4 artifacts present."
