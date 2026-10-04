From Stdlib Require Import String List Bool.
From MetaRocqRs.OriginalSelfHost Require Import
  RuntimeImage RetainedPayload HOL4ReuseManifest DualProofLedger
  CandleMachineChain SelfCICD.

Import ListNotations.
Open Scope string_scope.

Record image_evidence := {
  image_contains_metaself : bool;
  image_contains_peregrine : bool;
  image_contains_candle : bool;
  image_contains_cakeml_compiler : bool;
  image_contains_retained_pcuic : bool;
  image_contains_retained_opentheory : bool;
  image_cicd_interpreted_in_self : bool;
  image_identity_replay_proved : bool
}.

Record single_image_contract := {
  image_name : string;
  image_runtime_architecture : runtime_architecture;
  image_reused_hol4 : list reuse_asset;
  image_ci_plan : list ci_job;
  image_proof_chain : list chain_obligation;
  image_dual_claims : list semantic_claim
}.

Definition original_metarocq_single_image : single_image_contract :=
  {| image_name := "original-metarocq-self-reflective-candle";
     image_runtime_architecture := selfhost_runtime_architecture;
     image_reused_hol4 := inherited_hol4_assets;
     image_ci_plan := self_ci_pipeline;
     image_proof_chain := candle_machine_chain;
     image_dual_claims := selfhost_claims |}.

Definition structural_single_image_ready : bool :=
  runtime_architecture_well_formed
  && reuse_manifest_well_formed
  && self_ci_structure_closed.

Definition accept_single_image
  (i : image_evidence)
  (dual : list dual_evidence) : bool :=
  structural_single_image_ready
  && proof_payload_publishable
  && machine_chain_closed
  && all_dual_claims_accepted selfhost_claims dual
  && i.(image_contains_metaself)
  && i.(image_contains_peregrine)
  && i.(image_contains_candle)
  && i.(image_contains_cakeml_compiler)
  && i.(image_contains_retained_pcuic)
  && i.(image_contains_retained_opentheory)
  && i.(image_cicd_interpreted_in_self)
  && i.(image_identity_replay_proved).

Definition empty_image_evidence : image_evidence :=
  {| image_contains_metaself := false;
     image_contains_peregrine := false;
     image_contains_candle := false;
     image_contains_cakeml_compiler := false;
     image_contains_retained_pcuic := true;
     image_contains_retained_opentheory := false;
     image_cicd_interpreted_in_self := false;
     image_identity_replay_proved := false |}.
