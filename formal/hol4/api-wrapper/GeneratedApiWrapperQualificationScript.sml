Theory GeneratedApiWrapperQualification
Ancestors
  GeneratedApiWrapperModel GeneratedApiWrapperCompile
Libs
  preamble

Theorem generated_api_wrapper_one_to_one:
  !original foreign op payload.
    generated_foreign_refines_original original foreign /\
    MEM op generated_api_operations ==>
    generated_api_step foreign op payload =
      original op payload
Proof
  metis_tac [generated_api_refines_original]
QED

Theorem generated_api_wrapper_unknown_operations_fail_closed:
  !foreign op payload.
    ~MEM op generated_api_operations ==>
    generated_api_step foreign op payload =
      ApiError UnknownOperation
Proof
  metis_tac [generated_api_unknown_fail_closed]
QED

Theorem generated_api_wrapper_protocol_total:
  !foreign op payload.
    ?r. generated_api_step foreign op payload = r
Proof
  metis_tac [generated_api_step_total]
QED

Theorem generated_api_wrapper_exact_machine_object:
  generated_api_wrapper_machine_code =
  generated_api_wrapper_code
Proof
  rw [generated_api_wrapper_machine_code_def]
QED

Theorem generated_api_manifest_is_nonempty:
  generated_api_operations <> []
Proof
  fs [generated_api_operation_count]
QED

val _ =
  let
    val ths =
      [generated_api_wrapper_one_to_one,
       generated_api_wrapper_unknown_operations_fail_closed,
       generated_api_wrapper_protocol_total,
       generated_api_wrapper_exact_machine_object,
       generated_api_manifest_is_nonempty,
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

(* The foreign-contract premise is deliberate: this theory proves that the
   generated protocol mirrors the exact API inventory and binds the generated
   CakeML source to its exact compiler theorem. It does not claim that the
   external Poly/ML implementation was verified by CakeML. *)
val _ = export_theory();
