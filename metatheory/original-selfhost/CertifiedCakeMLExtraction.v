From MetaRocq.Utils Require Import utils.
From MetaRocq.PCUIC Require Import
  PCUICAst PCUICTyping PCUICSN PCUICProgram PCUICEtaExpand.
From CakeML.Backend Require Import Pipeline Serialize.
From CeresBS Require Import CeresSerialize.

Import PCUICProgram.
Import PCUICAst.PCUICEnvironment.

Module CertifiedCakeMLExtraction.

(* Evidence that is specific to the exact quoted self-host program.  This
   replaces the generic [trust_coq_kernel] / "only erase well-typed programs"
   convenience assumptions in the Peregrine wrappers. *)
Record checked_pcuic_program (p : pcuic_program) := {
  checked_type : term;
  checked_wf : wf_ext p.1;
  checked_expanded_env : expanded_global_env p.1.1;
  checked_expanded_term : expanded p.1.1 [] p.2;
  checked_typing : ∥ p.1 ;;; [] |- p.2 : checked_type ∥
}.

Definition normalization_for_program :=
  forall Sigma : global_env_ext, wf_ext Sigma -> NormalizationIn Sigma.

Section Compile.

Context (p : pcuic_program).
Context (checked : checked_pcuic_program p).
Context (normalize : normalization_for_program).

(* [CakeML.Backend.Pipeline.compile_malfunction_pipeline] is the lower-level
   proof-carrying route.  Unlike Peregrine's convenience CakeML wrapper, its
   caller supplies the PCUIC well-formedness/typing/expansion evidence and the
   normalization assumption explicitly. *)
Definition certified_cakeml_ast :=
  @CakeML.Backend.Pipeline.compile_malfunction_pipeline
    p.1 p.2 checked.(checked_type)
    checked.(checked_wf)
    checked.(checked_expanded_env)
    checked.(checked_expanded_term)
    checked.(checked_typing)
    normalize.

Definition certified_cakeml_source : string :=
  @CeresSerialize.to_string _
    (CakeML.Backend.Serialize.Serialize_module [])
    certified_cakeml_ast.

End Compile.

End CertifiedCakeMLExtraction.
