#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ID="${1:-}"
[[ "$ID" =~ ^(0[1-9]|1[0-9]|2[0-3])$ ]] || { echo "invalid stage id: $ID" >&2; exit 64; }
TRACE="${E2E_TRACE_DIR:?E2E_TRACE_DIR must be set by the trace runner}"
STAGE_DIR="$TRACE/stages/$ID"
mkdir -p "$STAGE_DIR"

# Adapt CakeML/regression worker semantics: each stage has a status file,
# combined stdout/stderr and /usr/bin/time -v resource accounting. The outer
# invocation observes the inner invocation so even shell/process failures are
# retained before the CakeML controller receives the exit code.
if [[ "${E2E_STAGE_OBS_ACTIVE:-0}" != "1" ]]; then
  set +e
  /usr/bin/time -v -o "$STAGE_DIR/time-memory.txt" \
    env E2E_STAGE_OBS_ACTIVE=1 "$0" "$ID" \
    >"$STAGE_DIR/stdout-stderr.log" 2>&1
  rc=$?
  set -e
  printf 'exit=%s\n' "$rc" > "$STAGE_DIR/status.txt"
  if [[ "$rc" -eq 0 ]]; then
    printf 'SUCCESS\n' > "$STAGE_DIR/regression-result.txt"
  else
    printf 'FAILED: stage %s exit=%s\n' "$ID" "$rc" > "$STAGE_DIR/regression-result.txt"
  fi
  cat "$STAGE_DIR/stdout-stderr.log"
  exit "$rc"
fi

fail() { printf 'FAILED: stage %s: %s\n' "$ID" "$*" | tee "$STAGE_DIR/failure.txt" >&2; exit 1; }
require_file() { [[ -s "$1" ]] || fail "required file missing or empty: $1"; }
require_cmd() { command -v "$1" >/dev/null 2>&1 || fail "required command unavailable: $1"; }
reject_trust_escape() {
  local f="$1"
  require_file "$f"
  if grep -nE '\b(Admitted|admit|trust_coq_kernel|assume_can_be_extracted)\b' "$f" > "$STAGE_DIR/forbidden.txt"; then
    fail "forbidden trust escape found in $f"
  fi
}
receipt() { printf '%s\n' "$*" >> "$STAGE_DIR/receipt.txt"; }

MANUAL="docs/unified-peregrine-metarocq-e2e"

