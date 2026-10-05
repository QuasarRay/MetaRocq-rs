From Stdlib Require Import String List Bool Arith.
From MetaRocqRs.OriginalSelfHost Require Import
  SelfHostCI CakeMLImageIR SingleImageContract.

Open Scope string_scope.

Record ci_evidence := {
  ci_sources_pinned : bool;
  ci_pcuic_quoted : bool;
  ci_hol_derivations_proved : bool;
  ci_opentheory_serialized : bool;
  ci_candle_replay_proved : bool;
  ci_lambdabox_extracted : bool;
  ci_residual_safety_proved : bool;
  ci_residual_semantics_proved : bool;
  ci_image_composed : bool;
  ci_verified_compile_proved : bool;
  ci_machine_identity_bound : bool;
  ci_recursive_replay_proved : bool
}.

Record ci_state := {
  current_stage : ci_stage;
  accepted : bool;
  block_reason : option string
}.

Definition blocked (reason : string) : ci_state :=
  {| current_stage := CIBlocked;
     accepted := false;
     block_reason := Some reason |}.

Definition running (stage : ci_stage) : ci_state :=
  {| current_stage := stage;
     accepted := false;
     block_reason := None |}.

Definition accepted_state : ci_state :=
  {| current_stage := CIAccept;
     accepted := true;
     block_reason := None |}.

Definition evaluate_ci (e : ci_evidence) : ci_state :=
  if negb ci_program_structure_ok then
    blocked "MetaRocq CI program structure is inconsistent"
  else if negb e.(ci_sources_pinned) then running CIPinSources
  else if negb e.(ci_pcuic_quoted) then running CIQuotePCUIC
  else if negb e.(ci_hol_derivations_proved) then running CILowerHOL
  else if negb e.(ci_opentheory_serialized) then running CISerializeOpenTheory
  else if negb e.(ci_candle_replay_proved) then running CICandleReplay
  else if negb e.(ci_lambdabox_extracted) then running CIPeregrineExtract
  else if negb e.(ci_residual_safety_proved) then running CIProveResidualSafety
  else if negb e.(ci_residual_semantics_proved) then running CIProveResidualSafety
  else if negb e.(ci_image_composed) then running CIComposeCakeMLImage
  else if negb e.(ci_verified_compile_proved) then running CIVerifiedCakeMLCompile
  else if negb e.(ci_machine_identity_bound) then running CIBindMachineIdentity
  else if negb e.(ci_recursive_replay_proved) then running CIReplaySelf
  else accepted_state.

Definition empty_ci_evidence : ci_evidence :=
  {| ci_sources_pinned := false;
     ci_pcuic_quoted := false;
     ci_hol_derivations_proved := false;
     ci_opentheory_serialized := false;
     ci_candle_replay_proved := false;
     ci_lambdabox_extracted := false;
     ci_residual_safety_proved := false;
     ci_residual_semantics_proved := false;
     ci_image_composed := false;
     ci_verified_compile_proved := false;
     ci_machine_identity_bound := false;
     ci_recursive_replay_proved := false |}.

Theorem empty_ci_starts_at_source_pinning :
  current_stage (evaluate_ci empty_ci_evidence) = CIPinSources.
Proof. reflexivity. Qed.

Theorem acceptance_requires_hol_derivations :
  forall src quote art candle lb safe sem img comp ident replay,
    accepted
      (evaluate_ci
        {| ci_sources_pinned := src;
           ci_pcuic_quoted := quote;
           ci_hol_derivations_proved := false;
           ci_opentheory_serialized := art;
           ci_candle_replay_proved := candle;
           ci_lambdabox_extracted := lb;
           ci_residual_safety_proved := safe;
           ci_residual_semantics_proved := sem;
           ci_image_composed := img;
           ci_verified_compile_proved := comp;
           ci_machine_identity_bound := ident;
           ci_recursive_replay_proved := replay |}) = false.
Proof.
  intros; destruct src, quote; reflexivity.
Qed.

Theorem acceptance_requires_recursive_replay :
  forall src quote hol art candle lb safe sem img comp ident,
    accepted
      (evaluate_ci
        {| ci_sources_pinned := src;
           ci_pcuic_quoted := quote;
           ci_hol_derivations_proved := hol;
           ci_opentheory_serialized := art;
           ci_candle_replay_proved := candle;
           ci_lambdabox_extracted := lb;
           ci_residual_safety_proved := safe;
           ci_residual_semantics_proved := sem;
           ci_image_composed := img;
           ci_verified_compile_proved := comp;
           ci_machine_identity_bound := ident;
           ci_recursive_replay_proved := false |}) = false.
Proof.
  intros.
  destruct src, quote, hol, art, candle, lb, safe, sem, img, comp, ident;
    reflexivity.
Qed.
