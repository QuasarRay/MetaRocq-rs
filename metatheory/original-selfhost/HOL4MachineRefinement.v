From Stdlib Require Import String List Bool.
From MetaRocqRs.OriginalSelfHost Require Import
  HOL4KernelContract SourceLambdaBoxRefinement IntegratedPeregrineCakeML.

Import ListNotations.
Open Scope string_scope.

Record cakeml_hol4_binding := {
  binding_file : string;
  binding_blob_sha : string;
  binding_symbol : string;
  binding_role : string
}.

Definition pinned_cakeml_revision : string :=
  "c98da7fc904c5d6d0e9a75a18fac1796a9bfb1f9".

Definition cakeml_hol4_bindings : list cakeml_hol4_binding :=
  [ {| binding_file := "cv_translator/eval_cake_compile_x64Lib.sml";
       binding_blob_sha := "71f472af47a1a46d58d3ac6935d062e1f3d70c70";
       binding_symbol := "eval_cake_compile_x64";
       binding_role :=
         "in-logic x64 compilation evaluator that produces a HOL theorem for the exact program definition" |};
    {| binding_file := "compiler/backend/proofs/backendProofScript.sml";
       binding_blob_sha := "32cc296f38650a98ddb633c6bb834263019becb2";
       binding_symbol := "compile_correct";
       binding_role :=
         "generic verified backend theorem relating source semantics to generated target bytes" |};
    {| binding_file := "compiler/backend/x64/proofs/x64_configProofScript.sml";
       binding_blob_sha := "c82ce0d7913e4f19f3d45c28579b8e32627ec653";
       binding_symbol := "x64_compile_correct";
       binding_role :=
         "x64 specialization of compiler correctness and machine configuration obligations" |};
    {| binding_file := "examples/compilation/x64/proofs/helloProofScript.sml";
       binding_blob_sha := "8c5104adeb6342d31d33b3f4123be58595e175a9";
       binding_symbol := "hello_compiled_thm";
       binding_role :=
         "reference composition pattern for a concrete program-level end-to-end theorem" |}
  ].

Definition cakeml_binding_count_ok : bool :=
  Nat.eqb (List.length cakeml_hol4_bindings) 4.

Record hol4_machine_refinement_evidence := {
  refinement_source_lambdabox : source_lambdabox_evidence;
  refinement_peregrine : integrated_peregrine_evidence;
  refinement_hol4_kernel : hol4_kernel_evidence;
  refinement_cakeml_program_digest : string;
  refinement_machine_image_digest : string;
  refinement_exact_program_definition_bound : bool;
  refinement_in_logic_compile_theorem_generated : bool;
  refinement_source_semantics_theorem_bound : bool;
  refinement_compile_correct_instantiated : bool;
  refinement_x64_machine_obligations_discharged : bool;
  refinement_concrete_bytes_bound : bool;
  refinement_installed_image_bound : bool;
  refinement_hol4_check_thm_passed : bool
}.

Definition nonempty_digest (s : string) : bool :=
  negb (String.eqb s EmptyString).

Definition hol4_machine_refinement_complete
  (e : hol4_machine_refinement_evidence) : bool :=
  source_lambdabox_evidence_complete e.(refinement_source_lambdabox)
  && integrated_peregrine_evidence_complete e.(refinement_peregrine)
  && hol4_kernel_evidence_complete e.(refinement_hol4_kernel)
  && nonempty_digest e.(refinement_cakeml_program_digest)
  && nonempty_digest e.(refinement_machine_image_digest)
  && e.(refinement_exact_program_definition_bound)
  && e.(refinement_in_logic_compile_theorem_generated)
  && e.(refinement_source_semantics_theorem_bound)
  && e.(refinement_compile_correct_instantiated)
  && e.(refinement_x64_machine_obligations_discharged)
  && e.(refinement_concrete_bytes_bound)
  && e.(refinement_installed_image_bound)
  && e.(refinement_hol4_check_thm_passed).

Definition unresolved_hol4_machine_refinement : hol4_machine_refinement_evidence :=
  {| refinement_source_lambdabox := unresolved_source_lambdabox_evidence;
     refinement_peregrine :=
       {| peregrine_revision_matches := true;
          cakeml_backend_revision_matches := true;
          checked_supported_fragment_used := true;
          generated_tree_has_no_raise := true;
          forbidden_backend_assumptions_unused := true |};
     refinement_hol4_kernel := unresolved_hol4_kernel_evidence;
     refinement_cakeml_program_digest := "";
     refinement_machine_image_digest := "";
     refinement_exact_program_definition_bound := false;
     refinement_in_logic_compile_theorem_generated := false;
     refinement_source_semantics_theorem_bound := false;
     refinement_compile_correct_instantiated := false;
     refinement_x64_machine_obligations_discharged := false;
     refinement_concrete_bytes_bound := false;
     refinement_installed_image_bound := false;
     refinement_hol4_check_thm_passed := false |}.

Definition hol4_machine_refinement_currently_publishable : bool :=
  hol4_machine_refinement_complete unresolved_hol4_machine_refinement.

Theorem machine_refinement_is_fail_closed :
  hol4_machine_refinement_currently_publishable = false.
Proof. reflexivity. Qed.
