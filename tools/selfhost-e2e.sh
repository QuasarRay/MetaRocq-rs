#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

GEN="$ROOT/generated/e2e"
HOL4_DIR="${HOL4_DIR:-$ROOT/.aegis/references/hol4}"
CAKEML_DIR="${CAKEML_DIR:-$ROOT/.aegis/references/cakeml}"
mkdir -p "$GEN/stages" "$GEN/logs"

blocked() { printf 'BLOCKED: %s\n' "$*" >&2; exit 2; }
require_file() { [[ -s "$1" ]] || blocked "required file missing/empty: $1"; }
require_hol4() { [[ -x "$HOL4_DIR/bin/Holmake" ]] || blocked "HOL4 is not built at $HOL4_DIR"; }

pins() {
  require_file spec/upstream.lock.json
  require_file spec/toolchain.lock.json
  python3 tools/metatheory_preflight.py
  python3 tools/check_hol4_selfhost_contract.py
  git diff --exit-code
  git diff --cached --exit-code
}

snapshot() {
  export OPAMROOT="${OPAMROOT:-$ROOT/.aegis/opam-root}"
  local switch="$ROOT/.aegis/opam"
  [[ -x "$switch/_opam/bin/rocq" ]] || blocked "pinned MetaRocq/Rocq switch missing"
  eval "$(opam env --switch "$switch" --set-switch)"
  local q=(-Q metatheory/original-selfhost MetaRocqRs.OriginalSelfHost)
  rocq compile "${q[@]}" metatheory/original-selfhost/PCUICModuleManifest.v
  rocq compile "${q[@]}" metatheory/original-selfhost/SelfSnapshot.v
}

lambdabox() {
  require_file generated/original-selfhost/reconciled-selfhost.ast
  sha256sum generated/original-selfhost/reconciled-selfhost.ast >"$GEN/stages/03-lambdabox.sha256"
}

erasure() {
  require_file metatheory/original-selfhost/SourceLambdaBoxRefinement.v
  if grep -nE '\bAdmitted\b|trust_coq_kernel' metatheory/original-selfhost/SourceLambdaBoxRefinement.v; then
    blocked "source -> LambdaBox proof contains forbidden shortcut"
  fi
}

peregrine() {
  require_file generated/peregrine-selfhost/final/final-e2e-theorem.txt
  require_file generated/peregrine-selfhost/final/SHA256SUMS
  require_file generated/original-selfhost/reconciled-selfhost.cakeml
}

hol4_replay() {
  require_hol4
  require_file formal/hol4/selfhost/MetaRocqReplayScript.sml
  (cd formal/hol4/selfhost && "$HOL4_DIR/bin/Holmake" MetaRocqReplayTheory)
}

cakeml() {
  require_hol4
  require_file formal/hol4/selfhost/MetaRocqCakeMLScript.sml
  (cd formal/hol4/selfhost && "$HOL4_DIR/bin/Holmake" MetaRocqCakeMLTheory)
}

machine() {
  require_hol4
  require_file formal/hol4/selfhost/MetaRocqMachineScript.sml
  (cd formal/hol4/selfhost && "$HOL4_DIR/bin/Holmake" MetaRocqMachineTheory)
  require_file "$GEN/metarocq-selfhost.S"
  sha256sum "$GEN/metarocq-selfhost.S" >"$GEN/stages/08-machine.sha256"
}

e2e() {
  require_hol4
  require_file formal/hol4/selfhost/MetaRocqE2EScript.sml
  (cd formal/hol4/selfhost && "$HOL4_DIR/bin/Holmake" MetaRocqE2ETheory)
  find formal/hol4/selfhost -name 'MetaRocqE2ETheory.dat' -print -quit | grep -q . || blocked "MetaRocqE2E theorem not produced"
}

replay_machine() {
  require_file "$GEN/final/machine.sha256"
  sha256sum -c "$GEN/final/machine.sha256"
  [[ -x tools/metarocq-selfhost-runtime-replay.sh ]] || blocked "MetaRocq runtime replay driver missing"
  tools/metarocq-selfhost-runtime-replay.sh
}

audit() {
  if grep -RInE '\bAdmitted\b|trust_coq_kernel' \
      metatheory/original-selfhost formal/hol4/selfhost \
      --include='*.v' --include='*.sml' >"$GEN/forbidden-shortcuts.txt"; then
    blocked "forbidden proof shortcuts remain in MetaRocq proof-critical sources"
  fi
  require_file "$GEN/final/final-theorem.txt"
  require_file "$GEN/final/theorem-tags.txt"
}

prove() {
  pins
  snapshot
  lambdabox
  erasure
  peregrine
  hol4_replay
  cakeml
  machine
  e2e
  replay_machine
  audit
}

publish_check() {
  tools/peregrine-selfhost-e2e.sh publish-check
  prove
  require_file "$GEN/final/SHA256SUMS"
}

clean() {
  rm -rf "$GEN/stages" "$GEN/logs"
  mkdir -p "$GEN/stages" "$GEN/logs"
}

case "${1:-}" in
  pins) pins ;;
  snapshot) snapshot ;;
  lambdabox) lambdabox ;;
  erasure) erasure ;;
  peregrine) peregrine ;;
  hol4-replay) hol4_replay ;;
  cakeml) cakeml ;;
  machine) machine ;;
  e2e) e2e ;;
  replay-machine) replay_machine ;;
  audit) audit ;;
  clean) clean ;;
  prove) prove ;;
  publish-check) publish_check ;;
  *) echo "usage: $0 {pins|snapshot|lambdabox|erasure|peregrine|hol4-replay|cakeml|machine|e2e|replay-machine|audit|clean|prove|publish-check}" >&2; exit 64 ;;
esac
