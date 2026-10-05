#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

GEN="$ROOT/generated/peregrine-selfhost"
STAGES="$GEN/stages"
OPAMROOT="${OPAMROOT:-$ROOT/.aegis/opam-root}"
SWITCH="$ROOT/.aegis/opam"
HOL4_DIR="${HOL4_DIR:-$ROOT/.aegis/references/hol4}"
CAKEML_DIR="${CAKEML_DIR:-$ROOT/.aegis/references/cakeml}"
PEREGRINE_DIR="$ROOT/.aegis/references/peregrine-selfhost"
BACKEND_DIR="$ROOT/.aegis/references/peregrine-cakeml-selfhost"

PEREGRINE_COMMIT=d768b83ffa7dab35b8d72241f0570b5bb6aedae9
BACKEND_PROOF_COMMIT=5baed0b21618480b30711eb9df87e9bf00537372
METAROCQ_COMMIT=7197056adbb9c15288b4c8d43407bf25786f723e
CAKEML_COMMIT=c98da7fc904c5d6d0e9a75a18fac1796a9bfb1f9
HOL4_COMMIT=40dd5b03de658f4bd9e3f4225fb0f1602ac90467

mkdir -p "$GEN" "$STAGES"

blocked() { printf 'BLOCKED: %s\n' "$*" >&2; exit 2; }
require_file() { [[ -s "$1" ]] || blocked "required file missing/empty: $1"; }
require_cmd() { command -v "$1" >/dev/null 2>&1 || blocked "required command missing: $1"; }
sha_file() { sha256sum "$1" | tee "$1.sha256"; }

check_repo() {
  local dir=$1 expected=$2
  [[ -d "$dir/.git" ]] || blocked "missing pinned checkout: $dir"
  [[ "$(git -C "$dir" rev-parse HEAD)" == "$expected" ]] || blocked "wrong commit in $dir"
  git -C "$dir" diff --exit-code
  git -C "$dir" diff --cached --exit-code
}

clone_exact() {
  local url=$1 commit=$2 dir=$3 recurse=${4:-false}
  if [[ ! -d "$dir/.git" ]]; then
    if [[ "$recurse" == true ]]; then
      git clone --recurse-submodules --jobs "$(nproc)" "$url" "$dir"
    else
      git clone "$url" "$dir"
    fi
  fi
  git -C "$dir" fetch --tags --force origin "$commit"
  git -C "$dir" checkout --detach "$commit"
  if [[ "$recurse" == true ]]; then
    git -C "$dir" submodule sync --recursive
    git -C "$dir" submodule update --init --recursive
  fi
  check_repo "$dir" "$commit"
}

activate_seed() {
  export OPAMROOT
  if [[ -x "$SWITCH/_opam/bin/rocq" ]]; then
    eval "$(opam env --switch "$SWITCH" --set-switch)"
  fi
  require_cmd rocq
}

pins() {
  require_file spec/peregrine-selfhost-e2e.json
  python3 tools/check_peregrine_selfhost_contract.py
  [[ ! -d "$PEREGRINE_DIR/.git" ]] || check_repo "$PEREGRINE_DIR" "$PEREGRINE_COMMIT"
  [[ ! -d "$BACKEND_DIR/.git" ]] || check_repo "$BACKEND_DIR" "$BACKEND_PROOF_COMMIT"
  [[ ! -d "$CAKEML_DIR/.git" ]] || check_repo "$CAKEML_DIR" "$CAKEML_COMMIT"
  [[ ! -d "$HOL4_DIR/.git" ]] || check_repo "$HOL4_DIR" "$HOL4_COMMIT"
  cat >"$STAGES/01-pins.json" <<JSON
{"status":"CHECKED","peregrine":"$PEREGRINE_COMMIT","peregrine_cakeml_proof":"$BACKEND_PROOF_COMMIT","metarocq":"$METAROCQ_COMMIT","cakeml":"$CAKEML_COMMIT","hol4":"$HOL4_COMMIT"}
JSON
}

clone_stage() {
  mkdir -p "$ROOT/.aegis/references"
  clone_exact https://github.com/peregrine-project/peregrine-tool.git "$PEREGRINE_COMMIT" "$PEREGRINE_DIR" true
  if [[ -f "$PEREGRINE_DIR/.gitmodules" ]]; then
    cat "$PEREGRINE_DIR/.gitmodules" >"$GEN/peregrine-gitmodules.txt"
  else
    printf '%s\n' 'NO .gitmodules AT PINNED PEREGRINE REVISION' >"$GEN/peregrine-gitmodules.txt"
  fi
  git -C "$PEREGRINE_DIR" submodule status --recursive >"$GEN/peregrine-submodules.txt"
  clone_exact https://github.com/peregrine-project/cakeml-backend.git "$BACKEND_PROOF_COMMIT" "$BACKEND_DIR" false
  require_file "$BACKEND_DIR/theories/Backend/CompileCorrect.v"
}

