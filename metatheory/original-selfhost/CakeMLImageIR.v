From Stdlib Require Import String List Bool Arith.
From MetaRocqRs.OriginalSelfHost Require Import
  VerifiedRuntimeAnchors SingleImageContract.

Import ListNotations.
Open Scope string_scope.

Inductive image_segment_kind :=
| CandleVerifiedPrefix
| CakeMLCompilerResidual
| MetaRocqSelfHostResidual
| RetainedProofPayloadSegment.

Record image_segment := {
  segment_kind : image_segment_kind;
  segment_name : string;
  segment_source_identity : string;
  segment_requires_safe_decs : bool
}.

Definition candle_prefix_segment : image_segment :=
  {| segment_kind := CandleVerifiedPrefix;
     segment_name := "candle_code";
     segment_source_identity :=
       "x64BootstrapProof.compiler64_prog_eq_candle_code_append";
     segment_requires_safe_decs := false |}.

Definition compiler_residual_segment : image_segment :=
  {| segment_kind := CakeMLCompilerResidual;
     segment_name := "compiler64 residual after candle_code";
     segment_source_identity :=
       "compiler64Prog.semantics_compiler64_prog";
     segment_requires_safe_decs := true |}.

Definition metarocq_residual_segment : image_segment :=
  {| segment_kind := MetaRocqSelfHostResidual;
     segment_name := "Peregrine-lowered MetaRocq selfhost entrypoint";
     segment_source_identity :=
       "MetaRocqRs.OriginalSelfHost.SingleImageExtractionRoot.single_image_entrypoint";
     segment_requires_safe_decs := true |}.

Definition retained_payload_segment : image_segment :=
  {| segment_kind := RetainedProofPayloadSegment;
     segment_name := "retained PCUIC/OpenTheory replay payload";
     segment_source_identity :=
       "MetaRocqRs.OriginalSelfHost.RetainedPayload.original_selfhost_payload";
     segment_requires_safe_decs := false |}.

Record image_composition_plan := {
  composition_segments : list image_segment;
  composition_uses_candle_prefix_theorem : bool;
  composition_uses_candle_top_level_soundness : bool;
  composition_requires_safe_residual : bool;
  composition_requires_exact_blob_identity : bool
}.

Definition single_image_composition_plan : image_composition_plan :=
  {| composition_segments :=
       [candle_prefix_segment;
        compiler_residual_segment;
        metarocq_residual_segment;
        retained_payload_segment];
     composition_uses_candle_prefix_theorem := true;
     composition_uses_candle_top_level_soundness := true;
     composition_requires_safe_residual := true;
     composition_requires_exact_blob_identity := true |}.

Definition image_composition_structure_ok : bool :=
  Nat.eqb (List.length single_image_composition_plan.(composition_segments)) 4
  && single_image_composition_plan.(composition_uses_candle_prefix_theorem)
  && single_image_composition_plan.(composition_uses_candle_top_level_soundness)
  && single_image_composition_plan.(composition_requires_safe_residual)
  && single_image_composition_plan.(composition_requires_exact_blob_identity).

Theorem image_composition_structure_is_ok :
  image_composition_structure_ok = true.
Proof. reflexivity. Qed.

(* The existing CakeML theorem proves safety of the compiler residual following
   [candle_code].  Extending that residual with MetaRocq requires a new safety
   and semantic-preservation theorem; this bit must not be set by packaging. *)
Record composition_evidence := {
  compiler_prefix_theorem_checked : bool;
  metarocq_residual_safe_decs_proved : bool;
  metarocq_residual_semantics_proved : bool;
  final_image_blob_identity_checked : bool
}.

Definition composition_evidence_acceptable (e : composition_evidence) : bool :=
  image_composition_structure_ok
  && e.(compiler_prefix_theorem_checked)
  && e.(metarocq_residual_safe_decs_proved)
  && e.(metarocq_residual_semantics_proved)
  && e.(final_image_blob_identity_checked).
