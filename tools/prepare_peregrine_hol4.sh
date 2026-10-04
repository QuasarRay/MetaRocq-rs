#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
source tools/hol4_artifacts.sh

HOL4_DIR="${HOL4_DIR:-$ROOT/.aegis/references/hol4}"
CAKEML_DIR="${CAKEML_DIR:-$ROOT/.aegis/references/cakeml}"

python3 - "$ROOT/spec/toolchain.lock.json" "$HOL4_DIR" "$CAKEML_DIR" <<'PY'
import json, subprocess, sys
lock, hol, cake = sys.argv[1:]
data = json.load(open(lock, encoding="utf-8"))
for key, path in (("hol4", hol), ("cakeml", cake)):
    expected = data["repositories"][key]["commit"]
    actual = subprocess.check_output(["git", "-C", path, "rev-parse", "HEAD"], text=True).strip()
    if actual != expected:
        raise SystemExit(f"{key} pin mismatch: expected {expected}, got {actual}")
PY

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
printf 'HOL4_DIR=%s\nCAKEML_DIR=%s\n' "$HOL4_DIR" "$CAKEML_DIR"