seed() {
  mkdir -p "$GEN/seed"
  if [[ -n "${METAROCQ_RS_SEED:-}" && -x "${METAROCQ_RS_SEED}" ]]; then
    require_file "${METAROCQ_RS_SEED_MANIFEST:-}"
    sha256sum "$METAROCQ_RS_SEED" >"$GEN/seed/metarocq-rs-seed.sha256"
    cp "${METAROCQ_RS_SEED_MANIFEST}" "$GEN/seed/manifest.json"
    printf '%s\n' 'METAROCQ_RS_BINARY' >"$GEN/seed/kind.txt"
  elif [[ -x "$SWITCH/_opam/bin/rocq" && -x "$SWITCH/_opam/bin/peregrine" ]]; then
    export OPAMROOT
    eval "$(opam env --switch "$SWITCH" --set-switch)"
    {
      command -v rocq
      rocq -v
      command -v peregrine
      opam list --installed --switch "$SWITCH"
    } >"$GEN/seed/prebuilt-packages.txt"
    sha_file "$GEN/seed/prebuilt-packages.txt" >/dev/null
    printf '%s\n' 'PREBUILT_ROCQ_METAROCQ_PACKAGES' >"$GEN/seed/kind.txt"
  else
    require_cmd opam
    bash tools/install_extraction.sh
    export OPAMROOT
    eval "$(opam env --switch "$SWITCH" --set-switch)"
    printf '%s\n' 'ONE_TIME_PINNED_SOURCE_BUILD' >"$GEN/seed/kind.txt"
  fi
  require_cmd rocq
  require_cmd peregrine
}

snapshot() {
  activate_seed
  local q0=(-Q metatheory/original-selfhost MetaRocqRs.OriginalSelfHost)
  rocq compile "${q0[@]}" metatheory/original-selfhost/PCUICModuleManifest.v
  rocq compile "${q0[@]}" metatheory/original-selfhost/SelfSnapshot.v
  local q=(
    -Q metatheory/original-selfhost MetaRocqRs.OriginalSelfHost
    -Q metatheory/peregrine-selfhost MetaRocqRs.PeregrineSelfHost
  )
  for f in \
    PeregrineSourceManifest.v \
    PeregrineLoadAll.v \
    PeregrineSnapshot.v \
    MaterializePeregrineSnapshot.v \
    PeregrineProofCorpus.v \
    PeregrineSelfHostEntrypoint.v
  do
    rocq compile "${q[@]}" "metatheory/peregrine-selfhost/$f"
  done
}

lambdabox() {
  activate_seed
  local q=(
    -Q metatheory/original-selfhost MetaRocqRs.OriginalSelfHost
    -Q metatheory/peregrine-selfhost MetaRocqRs.PeregrineSelfHost
  )
  rocq compile "${q[@]}" metatheory/peregrine-selfhost/ExtractPeregrineSelfHost.v
  require_file "$GEN/peregrine-selfhost.ast"
  sha_file "$GEN/peregrine-selfhost.ast" >/dev/null
}

candidate() {
  activate_seed
  require_file "$GEN/peregrine-selfhost.ast"
  mkdir -p "$GEN/cakeml"
  peregrine cakeml "$GEN/peregrine-selfhost.ast" -o "$GEN/cakeml/peregrine-selfhost.cml"
  require_file "$GEN/cakeml/peregrine-selfhost.cml"
  sha_file "$GEN/cakeml/peregrine-selfhost.cml" >/dev/null
  printf '%s\n' CANDIDATE_GENERATED >"$GEN/cakeml/status.txt"
}

translation_proof() {
  check_repo "$BACKEND_DIR" "$BACKEND_PROOF_COMMIT"
  require_file "$BACKEND_DIR/theories/Backend/CompileCorrect.v"
  local proof=metatheory/peregrine-selfhost/PeregrineCakeMLPipelineCorrect.v
  require_file "$proof"
  if grep -nE '\bAdmitted\b|trust_coq_kernel|post[[:space:]]*=[[:space:]]*True|obseq[[:space:]]*=[[:space:]]*True' "$proof"; then
    blocked "forbidden translation-proof shortcut detected"
  fi
  activate_seed
  local q=(
    -Q metatheory/original-selfhost MetaRocqRs.OriginalSelfHost
    -Q metatheory/peregrine-selfhost MetaRocqRs.PeregrineSelfHost
  )
  rocq compile "${q[@]}" "$proof"
  require_file "$GEN/cakeml/peregrine-selfhost.cml"
}

build_hol4() {
  [[ -x "$HOL4_DIR/bin/Holmake" ]] || blocked "HOL4 is not built at $HOL4_DIR"
}

hol4_replay() {
  build_hol4
  local src=formal/hol4/PeregrineProofReplayScript.sml
  require_file "$src"
  mkdir -p "$GEN/hol4/replay"
  cp "$src" "$GEN/hol4/replay/"
  (cd "$GEN/hol4/replay" && "$HOL4_DIR/bin/Holmake")
  find "$GEN/hol4/replay" -name '*Theory.dat' -print -quit | grep -q . || blocked "HOL4 replay theorem was not produced"
}

