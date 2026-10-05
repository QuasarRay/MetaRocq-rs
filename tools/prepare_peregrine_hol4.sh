#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
source tools/hol4_artifacts.sh

HOL4_DIR="${HOL4_DIR:-$ROOT/.aegis/references/hol4}"
CAKEML_SOURCE_DIR="${CAKEML_SOURCE_DIR:-${CAKEML_DIR:-$ROOT/.aegis/references/cakeml}}"
compat_key="$(python3 - "$CAKEML_SOURCE_DIR/misc/preamble.sml" <<'PY'
import hashlib, pathlib, sys
sys.path.insert(0, 'tools')
from materialize_cakeml_context_compat import compatibility_key
print(compatibility_key(pathlib.Path(sys.argv[1]).parents[1]))
PY
)"
CAKEML_DIR="${CAKEML_COMPAT_DIR:-$ROOT/.aegis/derived/cakeml-context-$compat_key}"
HOLGEN="$ROOT/generated/peregrine-selfhost/hol4"
mkdir -p "$HOLGEN"

python3 - "$ROOT/spec/toolchain.lock.json" "$HOL4_DIR" "$CAKEML_SOURCE_DIR" <<'PY'
import json, subprocess, sys
lock, hol, cake = sys.argv[1:]
data = json.load(open(lock, encoding="utf-8"))
for key, path in (("hol4", hol), ("cakeml", cake)):
    expected = data["repositories"][key]["commit"]
    actual = subprocess.check_output(["git", "-C", path, "rev-parse", "HEAD"], text=True).strip()
    if actual != expected:
        raise SystemExit(f"{key} pin mismatch: expected {expected}, got {actual}")
PY

python3 tools/materialize_cakeml_context_compat.py \
  --source "$CAKEML_SOURCE_DIR" --output "$CAKEML_DIR" \
  --receipt "$HOLGEN/cakeml-context-compat.json"

if [[ ! -x "$HOL4_DIR/bin/Holmake" ]]; then
  (
    cd "$HOL4_DIR"
    poly --script tools/smart-configure.sml
    bin/build
  )
fi

export HOLDIR="$HOL4_DIR"
export CAKEMLDIR="$CAKEML_DIR"
export PATH="$HOLDIR/bin:$PATH"

# Build only the in-logic x64 compiler evaluator first. Holmake follows the
# include graph to already-built dependencies; if the checkout is fresh this
# command exposes the first genuinely missing CakeML theory rather than hiding
# it behind a native compiler invocation.
(
  cd "$CAKEML_DIR/cv_translator"
  "$HOLDIR/bin/Holmake" -j2 eval_cake_compile_x64Lib.uo
)

hol4_artifact_path "$CAKEML_DIR/cv_translator/eval_cake_compile_x64Lib.uo" >/dev/null
{
  printf 'export HOL4_DIR=%q\n' "$HOL4_DIR"
  printf 'export CAKEML_SOURCE_DIR=%q\n' "$CAKEML_SOURCE_DIR"
  printf 'export CAKEML_DIR=%q\n' "$CAKEML_DIR"
  printf 'export HOLDIR=%q\n' "$HOL4_DIR"
  printf 'export CAKEMLDIR=%q\n' "$CAKEML_DIR"
} > "$HOLGEN/toolchain.env"
sha256sum "$HOLGEN/cakeml-context-compat.json" "$HOLGEN/toolchain.env" \
  "$CAKEML_DIR/misc/preamble.sml" "$HOL4_DIR/src/1/Tactical.sig" \
  tools/materialize_cakeml_context_compat.py tools/prepare_peregrine_hol4.sh \
  > "$HOLGEN/compiler-preparation-inputs.sha256"
python3 - "$HOLGEN/cakeml-context-compat.json" "$HOLGEN/compiler-preparation-inputs.sha256" <<'PY'
import json, pathlib, subprocess, sys
recipe = json.loads(pathlib.Path(sys.argv[1]).read_text())
paths = [str(pathlib.Path(recipe['derived_source']) / n)
         for n in recipe['modified_files'] if n != 'misc/preamble.sml']
if paths:
    with open(sys.argv[2], 'a') as output:
        subprocess.run(['sha256sum', *paths], check=True, stdout=output)
PY
printf 'HOL4_DIR=%s\nCAKEML_DIR=%s\n' "$HOL4_DIR" "$CAKEML_DIR"