case "$ID" in
  01)
    require_file "$MANUAL/README.md"
    count="$(find "$MANUAL" -maxdepth 1 -type f -name '*.md' | wc -l)"
    [[ "$count" -eq 24 ]] || fail "expected README + 23 instruction files, found $count"
    require_file spec/peregrine-selfhost-e2e.json
    require_file spec/hol4-selfhost-e2e.json
    git rev-parse HEAD > "$STAGE_DIR/repository-head.txt"
    receipt "Frozen instruction count: $count"
    receipt "No proof gate is opened by this stage."
    ;;
  02)
    require_cmd git
    require_cmd python3
    # This stage owns the clone/pin/audit boundary. Reuse the existing lockfile-
    # driven bootstrap so a fresh GitHub Actions runner does not assume local
    # reference checkouts already exist.
    python3 -B tools/bootstrap.py sources
    python3 tools/check_peregrine_selfhost_contract.py
    grep -Fq 'd768b83ffa7dab35b8d72241f0570b5bb6aedae9' spec/peregrine-selfhost-e2e.json ||
      fail "Peregrine pin drift"
    receipt "Pinned source checkouts bootstrapped from spec/toolchain.lock.json."
    receipt "Pinned Peregrine/source contract verified."
    ;;
  03)
    require_cmd bash
    # The existing producer already performs the self-reflective quotation,
    # complete retained proof/assumption/replay payload and LambdaBox->CakeML
    # candidate production. Run it once; Steps 04-05 consume these exact bytes.
    bash tools/peregrine_selfhost_pipeline.sh
    require_file generated/peregrine-selfhost/peregrine-selfhost.ast
    require_file metatheory/peregrine-selfhost/PeregrineRuntimeReplay.v
    require_file metatheory/peregrine-selfhost/PeregrineSelfHostEntrypoint.v
    grep -Fq 'replay_peregrine_runtime_program' \
      metatheory/peregrine-selfhost/PeregrineRuntimeReplay.v ||
      fail "runtime replay implementation missing"
    grep -Fq 'ReplayPeregrineRuntimeProofs' \
      metatheory/peregrine-selfhost/PeregrineSelfHostEntrypoint.v ||
      fail "runtime replay command missing from extraction root"
    sha256sum \
      generated/peregrine-selfhost/peregrine-selfhost.ast \
      metatheory/peregrine-selfhost/PeregrineRuntimeReplay.v \
      metatheory/peregrine-selfhost/PeregrineSelfHostEntrypoint.v \
      > "$STAGE_DIR/lambdabox-replay-inputs.sha256"
    receipt "Selfhost LambdaBox/proof corpus producer completed."
    receipt "Replay-capable entrypoint retained; diagnostic checker success is not semantic proof."
    ;;
  04)
    require_file generated/peregrine-selfhost/rocq-version.txt
    require_file generated/peregrine-selfhost/peregrine-help.txt
    require_file generated/peregrine-selfhost/producer-boundary.txt
    grep -Fq 'process success is not semantic evidence' generated/peregrine-selfhost/producer-boundary.txt ||
      fail "producer trust boundary missing"
    receipt "Exact prebuilt/rebuilt producer boundary recorded."
    ;;
  05)
    require_file generated/peregrine-selfhost/peregrine-selfhost.cakeml
    require_file generated/peregrine-selfhost/peregrine-selfhost.cakeml.sha256
    require_file generated/peregrine-selfhost/peregrine-selfhost.checked.cakeml
    require_file generated/peregrine-selfhost/peregrine-selfhost.checked.cakeml.sha256
    require_file generated/peregrine-selfhost/checked-native-cakeml-equality.txt
    sha256sum --check generated/peregrine-selfhost/peregrine-selfhost.cakeml.sha256
    sha256sum --check generated/peregrine-selfhost/peregrine-selfhost.checked.cakeml.sha256
    grep -Fxq 'byte-identical' \
      generated/peregrine-selfhost/checked-native-cakeml-equality.txt ||
      fail "checked/native CakeML equality marker missing"
    cmp -s \
      generated/peregrine-selfhost/peregrine-selfhost.cakeml \
      generated/peregrine-selfhost/peregrine-selfhost.checked.cakeml ||
      fail "checked/native CakeML candidate bytes differ"
    sha256sum \
      generated/peregrine-selfhost/peregrine-selfhost.cakeml \
      generated/peregrine-selfhost/peregrine-selfhost.checked.cakeml \
      generated/peregrine-selfhost/checked-native-cakeml-equality.txt \
      metatheory/peregrine-selfhost/PeregrineCheckedCakeMLProducer.v \
      metatheory/peregrine-selfhost/PeregrineRuntimeReplay.v \
      metatheory/peregrine-selfhost/PeregrineSelfHostEntrypoint.v \
      > "$STAGE_DIR/cakeml-replay-binding-inputs.sha256"
    receipt "Native and checked-adapter CakeML candidates are byte-identical."
    receipt "Equality is engineering/provenance evidence only; it is not semantic preservation proof."
    receipt "Replay and checked-producer source identities recorded with both exact CakeML candidates."
    ;;
  06)
    proof="metatheory/peregrine-selfhost/PeregrineCakeMLPipelineCorrect.v"
    reject_trust_escape "$proof"
    require_cmd rocq
    rocq compile -Q metatheory/peregrine-selfhost MetaRocqRs.PeregrineSelfHost "$proof"
    receipt "LambdaBox->CakeML proof-gap theorem compiled without forbidden trust escapes."
    ;;
  07)
    proof="formal/hol4/PeregrineSelfHostE2EScript.sml"
    reject_trust_escape "$proof"
    require_file generated/peregrine-selfhost/peregrine-selfhost.cakeml
    [[ -x "${HOL4_DIR:-}/bin/Holmake" ]] || fail "HOL4_DIR/bin/Holmake unavailable"
    mkdir -p "$STAGE_DIR/hol4"
    cp "$proof" "$STAGE_DIR/hol4/"
    (cd "$STAGE_DIR/hol4" && "$HOL4_DIR/bin/Holmake")
    find "$STAGE_DIR/hol4" -name 'PeregrineSelfHostE2ETheory.dat' -print -quit | grep -q . ||
      fail "PeregrineSelfHostE2ETheory.dat not produced"
    receipt "Exact Peregrine CakeML-to-machine theorem kernel checked."
    ;;
  08)
    proof="formal/hol4/PeregrineEmbeddedCertificateScript.sml"
    reject_trust_escape "$proof"
    require_file cakeml/peregrine-selfhost/CertificateRuntime.sml
    [[ -x "${HOL4_DIR:-}/bin/Holmake" ]] || fail "HOL4_DIR/bin/Holmake unavailable"
    mkdir -p "$STAGE_DIR/hol4"
    cp "$proof" "$STAGE_DIR/hol4/"
    (cd "$STAGE_DIR/hol4" && "$HOL4_DIR/bin/Holmake")
    receipt "Non-circular embedded proof-capsule correspondence checked."
    ;;
  09)
    proof="formal/hol4/PeregrineIndependentReplayScript.sml"
    reject_trust_escape "$proof"
    [[ -x "${HOL4_FRESH_DIR:-}/bin/Holmake" ]] || fail "fresh independent HOL4 not available in HOL4_FRESH_DIR"
    mkdir -p "$STAGE_DIR/fresh-hol4"
    cp "$proof" "$STAGE_DIR/fresh-hol4/"
    (cd "$STAGE_DIR/fresh-hol4" && "$HOL4_FRESH_DIR/bin/Holmake")
    receipt "Fresh independent HOL4 revalidation completed."
    ;;
  10)
    require_file "$TRACE/stages/07/receipt.txt"
    require_file "$TRACE/stages/08/receipt.txt"
    require_file "$TRACE/stages/09/receipt.txt"
    require_file spec/peregrine-selfhost-e2e.json
    receipt "Peregrine Part-I publication gate passed using theorem-bound evidence."
    ;;
  11)
    require_file spec/original-metarocq-selfhost.json
    require_file spec/hol4-selfhost-e2e.json
    grep -Fq '"status"' spec/hol4-selfhost-e2e.json || fail "HOL4 selfhost contract malformed"
    receipt "MetaRocq trust/completion criteria frozen."
    ;;
  12)
    require_cmd python3
    python3 tools/check_hol4_selfhost_contract.py
    require_file spec/toolchain.lock.json
    receipt "Pinned MetaRocq/HOL4/CakeML toolchain contract reproduced."
    ;;
  13)
    require_file spec/source-inventory.json
    require_file metatheory/original-selfhost/PCUICModuleManifest.v
    require_file metatheory/original-selfhost/SelfSnapshot.v
    require_file metatheory/original-selfhost/RetainedPayload.v
    sha256sum spec/source-inventory.json metatheory/original-selfhost/PCUICModuleManifest.v       metatheory/original-selfhost/SelfSnapshot.v metatheory/original-selfhost/RetainedPayload.v       > "$STAGE_DIR/source-proof-corpus.sha256"
    receipt "Complete source/specification/proof-corpus inputs bound."
    ;;
  14)
    require_file metatheory/original-selfhost/HOL4SelfHostEntrypoint.v
    require_file metatheory/original-selfhost/SourceLambdaBoxRefinement.v
    require_file metatheory/original-selfhost/ReflectiveDualRecursion.v
    require_file generated/original-metarocq-selfhost/metarocq-selfhost.ast
    sha256sum generated/original-metarocq-selfhost/metarocq-selfhost.ast > "$STAGE_DIR/metarocq-lambdabox.sha256"
    receipt "Self-reflective retained MetaRocq LambdaBox bound."
    ;;
  15)
    proof="formal/hol4/MetaRocqErasureClosureScript.sml"
    reject_trust_escape "$proof"
    [[ -x "${HOL4_DIR:-}/bin/Holmake" ]] || fail "HOL4_DIR/bin/Holmake unavailable"
    mkdir -p "$STAGE_DIR/hol4"
    cp "$proof" "$STAGE_DIR/hol4/"
    (cd "$STAGE_DIR/hol4" && "$HOL4_DIR/bin/Holmake")
    receipt "Erasure correctness and assumption closure kernel checked."
    ;;
  16)
    require_file "$TRACE/stages/10/receipt.txt"
    require_file metatheory/original-selfhost/IntegratedPeregrineCakeML.v
    reject_trust_escape metatheory/original-selfhost/IntegratedPeregrineCakeML.v
    receipt "Exact verified Part-I Peregrine bridge reused; no native-process substitution."
    ;;
  17)
    proof="formal/hol4/MetaRocqProofCorpusReplayScript.sml"
    reject_trust_escape "$proof"
    [[ -x "${HOL4_DIR:-}/bin/Holmake" ]] || fail "HOL4_DIR/bin/Holmake unavailable"
    mkdir -p "$STAGE_DIR/hol4"
    cp "$proof" "$STAGE_DIR/hol4/"
    (cd "$STAGE_DIR/hol4" && "$HOL4_DIR/bin/Holmake")
    receipt "Complete MetaRocq proof corpus replayed in HOL4."
    ;;
  18)
    proof="formal/hol4/MetaRocqGeneratedCompileScript.sml"
    reject_trust_escape "$proof"
    [[ -x "${HOL4_DIR:-}/bin/Holmake" ]] || fail "HOL4_DIR/bin/Holmake unavailable"
    require_file generated/original-metarocq-selfhost/metarocq-selfhost.cakeml
    mkdir -p "$STAGE_DIR/hol4"
    cp "$proof" "$STAGE_DIR/hol4/"
    (cd "$STAGE_DIR/hol4" && "$HOL4_DIR/bin/Holmake")
    receipt "Exact MetaRocq CakeML AST compiled inside HOL4."
    ;;
  19)
    proof="formal/hol4/MetaRocqSelfHostE2EScript.sml"
    reject_trust_escape "$proof"
    [[ -x "${HOL4_DIR:-}/bin/Holmake" ]] || fail "HOL4_DIR/bin/Holmake unavailable"
    mkdir -p "$STAGE_DIR/hol4"
    cp "$proof" "$STAGE_DIR/hol4/"
    (cd "$STAGE_DIR/hol4" && "$HOL4_DIR/bin/Holmake")
    find "$STAGE_DIR/hol4" -name 'MetaRocqSelfHostE2ETheory.dat' -print -quit | grep -q . ||
      fail "unified source-to-machine theory not produced"
    receipt "Unified source/specification/proof-to-machine theorem kernel checked."
    ;;
  20)
    proof="formal/hol4/MetaRocqRecursiveReplayScript.sml"
    reject_trust_escape "$proof"
    [[ -x "${HOL4_FRESH_DIR:-}/bin/Holmake" ]] || fail "fresh independent HOL4 not available in HOL4_FRESH_DIR"
    mkdir -p "$STAGE_DIR/fresh-hol4"
    cp "$proof" "$STAGE_DIR/fresh-hol4/"
    (cd "$STAGE_DIR/fresh-hol4" && "$HOL4_FRESH_DIR/bin/Holmake")
    receipt "Recursive machine self-replay theorem independently reconstructed."
    ;;
  21)
    require_cmd git
    require_cmd sha256sum
    require_file "$MANUAL/21-metarocq-local-operation-debugging-and-recovery.md"
    git status --porcelain=v1 > "$STAGE_DIR/git-status.txt"
    df -h > "$STAGE_DIR/disk.txt"
    receipt "Local debugging/recovery evidence captured."
    ;;
  22)
    for n in $(seq -w 11 21); do require_file "$TRACE/stages/$n/receipt.txt"; done
    require_file "$TRACE/stages/10/receipt.txt"
    git fsck --no-dangling > "$STAGE_DIR/git-fsck.txt"
    receipt "Final MetaRocq audit/publication gate passed."
    ;;
  23)
    for n in $(seq -w 1 22); do require_file "$TRACE/stages/$n/receipt.txt"; done
    {
      echo "# Unified E2E provenance"
      echo
      echo "repository_head=$(git rev-parse HEAD)"
      echo "peregrine_part_i_receipt=$TRACE/stages/10/receipt.txt"
      echo "metarocq_part_ii_receipt=$TRACE/stages/22/receipt.txt"
      echo
      echo "No open blocking proof obligation may be silently converted to success."
    } > "$STAGE_DIR/unified-provenance.md"
    receipt "Unified reuse/provenance report emitted."
    ;;
esac

printf 'SUCCESS: stage %s\n' "$ID" | tee "$STAGE_DIR/success.txt"