cakeml_program() {
  build_hol4
  require_file formal/hol4/PeregrineGeneratedCompileScript.sml
  require_file "$GEN/cakeml/peregrine-selfhost.cml"
  [[ -d "$CAKEML_DIR/examples/compilation/x64" ]] || blocked "pinned CakeML checkout missing"
  cp formal/hol4/PeregrineGeneratedCompileScript.sml "$CAKEML_DIR/examples/compilation/x64/"
  export PEREGRINE_CAKEML_SEXP="$GEN/cakeml/peregrine-selfhost.cml"
  export PEREGRINE_MACHINE_ASM="$GEN/peregrine-selfhost.S"
  (cd "$CAKEML_DIR/examples/compilation/x64" && "$HOL4_DIR/bin/Holmake" PeregrineGeneratedCompileTheory)
}

capsule() {
  require_file spec/peregrine-proof-capsule-v1.json
  require_file formal/hol4/PeregrineEmbeddedCapsuleCorrectScript.sml
  build_hol4
  mkdir -p "$GEN/capsule/hol4"
  cp formal/hol4/PeregrineEmbeddedCapsuleCorrectScript.sml "$GEN/capsule/hol4/"
  (cd "$GEN/capsule/hol4" && "$HOL4_DIR/bin/Holmake")
}

machine() {
  cakeml_program
  require_file "$GEN/peregrine-selfhost.S"
  sha_file "$GEN/peregrine-selfhost.S" >/dev/null
}

compose_e2e() {
  build_hol4
  local theorem=formal/hol4/PeregrineSelfHostE2EScript.sml
  require_file "$theorem"
  mkdir -p "$GEN/hol4/e2e"
  cp "$theorem" "$GEN/hol4/e2e/"
  (cd "$GEN/hol4/e2e" && "$HOL4_DIR/bin/Holmake")
  find "$GEN/hol4/e2e" -name 'PeregrineSelfHostE2ETheory.dat' -print -quit | grep -q . || blocked "PeregrineSelfHostE2E theorem not produced"
}

replay_machine() {
  require_file "$GEN/final/machine.sha256"
  sha256sum -c "$GEN/final/machine.sha256"
  [[ -x tools/peregrine-selfhost-runtime-replay.sh ]] || blocked "runtime replay driver missing"
  tools/peregrine-selfhost-runtime-replay.sh
}

fresh_revalidate() {
  [[ -x tools/peregrine-selfhost-revalidate.sh ]] || blocked "fresh HOL4 revalidation driver missing"
  require_file "$GEN/final/machine.sha256"
  tools/peregrine-selfhost-revalidate.sh --manifest "$GEN/final/machine.sha256"
  require_file "$GEN/revalidation/fresh-e2e-theorem.txt"
}

audit() {
  require_file spec/peregrine-selfhost-e2e.json
  if grep -RInE '\bAdmitted\b|trust_coq_kernel' \
      metatheory/peregrine-selfhost formal/hol4 \
      --include='*.v' --include='*.sml' >"$GEN/forbidden-shortcuts.txt"; then
    blocked "forbidden proof shortcuts remain in proof-critical local sources"
  fi
  require_file "$GEN/cakeml/peregrine-selfhost.cml.sha256"
}

mutations() {
  [[ -x tools/peregrine-selfhost-mutations.sh ]] || blocked "mutation suite missing"
  tools/peregrine-selfhost-mutations.sh
}

prove() {
  pins
  clone_stage
  seed
  snapshot
  lambdabox
  candidate
  translation_proof
  hol4_replay
  cakeml_program
  capsule
  machine
  compose_e2e
  replay_machine
  fresh_revalidate
  audit
}

publish_check() {
  prove
  mutations
  require_file "$GEN/final/final-e2e-theorem.txt"
  require_file "$GEN/final/fresh-e2e-theorem.txt"
  require_file "$GEN/final/SHA256SUMS"
}

clean() {
  rm -rf "$GEN/stages" "$GEN/hol4" "$GEN/revalidation"
  rm -f "$GEN"/*.sha256 "$GEN"/*.S
}

producer() {
  pins
  seed
  snapshot
  lambdabox
  candidate
}

cmd=${1:-}
case "$cmd" in
  pins) pins ;;
  clone) clone_stage ;;
  seed) seed ;;
  snapshot) snapshot ;;
  lambdabox) lambdabox ;;
  candidate) candidate ;;
  translation-proof) translation_proof ;;
  hol4-replay) hol4_replay ;;
  cakeml-program) cakeml_program ;;
  capsule) capsule ;;
  machine) machine ;;
  compose-e2e) compose_e2e ;;
  replay-machine) replay_machine ;;
  fresh-revalidate) fresh_revalidate ;;
  audit) audit ;;
  mutations) mutations ;;
  prove) prove ;;
  publish-check) publish_check ;;
  producer) producer ;;
  clean) clean ;;
  *) echo "usage: $0 {pins|clone|seed|snapshot|lambdabox|candidate|translation-proof|hol4-replay|cakeml-program|capsule|machine|compose-e2e|replay-machine|fresh-revalidate|audit|mutations|clean|producer|prove|publish-check}" >&2; exit 64 ;;
esac
