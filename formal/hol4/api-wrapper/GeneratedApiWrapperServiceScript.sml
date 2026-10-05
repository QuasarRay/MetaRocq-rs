Theory GeneratedApiWrapperService
Ancestors
  GeneratedApiWrapperSource GeneratedApiWrapperCompile cfMain semanticsProps
Libs
  preamble basis cfLib ml_progLib cfTacticsLib

fun require_env name =
  case OS.Process.getEnv name of
    SOME s => s
  | NONE => raise Fail ("missing required environment variable: " ^ name);

val source_path = require_env "GENERATED_API_WRAPPER_CML";
val ins = TextIO.openIn source_path;
val generated_source = TextIO.inputAll ins;
val _ = TextIO.closeIn ins;

(* Rebuild the exact characteristic-formula state from the same generated
   source used by the compiler theorem. *)
val _ = translation_extends "basisProg";
val generated_topdecs =
  cfTacticsLib.process_topdecs [QUOTE generated_source];
val _ =
  ml_translatorLib.ml_prog_update
    (ml_progLib.add_prog generated_topdecs I);
val generated_service_st = ml_translatorLib.get_ml_prog_state();

val service_library_prog_tm = ml_progLib.get_prog generated_service_st;
val generated_api_service_library_prog_def =
  Define `generated_api_service_library_prog = ^service_library_prog_tm`;

Theorem generated_api_service_Decls =
  ml_progLib.get_Decls_thm generated_service_st
  |> REWRITE_RULE [GSYM generated_api_service_library_prog_def];

(* Fail closed if CF parsing/normalisation ever ceases to denote exactly the
   program compiled by the in-logic compiler lane. *)
Theorem generated_api_service_library_matches_compile:
  generated_api_service_library_prog =
  generated_api_wrapper_library_prog
Proof
  EVAL_TAC
QED

val operation_names_v =
  fetch_v "generated_operation_names" generated_service_st;

Theorem generated_operation_names_rep:
  LIST_TYPE STRING_TYPE generated_api_operations ^operation_names_v
Proof
  EVAL_TAC
QED

Definition generated_api_service_names_def:
  generated_api_service_names =
    [«api_request»; «api_bridge»; «api_reply»]
End

Definition generated_api_service_io_def:
  generated_api_service_io s u =
    IO s u generated_api_service_names
End

Definition generated_lookup_model_def:
  (generated_lookup_model [] n = NONE) /\
  (generated_lookup_model (x::xs) n =
    if n = 0 then SOME x else generated_lookup_model xs (n - 1))
End

Definition generated_read_index_model_def:
  generated_read_index_model (bytes:word8 list) =
      w2n (EL 4 bytes)
    + 256 * w2n (EL 5 bytes)
    + 65536 * w2n (EL 6 bytes)
    + 16777216 * w2n (EL 7 bytes)
End

Definition generated_status_error_frame_def:
  generated_status_error_frame (bytes:word8 list) code =
    LUPDATE (n2w code) 0 bytes
End

