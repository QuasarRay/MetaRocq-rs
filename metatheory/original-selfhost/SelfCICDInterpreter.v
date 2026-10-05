From Stdlib Require Import String List Bool.
From MetaRocqRs.OriginalSelfHost Require Import SelfCICD.

Open Scope string_scope.

Record self_ci_evidence := {
  ci_sources_pinned : bool;
  ci_pcuic_snapshot_materialized : bool;
  ci_opentheory_proof_bundle_produced : bool;
  ci_candle_bundle_accepted : bool;
  ci_lambdabox_extracted : bool;
  ci_checked_cakeml_source_produced : bool;
  ci_cakeml_semantics_and_compile_proved : bool;
  ci_machine_image_replayed : bool;
  ci_self_identity_matched : bool
}.

Inductive self_ci_state :=
| CIWaiting (a : ci_action)
| CIRejected (reason : string)
| CIAccepted.

Definition evaluate_self_ci (e : self_ci_evidence) : self_ci_state :=
  if negb self_ci_structure_closed then
    CIRejected "MetaRocq-owned CI pipeline structure is inconsistent"
  else if negb e.(ci_sources_pinned) then CIWaiting VerifyPinnedSources
  else if negb e.(ci_pcuic_snapshot_materialized) then
    CIWaiting MaterializePCUICSnapshot
  else if negb e.(ci_opentheory_proof_bundle_produced) then
    CIWaiting ProduceOpenTheory
  else if negb e.(ci_candle_bundle_accepted) then
    CIWaiting CheckOpenTheoryWithCandle
  else if negb e.(ci_lambdabox_extracted) then
    CIWaiting ExtractSelfToLambdaBox
  else if negb e.(ci_checked_cakeml_source_produced) then
    CIWaiting TranslateLambdaBoxWithPeregrine
  else if negb e.(ci_cakeml_semantics_and_compile_proved) then
    CIWaiting CompileWithCakeMLInLogic
  else if negb e.(ci_machine_image_replayed) then
    CIWaiting ReplayMachineImage
  else if negb e.(ci_self_identity_matched) then
    CIWaiting CompareSelfIdentity
  else CIAccepted.

Definition empty_self_ci_evidence : self_ci_evidence :=
  {| ci_sources_pinned := false;
     ci_pcuic_snapshot_materialized := false;
     ci_opentheory_proof_bundle_produced := false;
     ci_candle_bundle_accepted := false;
     ci_lambdabox_extracted := false;
     ci_checked_cakeml_source_produced := false;
     ci_cakeml_semantics_and_compile_proved := false;
     ci_machine_image_replayed := false;
     ci_self_identity_matched := false |}.

Theorem empty_self_ci_starts_at_source_pinning :
  evaluate_self_ci empty_self_ci_evidence = CIWaiting VerifyPinnedSources.
Proof. reflexivity. Qed.

Theorem missing_opentheory_blocks_ci :
  forall src snap candle lb cake sem replay identity,
    evaluate_self_ci
      {| ci_sources_pinned := src;
         ci_pcuic_snapshot_materialized := snap;
         ci_opentheory_proof_bundle_produced := false;
         ci_candle_bundle_accepted := candle;
         ci_lambdabox_extracted := lb;
         ci_checked_cakeml_source_produced := cake;
         ci_cakeml_semantics_and_compile_proved := sem;
         ci_machine_image_replayed := replay;
         ci_self_identity_matched := identity |} <> CIAccepted.
Proof.
  intros.
  unfold evaluate_self_ci.
  destruct self_ci_structure_closed, src, snap; discriminate.
Qed.

Theorem missing_machine_replay_blocks_ci :
  forall src snap ot candle lb cake sem identity,
    evaluate_self_ci
      {| ci_sources_pinned := src;
         ci_pcuic_snapshot_materialized := snap;
         ci_opentheory_proof_bundle_produced := ot;
         ci_candle_bundle_accepted := candle;
         ci_lambdabox_extracted := lb;
         ci_checked_cakeml_source_produced := cake;
         ci_cakeml_semantics_and_compile_proved := sem;
         ci_machine_image_replayed := false;
         ci_self_identity_matched := identity |} <> CIAccepted.
Proof.
  intros.
  unfold evaluate_self_ci.
  destruct self_ci_structure_closed, src, snap, ot, candle, lb, cake, sem;
    discriminate.
Qed.
