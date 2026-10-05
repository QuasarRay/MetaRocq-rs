#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SPEC="$ROOT/spec/generated-sml-api-wrapper-pipeline.json"
HOL4_DIR="${API_WRAPPER_HOL4_DIR:-$ROOT/.aegis/references/hol4-api-wrapper}"
CAKEML_SOURCE_DIR="${API_WRAPPER_CAKEML_SOURCE_DIR:-$ROOT/.aegis/references/cakeml-api-wrapper-source}"
CAKEML_DIR="${API_WRAPPER_CAKEML_DIR:-$ROOT/.aegis/references/cakeml-api-wrapper-compat}"
HOL4_REPO="$(python3 -c 'import json; d=json.load(open("'"$SPEC"'")); print(d["inputs"]["hol4"]["repo"])')"
HOL4_SHA="$(python3 -c 'import json; d=json.load(open("'"$SPEC"'")); print(d["inputs"]["hol4"]["commit"])')"
CAKE_REPO="$(python3 -c 'import json; d=json.load(open("'"$SPEC"'")); print(d["inputs"]["cakeml"]["repo"])')"
CAKE_SHA="$(python3 -c 'import json; d=json.load(open("'"$SPEC"'")); print(d["inputs"]["cakeml"]["commit"])')"

clone_pin() {
  local repo="$1" sha="$2" dir="$3"
  if [[ ! -d "$dir/.git" ]]; then git clone "$repo" "$dir"; fi
  git -C "$dir" fetch --all --tags
  git -C "$dir" checkout --detach "$sha"
  [[ "$(git -C "$dir" rev-parse HEAD)" == "$sha" ]]
  [[ -z "$(git -C "$dir" status --porcelain)" ]] || {
    echo "refusing dirty pinned checkout: $dir" >&2
    exit 70
  }
}

mkdir -p generated/api-wrapper
clone_pin "$HOL4_REPO" "$HOL4_SHA" "$HOL4_DIR"
clone_pin "$CAKE_REPO" "$CAKE_SHA" "$CAKEML_SOURCE_DIR"

if [[ ! -x "$HOL4_DIR/bin/Holmake" ]]; then
  (cd "$HOL4_DIR"; poly --script tools/smart-configure.sml; bin/build)
fi

# Reuse the audited compatibility recipe developed by the MetaRocq E2E stack.
# The pinned CakeML source remains untouched; only this derived worktree is
# adapted to the qualified HOL4 context/grammar APIs.
python3 tools/materialize_cakeml_context_compat.py \
  --source "$CAKEML_SOURCE_DIR" \
  --output "$CAKEML_DIR" \
  --receipt "$ROOT/generated/api-wrapper/cakeml-context-compat.json"

export HOLDIR="$HOL4_DIR"
export CAKEMLDIR="$CAKEML_DIR"
export PATH="$HOLDIR/bin:$PATH"
jobs="${HOL4_BUILD_JOBS:-1}"

(
  cd "$CAKEML_DIR/basis"
  "$HOLDIR/bin/Holmake" -j"$jobs" basis.uo basis_ffiTheory.dat Word8ArrayProofTheory.dat
)
(
  cd "$CAKEML_DIR/characteristic"
  "$HOLDIR/bin/Holmake" -j"$jobs" cfTacticsLib.uo cfMainTheory.dat
)
(
  cd "$CAKEML_DIR/cv_translator"
  "$HOLDIR/bin/Holmake" -j"$jobs" eval_cake_compile_x64Lib.uo
)

{
  printf 'export HOL4_SRC=%q\n' "$HOL4_DIR"
  printf 'export HOLDIR=%q\n' "$HOL4_DIR"
  printf 'export CAKEML_SOURCE=%q\n' "$CAKEML_SOURCE_DIR"
  printf 'export CAKEML_SRC=%q\n' "$CAKEML_DIR"
  printf 'export CAKEMLDIR=%q\n' "$CAKEML_DIR"
} > generated/api-wrapper/proof-toolchain.env

sha256sum \
  "$HOL4_DIR/bin/Holmake" \
  "$CAKEML_SOURCE_DIR/cv_translator/eval_cake_compile_x64Lib.sml" \
  generated/api-wrapper/cakeml-context-compat.json \
  spec/generated-sml-api-wrapper-pipeline.json \
  tools/materialize_cakeml_context_compat.py \
  tools/prepare_generated_api_wrapper_toolchain.sh \
  > generated/api-wrapper/proof-toolchain.sha256

echo "Prepared generated-wrapper HOL4/CakeML proof stack using the historical compatibility recipe."
