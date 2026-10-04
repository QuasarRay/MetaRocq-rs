#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
STAGE="${1:?stage id required}"
GEN="$ROOT/generated/unified-e2e"
PGEN="$ROOT/generated/peregrine-selfhost"
MGEN="$ROOT/generated/original-selfhost"
HOLGEN="$ROOT/generated/hol4"
mkdir -p "$GEN" "$PGEN" "$MGEN" "$HOLGEN"

HOL4_DIR="${HOL4_DIR:-$ROOT/.aegis/references/hol4}"
CAKEML_DIR="${CAKEML_DIR:-$ROOT/.aegis/references/cakeml}"
METAROCQ_DIR="${METAROCQ_DIR:-$ROOT/.aegis/references/metarocq}"
PEREGRINE_DIR="${PEREGRINE_DIR:-$ROOT/.aegis/references/peregrine}"
CAKEML_BACKEND_DIR="${CAKEML_BACKEND_DIR:-$ROOT/.aegis/references/cakeml-backend}"
REGRESSION_DIR="${REGRESSION_DIR:-$ROOT/.aegis/references/cakeml-regression}"
export HOL4_DIR CAKEML_DIR METAROCQ_DIR PEREGRINE_DIR CAKEML_BACKEND_DIR

fail_missing() {
  local path="$1" obligation="$2"
  if [[ ! -s "$path" ]]; then
    printf 'BLOCKED: missing %s\nRequired obligation: %s\n' "$path" "$obligation" >&2
    exit 70
  fi
}

require_clean_tracked() {
  local repo="$1" label="$2"
  local dirty
  dirty="$(git -C "$repo" status --porcelain --untracked-files=no)"
  if [[ -n "$dirty" ]]; then
    printf 'tracked checkout is dirty: %s\n%s\n' "$label" "$dirty" >&2
    exit 72
  fi
}

activate_opam() {
  export OPAMROOT="${OPAMROOT:-$ROOT/.aegis/opam-root}"
  local switch="$ROOT/.aegis/opam"
  if [[ -x "$switch/_opam/bin/rocq" ]]; then
    eval "$(opam env --switch "$switch" --set-switch)"
  fi
}

ensure_producer() {
  activate_opam
  if command -v rocq >/dev/null 2>&1 && command -v peregrine >/dev/null 2>&1; then
    echo 'producer-source=prebuilt-or-restored' | tee "$GEN/producer-selection.txt"
    return 0
  fi
  echo 'producer-source=exact-pin-rebuild-fallback' | tee "$GEN/producer-selection.txt"
  bash tools/install_extraction.sh
  activate_opam
  command -v rocq
  command -v peregrine
}

ensure_hol4() {
  if [[ -x "$HOL4_DIR/bin/Holmake" ]]; then
    echo 'HOL4 already built; reusing exact pinned checkout'
    return 0
  fi
  (cd "$HOL4_DIR" && poly --script tools/smart-configure.sml && bin/build)
}

compile_peregrine_selfhost_to_ast() {
  ensure_producer
  local q0=(-Q metatheory/original-selfhost MetaRocqRs.OriginalSelfHost)
  rocq compile "${q0[@]}" metatheory/original-selfhost/PCUICModuleManifest.v
  rocq compile "${q0[@]}" metatheory/original-selfhost/SelfSnapshot.v
  local q=(
    -Q metatheory/original-selfhost MetaRocqRs.OriginalSelfHost
    -Q metatheory/peregrine-selfhost MetaRocqRs.PeregrineSelfHost
  )
  local f
  for f in \
    PeregrineSourceManifest.v PeregrineLoadAll.v PeregrineSnapshot.v \
    MaterializePeregrineSnapshot.v PeregrineProofCorpus.v \
    PeregrineSelfHostEntrypoint.v ExtractPeregrineSelfHost.v
  do
    rocq compile "${q[@]}" "metatheory/peregrine-selfhost/$f"
  done
  test -s "$PGEN/peregrine-selfhost.ast"
}

