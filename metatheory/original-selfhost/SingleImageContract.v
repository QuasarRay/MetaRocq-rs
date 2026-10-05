From Stdlib Require Import String List Bool Arith.
From MetaRocqRs.OriginalSelfHost Require Import
  RuntimeImage RetainedPayload VerifiedRuntimeAnchors RecursiveTrustGraph.

Import ListNotations.
Open Scope string_scope.

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

Record single_image_contract := {
  image_members : list image_member;
  image_theorem_anchors : list verified_theorem_anchor;
  image_requires_one_machine_image : bool;
  image_requires_retained_proof_data : bool;
  image_requires_non_circular_trust : bool;
  image_architecture : runtime_architecture
}.

Definition original_metarocq_single_image_contract : single_image_contract :=
  {| image_members := required_image_members;
     image_theorem_anchors := verified_runtime_anchors;
     image_requires_one_machine_image := true;
     image_requires_retained_proof_data := true;
     image_requires_non_circular_trust := trust_graph_well_founded;
     image_architecture := selfhost_runtime_architecture |}.

Definition single_image_contract_structurally_valid : bool :=
  Nat.eqb
    (List.length original_metarocq_single_image_contract.(image_members)) 5
  && verified_runtime_anchor_count_ok
  && original_metarocq_single_image_contract.(image_requires_one_machine_image)
  && original_metarocq_single_image_contract.(image_requires_retained_proof_data)
  && original_metarocq_single_image_contract.(image_requires_non_circular_trust)
  && runtime_architecture_well_formed.

Theorem single_image_contract_structure_is_valid :
  single_image_contract_structurally_valid = true.
Proof. reflexivity. Qed.

(* Semantic readiness remains false until the proof-producing PCUIC -> HOL
   lowering from the preceding stack is discharged. *)
Definition single_image_semantically_ready : bool :=
  single_image_contract_structurally_valid && proof_payload_publishable.
