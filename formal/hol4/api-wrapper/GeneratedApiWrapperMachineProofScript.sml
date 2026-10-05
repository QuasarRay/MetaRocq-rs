(*
  Compose the generated wrapper service semantics theorem and CakeML's verified
  compiler theorem to reach exact x64 machine semantics.

  Trust boundary: api_request/api_bridge/api_reply remain explicit foreign
  oracle premises. This theory does not claim to verify Poly/ML, HOL4,
  TacticToe, Z3_TAC or Z3 internals.
*)
Theory GeneratedApiWrapperMachineProof
Ancestors
  GeneratedApiWrapperService GeneratedApiWrapperCompile
  semanticsProps backendProof x64_configProof
Libs
  preamble

(* Generic extraction used because cfMain.call_main_thm2 existentially returns
   the final CakeML state. A successful source execution rules out Fail. *)
Theorem exists_success_semantics_not_fail:
  (!?x. P x) \/
  ((?x.
      semantics_prog s env prog
        (Terminate Success (events x)) /\
      Q x) ==>
   ~semantics_prog s env prog Fail)
Proof
  Cases_on `?x. P x`
  \ simp []
  \ metis_tac [semantics_prog_Terminate_not_Fail]
QED

(* Simpler specialization with no irrelevant witness predicate. *)
Theorem success_witness_not_fail:
  (?x.
      semantics_prog s env prog
        (Terminate Success (events x)) /\
      Q x) ==>
  ~semantics_prog s env prog Fail
Proof
  metis_tac [semantics_prog_Terminate_not_Fail]
QED

(* Convert cfMain's semantics_dec_list theorem to the exact semantics_prog
   relation required by backendProof.compile_correct. The compiler evaluation
   theorem supplies prog_syntax_ok, exactly as in CakeML's helloProof. *)
val generated_api_service_semantics_prog =
  generated_api_service_semantics
  |> SRULE [generated_api_wrapper_compiled,
            ml_progTheory.prog_syntax_ok_semantics]
  |> check_thm;

val generated_api_service_semantics_prog_open =
  generated_api_service_semantics_prog
  |> SPEC_ALL
  |> UNDISCH_ALL;

val generated_api_wrapper_no_source_fail_open =
  MATCH_MP (GEN_ALL success_witness_not_fail)
           generated_api_service_semantics_prog_open
  |> check_thm;

val generated_api_wrapper_no_source_fail =
  generated_api_wrapper_no_source_fail_open
  |> DISCH_ALL
  |> check_thm;

val _ =
  save_thm ("generated_api_wrapper_no_source_fail",
            generated_api_wrapper_no_source_fail);

(* Standard CakeML x64 composition, following examples/compilation/x64/
   proofs/helloProofScript.sml. The installed-image and initial-machine-state
   assumptions intentionally remain theorem premises. *)
val generated_api_compile_correct_applied =
  MATCH_MP backendProofTheory.compile_correct
           (cj 1 generated_api_wrapper_compiled)
  |> SIMP_RULE (srw_ss())
       [LET_THM,ml_progTheory.init_state_env_thm,GSYM AND_IMP_INTRO]
  |> C MATCH_MP generated_api_wrapper_no_source_fail_open
  |> C MATCH_MP x64_backend_config_ok
  |> REWRITE_RULE [AND_IMP_INTRO]
  |> REWRITE_RULE [Once (GSYM AND_IMP_INTRO)]
  |> C MATCH_MP
       (CONJ (UNDISCH x64_machine_config_ok)
             (UNDISCH x64_init_ok))
  |> DISCH (#1 (dest_imp (concl x64_init_ok)))
  |> REWRITE_RULE [AND_IMP_INTRO]
  |> check_thm;

val generated_api_wrapper_machine_refines =
  generated_api_compile_correct_applied
  |> DISCH_ALL
  |> check_thm;

val _ =
  save_thm ("generated_api_wrapper_machine_refines",
            generated_api_wrapper_machine_refines);

(* One theorem artifact carries both directions needed by the pipeline:
   - source service execution obeys the generated API/FFI contract;
   - exact x64 machine semantics refines that non-failing CakeML program. *)
val generated_api_wrapper_source_to_machine =
  CONJ generated_api_compile_correct_applied
       generated_api_service_semantics_prog_open
  |> DISCH_ALL
  |> check_thm;

val _ =
  save_thm ("generated_api_wrapper_source_to_machine",
            generated_api_wrapper_source_to_machine);

fun require_kernel_clean name th =
  let
    val (oracles,axioms) = Tag.dest_tag (Thm.tag th)
  in
    if null (Thm.hyp th) andalso
       List.all (fn s => s = "DISK_THM") oracles andalso
       null axioms
    then ()
    else raise Fail ("open/oracular generated API theorem: " ^ name)
  end;

val _ =
  require_kernel_clean "generated_api_wrapper_no_source_fail"
    generated_api_wrapper_no_source_fail;
val _ =
  require_kernel_clean "generated_api_wrapper_machine_refines"
    generated_api_wrapper_machine_refines;
val _ =
  require_kernel_clean "generated_api_wrapper_source_to_machine"
    generated_api_wrapper_source_to_machine;

val _ = export_theory();
