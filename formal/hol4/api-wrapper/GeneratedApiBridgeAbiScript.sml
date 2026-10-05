Theory GeneratedApiBridgeAbi
Ancestors
  GeneratedApiContract list words cfHeapsBase
Libs
  preamble

Definition generated_api_min_frame_def:
  generated_api_min_frame = 16
End

Definition generated_api_frame_wf_def:
  generated_api_frame_wf (bytes:word8 list) <=>
    generated_api_min_frame <= LENGTH bytes
End

Definition generated_api_bridge_transition_def:
  generated_api_bridge_transition
    (u:ffi_next) (s:ffi) (op:string)
    (input:word8 list) (s':ffi) (output:word8 list) <=>
      u «api_bridge»
        (MAP (n2w o ORD) (explode op))
        input s =
        SOME (FFIreturn output s') /\
      LENGTH output = LENGTH input
End

Definition generated_api_known_operation_def:
  generated_api_known_operation op <=>
    MEM op generated_api_operations
End

Definition generated_api_safe_call_def:
  generated_api_safe_call u s op input s' output <=>
    generated_api_frame_wf input /\
    generated_api_known_operation op /\
    generated_api_bridge_transition u s op input s' output
End

Theorem generated_api_short_frame_rejected:
  !bytes.
    ~generated_api_frame_wf bytes <=>
    LENGTH bytes < generated_api_min_frame
Proof
  simp [generated_api_frame_wf_def]
QED

Theorem generated_api_bridge_preserves_length:
  !u s op input s' output.
    generated_api_bridge_transition u s op input s' output ==>
    LENGTH output = LENGTH input
Proof
  simp [generated_api_bridge_transition_def]
QED

Theorem generated_api_safe_call_has_bounded_result:
  !u s op input s' output.
    generated_api_safe_call u s op input s' output ==>
    generated_api_frame_wf output
Proof
  simp [generated_api_safe_call_def,generated_api_frame_wf_def,
        generated_api_bridge_transition_def]
QED

Theorem generated_api_safe_call_exact_operation:
  !u s op input s' output.
    generated_api_safe_call u s op input s' output ==>
    MEM op generated_api_operations
Proof
  simp [generated_api_safe_call_def,generated_api_known_operation_def]
QED

Theorem generated_api_safe_call_exact_ffi_name:
  !u s op input s' output.
    generated_api_safe_call u s op input s' output ==>
    u «api_bridge»
      (MAP (n2w o ORD) (explode op))
      input s =
      SOME (FFIreturn output s')
Proof
  simp [generated_api_safe_call_def,generated_api_bridge_transition_def]
QED

val _ = export_theory();