compile_original_runtime_once() {
  local marker="$GEN/original-runtime.complete"
  [[ -f "$marker" ]] && return 0
  ensure_producer
  local q=(-Q metatheory/original-selfhost MetaRocqRs.OriginalSelfHost)
  local files=(
    PipelineIR.v OpenTheoryIR.v PCUICModuleManifest.v SelfSnapshot.v
    MaterializeSnapshot.v HOLProofIR.v OpenTheorySerialize.v RuntimeImage.v
    RetainedPayload.v SelfHostRunner.v ExtractionRoot.v HOL4ReuseManifest.v
    CandleMachineChain.v CandlePrefixManifest.v PCUICCertificateIR.v
    PCUICDeepEmbeddingSchema.v SafeCheckerContract.v CertificateReplayIR.v
    HOL4RoundTripIR.v CandleExportContract.v DeepEmbeddingStatus.v
    DualProofLedger.v SelfCICD.v SelfCICDInterpreter.v SingleImageContract.v
    SingleImageEntrypoint.v EmbeddedPeregrine.v MetaRocqSuffixSafety.v
    CandlePrefixComposition.v CakeMLBackendTrustLedger.v
    CandidateCakeMLCompiler.v CakeMLTranslationCertificate.v
    ValidatedCakeMLGateway.v RecursiveSelfIdentity.v SharedImageEntrypoint.v
    ValidatedSharedImageEntrypoint.v EAstSupportedFragment.v CakeMLNoRaise.v
    CheckedCandidateCakeML.v CheckedSharedImageEntrypoint.v
    ReflectiveDualRecursion.v ReconciledSelfHostEntrypoint.v
    HOL4KernelContract.v SourceLambdaBoxRefinement.v
    IntegratedPeregrineCakeML.v HOL4MachineRefinement.v HOL4ProofLedger.v
    HOL4CertificateReplayIR.v HOL4RecursiveSelfIdentity.v
    HOL4SelfHostEntrypoint.v ExtractHOL4SelfHost.v
  )
  local f
  for f in "${files[@]}"; do
    rocq compile "${q[@]}" "metatheory/original-selfhost/$f"
  done
  test -s "$MGEN/hol4-selfhost.ast"
  sha256sum "$MGEN/hol4-selfhost.ast" > "$GEN/metarocq-lambdabox.sha256"
  : > "$marker"
}

