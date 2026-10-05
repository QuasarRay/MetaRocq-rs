#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

: "${HOL4_SRC:?Set HOL4_SRC to the pinned HOL4 checkout}"
: "${CAKEML_SRC:?Set CAKEML_SRC to the pinned CakeML checkout}"
: "${CAKEML_BIN_DIR:?Set CAKEML_BIN_DIR to the pinned CakeML compiler bundle containing cake and basis_ffi.c}"
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

# Reuse PR #59's qualification environment and exact HOL4/CakeML pins when available.
if [[ -x "$ROOT/.aegis/tools/original-proof-automation/bin/python" ]]; then
  "$ROOT/.aegis/tools/original-proof-automation/bin/python"     "$ROOT/.agents/scripts/check_hol4.py"     > "$OUT/reused-hol4-qualification.log" 2>&1
fi

python3 tools/extract_sml_public_api.py   --hol4-root "$HOL4_SRC"   --config "$SPEC"   --out "$OUT/canonical-api.json"   --strict

for component in hol4 z3_tac tactictoe; do
  test -s "$OUT/canonical-api.$component.json" || {
    echo "missing component contract: $component" >&2
    exit 71
  }
done

python3 tools/render_api_contract_cml.py   "$OUT/canonical-api.json"   "$OUT/GeneratedApiContractData.cml"

python3 tools/render_api_contract_hol4.py \
  "$OUT/canonical-api.json" \
  "formal/hol4/api-wrapper/GeneratedApiContractScript.sml"
python3 tools/render_api_wrapper_bindings_hol4.py \
  "$OUT/canonical-api.json" \
  "formal/hol4/api-wrapper/GeneratedApiWrapperBindingsScript.sml"

cat "$OUT/GeneratedApiContractData.cml"     pipeline/cakeml/api-wrapper/ApiWrapperGenerator.cml     > "$OUT/ApiWrapperGeneratorInput.cml"

CAKE="$CAKEML_BIN_DIR/cake"
FFI="$CAKEML_BIN_DIR/basis_ffi.c"
[[ -x "$CAKE" ]] || { echo "missing CakeML compiler: $CAKE" >&2; exit 66; }
[[ -f "$FFI" ]] || { echo "missing CakeML basis_ffi.c: $FFI" >&2; exit 67; }

# Compile the generator with CakeML itself, then execute that machine code.
"$CAKE" < "$OUT/ApiWrapperGeneratorInput.cml" > "$OUT/ApiWrapperGenerator.S"
cc -O2 -o "$OUT/api-wrapper-generator" "$OUT/ApiWrapperGenerator.S" "$FFI"

# Unified API plus three independently consumable generated facades.
"$OUT/api-wrapper-generator" cakeml > "$OUT/GeneratedApiWrappers.cml"
"$OUT/api-wrapper-generator" sml > "$OUT/GeneratedApiAdapter.sml"

for component in hol4 z3_tac tactictoe; do
  case "$component" in
    hol4) stem="Hol4" ;;
    z3_tac) stem="Z3Tac" ;;
    tactictoe) stem="TacticToe" ;;
  esac
  "$OUT/api-wrapper-generator" cakeml "$component"     > "$OUT/Generated${stem}ApiWrappers.cml"
  "$OUT/api-wrapper-generator" sml "$component"     > "$OUT/Generated${stem}ApiAdapter.sml"
done

# Type-check every generated CakeML facade. Only the unified facade is sent
# through the authoritative exact-code HOL4 lane; component facades are
# projections of the same canonical contract and generator.
for cml in   "$OUT/GeneratedApiWrappers.cml"   "$OUT/GeneratedHol4ApiWrappers.cml"   "$OUT/GeneratedZ3TacApiWrappers.cml"   "$OUT/GeneratedTacticToeApiWrappers.cml"
do
  "$CAKE" --types < "$cml" > "$cml.types"
done
"$CAKE" < "$OUT/GeneratedApiWrappers.cml" > "$OUT/GeneratedApiWrappers.S"

export GENERATED_API_WRAPPER_CML="$OUT/GeneratedApiWrappers.cml"
export GENERATED_API_WRAPPER_ASM="$OUT/GeneratedApiWrapper-hol.S"

(
  cd formal/hol4/api-wrapper
  "$HOLDIR/bin/Holmake"
)

for theory in   GeneratedApiBridgeAbiTheory.dat   GeneratedApiWrapperModelTheory.dat   GeneratedApiWrapperCompileTheory.dat   GeneratedApiWrapperSourceTheory.dat   GeneratedApiWrapperBindingsTheory.dat   GeneratedApiWrapperQualificationTheory.dat
do
  [[ -s "formal/hol4/api-wrapper/$theory" ]] || {
    echo "missing HOL4 qualification artifact: $theory" >&2
    exit 68
  }
done

python3 - "$OUT" <<'PY'
import hashlib, json, pathlib, sys
out=pathlib.Path(sys.argv[1])
api=json.loads((out/"canonical-api.json").read_text())
components={}
for name in ("hol4","z3_tac","tactictoe"):
    data=json.loads((out/f"canonical-api.{name}.json").read_text())
    components[name]=data["summary"]
files=sorted(p for p in out.iterdir() if p.is_file())
manifest={
  "schema":1,
  "status":"KERNEL_ARTIFACTS_PRESENT",
  "api_summary":api["summary"],
  "component_summaries":components,
  "files":{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in files},
  "claim":"generated wrapper protocol and exact CakeML compilation artifacts; foreign implementation correctness remains the declared contract premise"
}
(out/"manifest.json").write_text(json.dumps(manifest,indent=2,sort_keys=True)+"\n")
PY

echo "Generated HOL4/Z3_TAC/TacticToe/unified CakeML APIs with HOL4 artifacts present."