Definition generated_api_request_transition_def:
  generated_api_request_transition
    (u:ffi_next) (s:ffi) (request:word8 list) (s':ffi) <=>
      u «api_request» [] (REPLICATE 64 0w) s =
        SOME (FFIreturn request s') /\
      LENGTH request = 64
End

Definition generated_api_reply_transition_def:
  generated_api_reply_transition
    (u:ffi_next) (s:ffi) (input:word8 list)
    (reply:word8 list) (s':ffi) <=>
      u «api_reply» [] input s =
        SOME (FFIreturn reply s') /\
      LENGTH reply = LENGTH input
End

Definition generated_api_dispatch_transition_def:
  generated_api_dispatch_transition
    (u:ffi_next) (s:ffi) index (input:word8 list)
    (output:word8 list) (s':ffi) <=>
      LENGTH input = 64 /\
      case generated_api_operation_at index of
        NONE =>
          s' = s /\
          output = generated_status_error_frame input 2
      | SOME op =>
          generated_api_bridge_transition u s op input s' output
End

Definition generated_api_service_contract_def:
  generated_api_service_contract
    (u:ffi_next) (s0:ffi)
    request s1 result s2 reply s3 <=>
      generated_api_request_transition u s0 request s1 /\
      generated_api_dispatch_transition u s1
        (generated_read_index_model request) request result s2 /\
      generated_api_reply_transition u s2 result reply s3
End

Theorem generated_lookup_model_eq:
  !xs n.
    generated_lookup_model xs n =
      if n < LENGTH xs then SOME (EL n xs) else NONE
Proof
  Induct
  >- simp [generated_lookup_model_def]
  \ Cases_on n
  \ simp [generated_lookup_model_def]
QED

Theorem generated_lookup_model_operation_at:
  !n.
    generated_lookup_model generated_api_operations n =
    generated_api_operation_at n
Proof
  simp [generated_lookup_model_eq,generated_api_operation_at_def]
QED

Theorem generated_status_error_frame_length:
  !bytes code.
    bytes <> [] ==>
    LENGTH (generated_status_error_frame bytes code) = LENGTH bytes
Proof
  simp [generated_status_error_frame_def]
QED

Theorem generated_dispatch_preserves_frame:
  !u s index input output s'.
    generated_api_dispatch_transition u s index input output s' ==>
    LENGTH output = 64
Proof
  rw [generated_api_dispatch_transition_def]
  \ Cases_on `generated_api_operation_at index`
  \ fs [generated_status_error_frame_length,
         generated_api_bridge_transition_def]
QED

Theorem generated_api_service_io_has_ffi:
  !s u. FFI_part_hprop (generated_api_service_io s u)
Proof
  rw [FFI_part_hprop_def,generated_api_service_io_def,
      IO_def,SEP_EXISTS_THM,SEP_CLAUSES,one_def]
  \ metis_tac []
QED

Theorem generated_api_main_post_has_ffi:
  !av bytes s u.
    FFI_part_hprop
      (W8ARRAY av bytes * generated_api_service_io s u)
Proof
  rpt strip_tac
  \ irule FFI_part_hprop_STAR
  \ right
  \ simp [generated_api_service_io_has_ffi]
QED

Theorem generated_status_error_spec:
  !p av bytes code cv.
    bytes <> [] /\ NUM code cv ==>
    app (p:'ffi ffi_proj)
      ^(fetch_v "generated_status_error" generated_service_st)
      [av;cv]
      (W8ARRAY av bytes)
      (POSTv v.
        &(v = av) *
        W8ARRAY av (generated_status_error_frame bytes code))
Proof
  rpt strip_tac
  \ xcf "generated_status_error" generated_service_st
  \ xlet_auto THEN1 xsimpl
  \ xlet_auto THEN1 xsimpl
  \ xvar
  \ xsimpl
  \ fs [generated_status_error_frame_def,NUM_def,INT_def]
QED

Theorem generated_lookup_spec:
  !p xs xsv n nv.
    LIST_TYPE STRING_TYPE xs xsv /\ NUM n nv ==>
    app (p:'ffi ffi_proj)
      ^(fetch_v "generated_lookup" generated_service_st)
      [xsv;nv]
      emp
      (POSTv ov.
        &OPTION_TYPE STRING_TYPE (generated_lookup_model xs n) ov)
Proof
  Induct_on `xs`
  \ rpt strip_tac
  \ fs [LIST_TYPE_def,generated_lookup_model_def]
  >- (xcf "generated_lookup" generated_service_st
      \ xmatch
      \ xcon
      \ xsimpl
      \ simp [OPTION_TYPE_def])
  \ xcf "generated_lookup" generated_service_st
  \ xmatch
  \ xif
  >- (xcon \ xsimpl \ simp [OPTION_TYPE_def])
  \ xlet_auto THEN1 xsimpl
  \ xapp
  \ xsimpl
QED

Theorem generated_read_index_spec:
  !p av bytes.
    8 <= LENGTH bytes ==>
    app (p:'ffi ffi_proj)
      ^(fetch_v "generated_read_index" generated_service_st)
      [av]
      (W8ARRAY av bytes)
      (POSTv nv.
        &NUM (generated_read_index_model bytes) nv *
        W8ARRAY av bytes)
Proof
  rpt strip_tac
  \ xcf "generated_read_index" generated_service_st
  \ rpt (xlet_auto THEN1 xsimpl)
  \ xsimpl
  \ fs [generated_read_index_model_def,NUM_def,INT_def,
         integerTheory.INT_ADD,integerTheory.INT_MUL]
QED

(* Same CakeML function as GeneratedApiWrapperSource.generated_api_call_spec,
   but framed over the complete service FFI name set. *)
Theorem generated_api_call_service_spec:
  !p op opv av input s u s' output.
    STRING_TYPE op opv /\
    generated_api_frame_wf input /\
    generated_api_bridge_transition u s op input s' output ==>
    app (p:'ffi ffi_proj)
      ^(fetch_v "generated_api_call" generated_service_st)
      [opv;av]
      (W8ARRAY av input * generated_api_service_io s u)
      (POSTv v.
        &(v = av) *
        W8ARRAY av output *
        generated_api_service_io s' u)
Proof
  rpt strip_tac
  \ xcf "generated_api_call" generated_service_st
  \ xlet_auto THEN1 xsimpl
  \ xif
  >- (fs [generated_api_frame_wf_def,generated_api_min_frame_def])
  \ xlet
       `POSTv uv.
          &UNIT_TYPE () uv *
          W8ARRAY av output *
          generated_api_service_io s' u`
  >- (xffi
      \ xsimpl
      \ fs [generated_api_service_io_def,
             generated_api_service_names_def,IO_def,
             generated_api_bridge_transition_def]
      \ qmatch_goalsub_abbrev_tac `FFI_part ss uu ns events`
      \ MAP_EVERY qexists_tac [`emp`,`ss`,`uu`,`ns`,`events`]
      \ xsimpl
      \ fs [])
  \ xvar
  \ xsimpl
QED

Theorem generated_dispatch_spec:
  !p index iv av input s u output s'.
    NUM index iv /\
    generated_api_dispatch_transition u s index input output s' ==>
    app (p:'ffi ffi_proj)
      ^(fetch_v "generated_dispatch" generated_service_st)
      [iv;av]
      (W8ARRAY av input * generated_api_service_io s u)
      (POSTv v.
        &(v = av) *
        W8ARRAY av output *
        generated_api_service_io s' u)
Proof
  rpt strip_tac
  \ fs [generated_api_dispatch_transition_def]
  \ xcf "generated_dispatch" generated_service_st
  \ xlet
       `POSTv ov.
          &OPTION_TYPE STRING_TYPE
            (generated_lookup_model generated_api_operations index) ov *
          W8ARRAY av input *
          generated_api_service_io s u`
  >- (xapp_spec generated_lookup_spec
      \ xsimpl
      \ metis_tac [generated_operation_names_rep])
  \ fs [generated_lookup_model_operation_at]
  \ Cases_on `generated_api_operation_at index`
  \ fs [OPTION_TYPE_def]
  \ xmatch
  >- (xapp_spec generated_status_error_spec
      \ xsimpl
      \ fs [generated_status_error_frame_def])
  \ xapp_spec generated_api_call_service_spec
  \ xsimpl
  \ fs [generated_api_frame_wf_def,generated_api_min_frame_def]
QED

Theorem generated_service_main_spec:
  !p u s0 request s1 result s2 reply s3.
    generated_api_service_contract
      u s0 request s1 result s2 reply s3 ==>
    app (p:'ffi ffi_proj)
      ^(fetch_v "generated_service_main" generated_service_st)
      [Conv NONE []]
      (generated_api_service_io s0 u)
      (POSTv uv.
        &UNIT_TYPE () uv *
        SEP_EXISTS av.
          W8ARRAY av reply *
          generated_api_service_io s3 u)
Proof
  rpt strip_tac
  \ fs [generated_api_service_contract_def,
         generated_api_request_transition_def,
         generated_api_reply_transition_def]
  \ xcf "generated_service_main" generated_service_st
  \ xmatch
  \ xlet_auto THEN1 xsimpl
  \ xlet
       `POSTv uv.
          &UNIT_TYPE () uv *
          W8ARRAY v request *
          generated_api_service_io s1 u`
  >- (xffi
      \ xsimpl
      \ fs [generated_api_service_io_def,
             generated_api_service_names_def,IO_def]
      \ qmatch_goalsub_abbrev_tac `FFI_part ss uu ns events`
      \ MAP_EVERY qexists_tac [`emp`,`ss`,`uu`,`ns`,`events`]
      \ xsimpl
      \ fs [])
  \ xlet
       `POSTv iv.
          &NUM (generated_read_index_model request) iv *
          W8ARRAY v request *
          generated_api_service_io s1 u`
  >- (xapp_spec generated_read_index_spec \ xsimpl)
  \ xlet
       `POSTv rv.
          &(rv = v) *
          W8ARRAY v result *
          generated_api_service_io s2 u`
  >- (xapp_spec generated_dispatch_spec \ xsimpl)
  \ xlet
       `POSTv uv2.
          &UNIT_TYPE () uv2 *
          W8ARRAY v reply *
          generated_api_service_io s3 u`
  >- (xffi
      \ xsimpl
      \ fs [generated_api_service_io_def,
             generated_api_service_names_def,IO_def]
      \ qmatch_goalsub_abbrev_tac `FFI_part ss uu ns events`
      \ MAP_EVERY qexists_tac [`emp`,`ss`,`uu`,`ns`,`events`]
      \ xsimpl
      \ fs [])
  \ xcon
  \ xsimpl
QED

Theorem generated_api_main_spec:
  !p u s0 request s1 result s2 reply s3.
    generated_api_service_contract
      u s0 request s1 result s2 reply s3 ==>
    app (p:'ffi ffi_proj)
      ^(fetch_v "main" generated_service_st)
      [Conv NONE []]
      (generated_api_service_io s0 u)
      (POSTv uv.
        &UNIT_TYPE () uv *
        SEP_EXISTS av.
          W8ARRAY av reply *
          generated_api_service_io s3 u)
Proof
  rpt strip_tac
  \ xcf "main" generated_service_st
  \ xapp_spec generated_service_main_spec
  \ xsimpl
QED

(* Compose the exact Decls theorem with cfMain.call_main_thm2.  Foreign
   request/bridge/reply behavior and the initial SPLIT remain explicit theorem
   premises; no Poly/ML/HOL4/Z3/TacticToe implementation fact is assumed here. *)
val generated_api_service_semantics =
  let
    val decls =
      generated_api_service_Decls
      |> REWRITE_RULE [generated_api_service_library_matches_compile]
    val app_th =
      generated_api_main_spec
      |> SPEC_ALL
      |> UNDISCH_ALL
    val th =
      cfMainTheory.call_main_thm2
      |> MATCH_MP decls
      |> SPEC (mlstringSyntax.mk_mlstring "main")
      |> CONV_RULE
           (QUANT_CONV
             (LAND_CONV
               (LAND_CONV EVAL THENC SIMP_CONV std_ss [])))
      |> CONV_RULE (HO_REWR_CONV UNWIND_FORALL_THM1)
      |> C HO_MATCH_MP app_th
      |> C HO_MATCH_MP generated_api_main_post_has_ffi
      |> REWRITE_RULE
           [generated_api_wrapper_prog_has_main_call,
            GSYM generated_api_service_library_matches_compile]
      |> DISCH_ALL
      |> check_thm
  in
    save_thm ("generated_api_service_semantics",th)
  end;

val _ = export_theory();
