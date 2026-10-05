From Stdlib Require Import String List Bool Arith.
From MetaRocqRs.OriginalSelfHost Require Import
  RuntimeImage RetainedPayload VerifiedRuntimeAnchors RecursiveTrustGraph
  HOL4ReuseManifest DualProofLedger CandleMachineChain SelfCICD.

Import ListNotations.
Open Scope string_scope.

(* Machine-chain contract retained from the single-image/Candle branch. *)
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

(* The theorem-anchor contract from the parallel single-image-contract branch is
   retained under a distinct name so both proof architectures remain usable. *)
Inductive image_member :=
| MetaRocqSelfHostMember
| PeregrineRegeneratorMember
| OpenTheoryReaderMember
| CandleKernelMember
| CakeMLCompilerReplMember.

Definition required_image_members : list image_member :=
  [MetaRocqSelfHostMember;
   PeregrineRegeneratorMember;
   OpenTheoryReaderMember;
   CandleKernelMember;
   CakeMLCompilerReplMember].

Record anchored_single_image_contract := {
  anchored_image_members : list image_member;
  anchored_image_theorem_anchors : list verified_theorem_anchor;
  anchored_image_requires_one_machine_image : bool;
  anchored_image_requires_retained_proof_data : bool;
  anchored_image_requires_non_circular_trust : bool;
  anchored_image_architecture : runtime_architecture
}.

Definition original_metarocq_anchored_single_image_contract
  : anchored_single_image_contract :=
  {| anchored_image_members := required_image_members;
     anchored_image_theorem_anchors := verified_runtime_anchors;
     anchored_image_requires_one_machine_image := true;
     anchored_image_requires_retained_proof_data := true;
     anchored_image_requires_non_circular_trust := trust_graph_well_founded;
     anchored_image_architecture := selfhost_runtime_architecture |}.

Definition single_image_contract_structurally_valid : bool :=
  Nat.eqb
    (List.length
       original_metarocq_anchored_single_image_contract.(anchored_image_members)) 5
  && verified_runtime_anchor_count_ok
  && original_metarocq_anchored_single_image_contract.(anchored_image_requires_one_machine_image)
  && original_metarocq_anchored_single_image_contract.(anchored_image_requires_retained_proof_data)
  && original_metarocq_anchored_single_image_contract.(anchored_image_requires_non_circular_trust)
  && runtime_architecture_well_formed.

Theorem single_image_contract_structure_is_valid :
  single_image_contract_structurally_valid = true.
Proof. reflexivity. Qed.

Definition single_image_semantically_ready : bool :=
  single_image_contract_structurally_valid && proof_payload_publishable.
