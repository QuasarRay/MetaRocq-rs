Theory GeneratedApiWrapperQualification
Ancestors
  GeneratedApiWrapperModel GeneratedApiWrapperCompile
Libs
  preamble

Theorem generated_api_wrapper_one_to_one:
  !known original foreign op payload.
    generated_foreign_refines_original original foreign /\
    MEM op known ==>
    generated_wrapper_step known foreign op payload =
      original op payload
Proof
  metis_tac [generated_wrapper_refines_original]
QED

Theorem generated_api_wrapper_unknown_operations_fail_closed:
  !known foreign op payload.
    ~MEM op known ==>
    generated_wrapper_step known foreign op payload =
      ApiError UnknownOperation
Proof
  metis_tac [generated_wrapper_unknown_fail_closed]
QED

Theorem generated_api_wrapper_protocol_total:
  !known foreign op payload.
    ?r. generated_wrapper_step known foreign op payload = r
Proof
  metis_tac [generated_wrapper_step_total]
QED

Theorem generated_api_wrapper_exact_machine_object:
  generated_api_wrapper_machine_code =
  generated_api_wrapper_code
Proof
  rw [generated_api_wrapper_machine_code_def]
QED

val _ =
  let
    val ths =
      [generated_api_wrapper_one_to_one,
       generated_api_wrapper_unknown_operations_fail_closed,
       generated_api_wrapper_protocol_total,
       generated_api_wrapper_exact_machine_object,
       generated_api_wrapper_compiled]
    fun clean th =
      let val (oracles,axioms) = Tag.dest_tag (Thm.tag th)
      in null (Thm.hyp th) andalso
         List.all (fn s => s = "DISK_THM") oracles andalso
         null axioms
      end
  in
    if List.all clean ths then ()
    else raise Fail "Generated wrapper qualification contains open/contaminated theorem"
  end;

val _ = export_theory();
