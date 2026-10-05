From Stdlib Require Import String List Bool.
From MetaRocq.Utils Require Import ResultMonad.
From MetaRocqRs.OriginalSelfHost Require Import
  CheckedCandidateCakeML CakeMLBackendTrustLedger.

Open Scope string_scope.

Definition pinned_peregrine_revision : string :=
  "d768b83ffa7dab35b8d72241f0570b5bb6aedae9".

Definition pinned_cakeml_backend_revision : string :=
  "cc20d1a2986bd2fec7c6eb0864c8c9a806188b58".

Definition pinned_peregrine_past_blob : string :=
  "45306f7c193eaa4e47cfe1b7b0f63e211de948b8".

Definition pinned_cakeml_compile_blob : string :=
  "b22338bc3113a972bcf793f79be7887bc59153e8".

Definition integrated_lambdabox_to_cakeml
  (attrs : list string) (source : string)
  : result' candidate_cakeml_ast :=
  prepare_and_checked_compile attrs source.

Record integrated_peregrine_evidence := {
  peregrine_revision_matches : bool;
  cakeml_backend_revision_matches : bool;
  checked_supported_fragment_used : bool;
  generated_tree_has_no_raise : bool;
  forbidden_backend_assumptions_unused : bool
}.

Definition integrated_peregrine_evidence_complete
  (e : integrated_peregrine_evidence) : bool :=
  e.(peregrine_revision_matches)
  && e.(cakeml_backend_revision_matches)
  && e.(checked_supported_fragment_used)
  && e.(generated_tree_has_no_raise)
  && e.(forbidden_backend_assumptions_unused).

Lemma integrated_lambdabox_to_cakeml_no_raise
  (attrs : list string) (source : string)
  (out : candidate_cakeml_ast) :
  integrated_lambdabox_to_cakeml attrs source = Ok out ->
  candidate_cakeml_no_raise out = true.
Proof.
  exact (prepare_and_checked_compile_no_raise attrs source out).
Qed.

Lemma integrated_lambdabox_to_cakeml_supported
  (attrs : list string) (source : string)
  (out : candidate_cakeml_ast) :
  integrated_lambdabox_to_cakeml attrs source = Ok out ->
  exists p ep,
    prepare_cakeml attrs source = Ok p
    /\ PAst_to_EAst p = Ok ep
    /\ east_program_supported ep = true
    /\ out = CakeML.Backend.Compile.compile_program ep.
Proof.
  exact (prepare_and_checked_compile_supported attrs source out).
Qed.
