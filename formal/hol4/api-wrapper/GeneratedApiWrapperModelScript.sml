Theory GeneratedApiWrapperModel
Ancestors
  GeneratedApiContract list words
Libs
  preamble

Datatype:
  api_error = UnknownOperation | ForeignRejected
End

Datatype:
  api_result = ApiOk (word8 list) | ApiError api_error
End

Definition generated_wrapper_step_def:
  generated_wrapper_step
    (known:string list)
    (foreign:string -> word8 list -> api_result)
    (op:string)
    (payload:word8 list) =
      if MEM op known then foreign op payload
      else ApiError UnknownOperation
End

Definition generated_api_step_def:
  generated_api_step foreign op payload =
    generated_wrapper_step generated_api_operations foreign op payload
End

Definition generated_api_conf_def:
  generated_api_conf (op:string) =
    MAP ((n2w:num->word8) o ORD) op
End

Definition generated_foreign_bytes_refines_original_def:
  generated_foreign_bytes_refines_original
    (original:string -> word8 list -> word8 list)
    (foreign:word8 list -> word8 list -> word8 list option) <=>
      !op payload.
        MEM op generated_api_operations ==>
        foreign (generated_api_conf op) payload =
        SOME (original op payload)
End

Definition generated_foreign_refines_original_def:
  generated_foreign_refines_original
    (original:string -> word8 list -> api_result)
    (foreign:string -> word8 list -> api_result) <=>
      !op payload.
        MEM op generated_api_operations ==>
        foreign op payload = original op payload
End

Definition generated_wrapper_safe_def:
  generated_wrapper_safe known foreign <=>
    !op payload.
      ~MEM op known ==>
      generated_wrapper_step known foreign op payload =
        ApiError UnknownOperation
End

Theorem generated_wrapper_step_total:
  !known foreign op payload.
    ?r. generated_wrapper_step known foreign op payload = r
Proof
  rw [generated_wrapper_step_def]
QED

Theorem generated_wrapper_unknown_fail_closed:
  !known foreign op payload.
    ~MEM op known ==>
    generated_wrapper_step known foreign op payload =
      ApiError UnknownOperation
Proof
  simp [generated_wrapper_step_def]
QED

Theorem generated_wrapper_known_is_exact_foreign_call:
  !known foreign op payload.
    MEM op known ==>
    generated_wrapper_step known foreign op payload =
      foreign op payload
Proof
  simp [generated_wrapper_step_def]
QED

Theorem generated_api_unknown_fail_closed:
  !foreign op payload.
    ~MEM op generated_api_operations ==>
    generated_api_step foreign op payload =
      ApiError UnknownOperation
Proof
  simp [generated_api_step_def,generated_wrapper_step_def]
QED

Theorem generated_api_known_is_exact_foreign_call:
  !foreign op payload.
    MEM op generated_api_operations ==>
    generated_api_step foreign op payload =
      foreign op payload
Proof
  simp [generated_api_step_def,generated_wrapper_step_def]
QED

Theorem generated_foreign_bytes_refines_original_call:
  !original foreign op payload.
    generated_foreign_bytes_refines_original original foreign /\
    MEM op generated_api_operations ==>
    foreign (generated_api_conf op) payload =
    SOME (original op payload)
Proof
  simp [generated_foreign_bytes_refines_original_def]
QED

Theorem generated_api_refines_original:
  !original foreign op payload.
    generated_foreign_refines_original original foreign /\
    MEM op generated_api_operations ==>
    generated_api_step foreign op payload =
      original op payload
Proof
  simp [generated_foreign_refines_original_def,
        generated_api_step_def,generated_wrapper_step_def]
QED

Theorem generated_wrapper_safe:
  !known foreign. generated_wrapper_safe known foreign
Proof
  simp [generated_wrapper_safe_def,generated_wrapper_step_def]
QED

Theorem generated_api_step_total:
  !foreign op payload. ?r. generated_api_step foreign op payload = r
Proof
  simp [generated_api_step_def]
  \\ metis_tac [generated_wrapper_step_total]
QED