case "$STAGE" in
  01)
    # Freeze the exact uploaded manual and the stronger unified target.
    sha256sum -c spec/unified-e2e-instruction-sha256.txt
    git rev-parse HEAD | tee "$GEN/repository-head.txt"
    git status --porcelain --untracked-files=no | tee "$GEN/tracked-status.txt"
    test ! -s "$GEN/tracked-status.txt"
    python3 -m json.tool spec/peregrine-selfhost-e2e.json >/dev/null
    python3 -m json.tool spec/hol4-selfhost-e2e.json >/dev/null
    python3 -m json.tool spec/unified-e2e-pipeline.json >/dev/null
    grep -q 'FAIL_CLOSED' spec/unified-e2e-pipeline.json
    ;;
  02)
    # Clone/pin/audit is materialized by exact Actions checkouts before the plan;
    # this stage independently verifies every resulting identity and trust escape.
    python3 tools/check_peregrine_selfhost_contract.py
    test "$(git -C "$METAROCQ_DIR" rev-parse HEAD)" = "7197056adbb9c15288b4c8d43407bf25786f723e"
    test "$(git -C "$PEREGRINE_DIR" rev-parse HEAD)" = "d768b83ffa7dab35b8d72241f0570b5bb6aedae9"
    test "$(git -C "$CAKEML_BACKEND_DIR" rev-parse HEAD)" = "cc20d1a2986bd2fec7c6eb0864c8c9a806188b58"
    test "$(git -C "$CAKEML_DIR" rev-parse HEAD)" = "c98da7fc904c5d6d0e9a75a18fac1796a9bfb1f9"
    test "$(git -C "$HOL4_DIR" rev-parse HEAD)" = "40dd5b03de658f4bd9e3f4225fb0f1602ac90467"
    test "$(git -C "$REGRESSION_DIR" rev-parse HEAD)" = "23cfeba74d0cef77f7274ab41a2e8e87d4032995"
    require_clean_tracked "$PEREGRINE_DIR" Peregrine
    require_clean_tracked "$CAKEML_BACKEND_DIR" Peregrine-CakeML-backend
    git -C "$PEREGRINE_DIR" submodule status --recursive | tee "$GEN/peregrine-submodules.txt"
    grep -nE 'trust_coq_kernel|Admitted\.' "$PEREGRINE_DIR/theories/backends/CakeMLBackend.v" \
      > "$GEN/peregrine-known-trust-escapes.txt"
    grep -nE 'assume_can_be_extracted|Admitted\.' "$CAKEML_BACKEND_DIR/theories/Backend/Pipeline.v" \
      > "$GEN/cakeml-backend-known-trust-escapes.txt"
    ;;
  03)
    # Build/audit the self-reflective root and complete retained proof/replay state
    # before invoking an independent producer seed.
    test "$(grep -c '\.v"' metatheory/peregrine-selfhost/PeregrineSourceManifest.v)" -ge 50
    grep -q 'Peregrine.Pipeline.peregrine_pipeline' metatheory/peregrine-selfhost/PeregrineSelfHostEntrypoint.v
    grep -q 'retained_peregrine_proof_corpus' metatheory/peregrine-selfhost/PeregrineSelfHostEntrypoint.v
    grep -q 'retained_peregrine_assumption_ledger' metatheory/peregrine-selfhost/PeregrineSelfHostEntrypoint.v
    grep -q 'retained_peregrine_replay_jobs' metatheory/peregrine-selfhost/PeregrineSelfHostEntrypoint.v
    grep -q 'peregrine-selfhost.ast' metatheory/peregrine-selfhost/ExtractPeregrineSelfHost.v
    ;;
  04)
    # Select independent seed by priority, execute the exact reflective extraction,
    # and bind seed identity to the resulting LambdaBox artifact.
    ensure_producer
    rocq -v | tee "$PGEN/rocq-version.txt"
    peregrine --help > "$PGEN/peregrine-help.txt"
    opam list --installed --switch "$ROOT/.aegis/opam" 2>/dev/null | \
      grep -E 'rocq-(metarocq|peregrine)' > "$PGEN/producer-packages.txt" || true
    compile_peregrine_selfhost_to_ast
    sha256sum "$PGEN/peregrine-selfhost.ast" > "$PGEN/peregrine-selfhost.ast.sha256"
    {
      echo "producer=$(command -v rocq)"
      echo "peregrine=$(command -v peregrine)"
      cat "$GEN/producer-selection.txt"
      cat "$PGEN/peregrine-selfhost.ast.sha256"
    } > "$PGEN/bootstrap-seed-binding.txt"
    ;;
  05)
    # Use the prebuilt Peregrine executable to produce exactly one CakeML candidate.
    ensure_producer
    sha256sum -c "$PGEN/peregrine-selfhost.ast.sha256"
    peregrine cakeml "$PGEN/peregrine-selfhost.ast" -o "$PGEN/peregrine-selfhost.cakeml"
    test -s "$PGEN/peregrine-selfhost.cakeml"
    sha256sum "$PGEN/peregrine-selfhost.cakeml" > "$PGEN/peregrine-selfhost.cakeml.sha256"
    printf '%s\n' 'candidate-only: semantic publication requires Step 06 theorem' > "$PGEN/candidate-boundary.txt"
    ;;
  06)
    # The base branch deliberately does not contain this missing formal proof.
    # Do not turn native process success into a substitute.
    fail_missing metatheory/peregrine-selfhost/PeregrineCakeMLPipelineCorrect.v \
      'complete LambdaBox -> CakeML refinement theorem instantiating the verified backend without trust_coq_kernel, Admitted, or assume_can_be_extracted'
    fail_missing metatheory/peregrine-selfhost/PeregrineCakeMLTranslationCertificate.v \
      'exact candidate/logic-level CakeML serialization and version binding certificate'
    ensure_producer
    local_q=(-Q metatheory/peregrine-selfhost MetaRocqRs.PeregrineSelfHost)
    rocq compile "${local_q[@]}" metatheory/peregrine-selfhost/PeregrineCakeMLPipelineCorrect.v
    rocq compile "${local_q[@]}" metatheory/peregrine-selfhost/PeregrineCakeMLTranslationCertificate.v
    grep -RInE 'Admitted\.|Axiom trust_coq_kernel|assume_can_be_extracted' \
      metatheory/peregrine-selfhost/PeregrineCakeMLPipelineCorrect.v \
      metatheory/peregrine-selfhost/PeregrineCakeMLTranslationCertificate.v \
      > "$GEN/peregrine-bridge-forbidden-shortcuts.txt" || true
    test ! -s "$GEN/peregrine-bridge-forbidden-shortcuts.txt"
    sha256sum metatheory/peregrine-selfhost/PeregrineCakeMLPipelineCorrect.vo \
      metatheory/peregrine-selfhost/PeregrineCakeMLTranslationCertificate.vo \
      > "$GEN/verified-peregrine-bridge.sha256"
    ;;
  07)
    # Exact CakeML AST -> theorem-producing x64 compilation inside HOL4.
    fail_missing "$GEN/verified-peregrine-bridge.sha256" 'Step 06 verified bridge identity'
    ensure_hol4
    cp formal/hol4/PeregrineGeneratedCompileScript.sml "$CAKEML_DIR/examples/compilation/x64/"
    export PEREGRINE_CAKEML_SEXP="$PGEN/peregrine-selfhost.cakeml"
    export PEREGRINE_MACHINE_ASM="$PGEN/peregrine-selfhost.S"
    (cd "$CAKEML_DIR/examples/compilation/x64" && "$HOL4_DIR/bin/Holmake" PeregrineGeneratedCompileTheory)
    test -s "$PGEN/peregrine-selfhost.S"
    sha256sum "$PGEN/peregrine-selfhost.S" > "$PGEN/peregrine-selfhost.S.sha256"
    cp "$CAKEML_DIR/examples/compilation/x64/PeregrineGeneratedCompileTheory.dat" "$HOLGEN/"
    ;;
  08)
    fail_missing formal/hol4/PeregrineProofCapsuleScript.sml \
      'theorem-bound non-circular Level-1 embedded replay/provenance capsule plus Level-2 outer exact-machine attestation'
    ensure_hol4
    mkdir -p "$HOLGEN/peregrine-capsule"
    cp formal/hol4/PeregrineProofCapsuleScript.sml "$HOLGEN/peregrine-capsule/"
    (cd "$HOLGEN/peregrine-capsule" && "$HOL4_DIR/bin/Holmake")
    ;;
  09)
    fail_missing formal/hol4/PeregrineIndependentReplayScript.sml \
      'fresh isolated HOL4 reconstruction from embedded capsule and exact machine identity'
    ensure_hol4
    rm -rf "$GEN/fresh-hol4-replay"
    mkdir -p "$GEN/fresh-hol4-replay"
    cp formal/hol4/PeregrineIndependentReplayScript.sml "$GEN/fresh-hol4-replay/"
    (cd "$GEN/fresh-hol4-replay" && "$HOL4_DIR/bin/Holmake")
    ;;
  10)
    fail_missing formal/hol4/PeregrineSelfHostE2EScript.sml \
      'exact Peregrine source/proof corpus -> machine theorem and one-command publication gate'
    ensure_hol4
    mkdir -p "$HOLGEN/peregrine-e2e"
    cp formal/hol4/PeregrineSelfHostE2EScript.sml "$HOLGEN/peregrine-e2e/"
    (cd "$HOLGEN/peregrine-e2e" && "$HOL4_DIR/bin/Holmake")
    ;;
  11)
    # Freeze MetaRocq Part-II trust base and fail-closed theorem criteria.
    python3 tools/check_hol4_selfhost_contract.py
    grep -q 'FAIL_CLOSED' spec/hol4-selfhost-e2e.json
    grep -q 'required_e2e_obligations' spec/hol4-selfhost-e2e.json
    ;;
  12)
    # Reproduce and record the pinned toolchain.  CI runner OS is recorded rather
    # than falsely claiming it is the user's CachyOS laptop.
    cat /etc/os-release | tee "$GEN/host-os-release.txt"
    test "$(git -C "$HOL4_DIR" rev-parse HEAD)" = "40dd5b03de658f4bd9e3f4225fb0f1602ac90467"
    test "$(git -C "$CAKEML_DIR" rev-parse HEAD)" = "c98da7fc904c5d6d0e9a75a18fac1796a9bfb1f9"
    test "$(git -C "$PEREGRINE_DIR" rev-parse HEAD)" = "d768b83ffa7dab35b8d72241f0570b5bb6aedae9"
    test "$(git -C "$CAKEML_BACKEND_DIR" rev-parse HEAD)" = "cc20d1a2986bd2fec7c6eb0864c8c9a806188b58"
    ensure_producer
    ensure_hol4
    rocq -v | tee "$GEN/metarocq-rocq-version.txt"
    peregrine --help > "$GEN/metarocq-peregrine-help.txt"
    ;;
  13)
    compile_original_runtime_once
    test -s "$MGEN/hol4-selfhost.ast"
    grep -q 'PCUIC' metatheory/original-selfhost/PCUICModuleManifest.v
    ;;
  14)
    compile_original_runtime_once
    grep -q 'hol4_selfhost_entrypoint' metatheory/original-selfhost/HOL4SelfHostEntrypoint.v
    grep -q 'accept_original_hol4_certificate_corpus' metatheory/original-selfhost/HOL4SelfHostEntrypoint.v
    grep -q 'accept_hol4_recursive_identity' metatheory/original-selfhost/HOL4SelfHostEntrypoint.v
    ;;
  15)
    compile_original_runtime_once
    python3 tools/check_hol4_selfhost_contract.py
    grep -RInE '(^|[^A-Za-z])(Admitted\.|Axiom trust_coq_kernel|assume_can_be_extracted)' \
      metatheory/original-selfhost/HOL4*.v > "$GEN/metarocq-forbidden-proof-shortcuts.txt" || true
    test ! -s "$GEN/metarocq-forbidden-proof-shortcuts.txt"
    ;;
  16)
    fail_missing "$GEN/verified-peregrine-bridge.sha256" \
      'the exact theorem identity produced by Peregrine Step 06'
    cp "$GEN/verified-peregrine-bridge.sha256" "$GEN/metarocq-consumed-peregrine-bridge.sha256"
    cmp "$GEN/verified-peregrine-bridge.sha256" "$GEN/metarocq-consumed-peregrine-bridge.sha256"
    ;;
  17)
    ensure_hol4
    mkdir -p "$HOLGEN/metarocq-kernel"
    cp formal/hol4/MetaRocqSelfHostKernelScript.sml "$HOLGEN/metarocq-kernel/"
    (cd "$HOLGEN/metarocq-kernel" && "$HOL4_DIR/bin/Holmake")
    fail_missing formal/hol4/MetaRocqProofReplayScript.sml \
      'complete retained PCUIC proof-corpus replay theorem produced by HOL4 evaluation, not an oracle'
    mkdir -p "$HOLGEN/metarocq-replay"
    cp formal/hol4/MetaRocqProofReplayScript.sml "$HOLGEN/metarocq-replay/"
    (cd "$HOLGEN/metarocq-replay" && "$HOL4_DIR/bin/Holmake")
    ;;
  18)
    fail_missing formal/hol4/MetaRocqGeneratedCompileScript.sml \
      'exact theorem-producing eval_cake_compile_x64 over the same Step-16 theorem-bound CakeML AST'
    ensure_hol4
    mkdir -p "$HOLGEN/metarocq-compile"
    cp formal/hol4/MetaRocqGeneratedCompileScript.sml "$HOLGEN/metarocq-compile/"
    (cd "$HOLGEN/metarocq-compile" && "$HOL4_DIR/bin/Holmake")
    ;;
  19)
    fail_missing formal/hol4/MetaRocqSelfHostE2EScript.sml \
      'one composed source/specification/proof-corpus -> exact machine refinement theorem'
    ensure_hol4
    mkdir -p "$HOLGEN/metarocq-e2e"
    cp formal/hol4/MetaRocqSelfHostE2EScript.sml "$HOLGEN/metarocq-e2e/"
    (cd "$HOLGEN/metarocq-e2e" && "$HOL4_DIR/bin/Holmake")
    ;;
  20)
    fail_missing "$MGEN/metarocq-selfhost.cake" \
      'exact theorem-bound final machine executable exposing deterministic recursive self replay'
    sha256sum "$MGEN/metarocq-selfhost.cake" > "$GEN/metarocq-selfhost.cake.sha256"
    "$MGEN/metarocq-selfhost.cake" --replay-self > "$GEN/metarocq-runtime-replay.txt"
    test -s "$GEN/metarocq-runtime-replay.txt"
    ;;
  21)
    test -n "${O11Y_RUN_DIR:-}"
    test -d "$O11Y_RUN_DIR"
    find "$O11Y_RUN_DIR" -maxdepth 3 -type f -print | sort > "$GEN/o11y-file-index.txt"
    test -s "$GEN/o11y-file-index.txt"
    test -s "$O11Y_RUN_DIR/pipeline.tsv"
    ;;
  22)
    fail_missing formal/hol4/PeregrineSelfHostE2EScript.sml 'Part-I theorem must remain valid'
    fail_missing formal/hol4/MetaRocqSelfHostE2EScript.sml 'final unified source-to-machine theorem'
    test -s "$GEN/metarocq-consumed-peregrine-bridge.sha256"
    test -n "${O11Y_RUN_DIR:-}"
    find "$O11Y_RUN_DIR" -name status.txt -exec grep -H . {} + | tee "$GEN/final-stage-statuses.txt"
    if grep -RInE 'Admitted\.|Axiom trust_coq_kernel|assume_can_be_extracted' \
      formal/hol4 metatheory/peregrine-selfhost metatheory/original-selfhost; then
      echo 'forbidden proof shortcut found in final evidence scope' >&2
      exit 71
    fi
    ;;
  23)
    # Always-run organizational/provenance report.  Missing formal obligations are
    # reported, never promoted to success.
    sha256sum -c spec/unified-e2e-instruction-sha256.txt
    {
      echo 'UNIFIED_INSTRUCTION_SEQUENCE = COMPLETE'
      echo 'FORMAL_IMPLEMENTATION = FAIL_CLOSED UNTIL ALL REQUIRED THEOREMS EXIST'
      echo
      echo 'base implementation reused: experiment/peregrine-selfhost-cakeml-hol4-e2e'
      echo 'source instruction stacks expected:'
      echo '  docs/peregrine-selfhost-03-independent-replay'
      echo '  docs/selfhost-bootstrap-04-runtime-audit'
      echo
      echo 'open formal artifacts:'
      for p in \
        metatheory/peregrine-selfhost/PeregrineCakeMLPipelineCorrect.v \
        metatheory/peregrine-selfhost/PeregrineCakeMLTranslationCertificate.v \
        formal/hol4/PeregrineProofCapsuleScript.sml \
        formal/hol4/PeregrineIndependentReplayScript.sml \
        formal/hol4/PeregrineSelfHostE2EScript.sml \
        formal/hol4/MetaRocqProofReplayScript.sml \
        formal/hol4/MetaRocqGeneratedCompileScript.sml \
        formal/hol4/MetaRocqSelfHostE2EScript.sml \
        generated/original-selfhost/metarocq-selfhost.cake
      do
        if [[ -s "$p" ]]; then echo "  [present] $p"; else echo "  [missing] $p"; fi
      done
      echo
      echo 'instruction hashes:'
      cat spec/unified-e2e-instruction-sha256.txt
    } | tee "$GEN/unified-provenance-and-open-obligations.txt"
    git ls-remote --exit-code origin refs/heads/docs/peregrine-selfhost-03-independent-replay \
      > "$GEN/source-peregrine-doc-branch.txt"
    git ls-remote --exit-code origin refs/heads/docs/selfhost-bootstrap-04-runtime-audit \
      > "$GEN/source-metarocq-doc-branch.txt"
    ;;
  *)
    echo "unknown stage: $STAGE" >&2
    exit 64
    ;;
esac
