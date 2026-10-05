Theory GeneratedApiWrapperSource
Ancestors
  GeneratedApiBridgeAbi basisProg
Libs
  preamble basis cfLib ml_progLib cfTacticsLib

fun require_env name =
  case OS.Process.getEnv name of
    SOME s => s
  | NONE => raise Fail ("missing required environment variable: " ^ name);

val source_path = require_env "GENERATED_API_WRAPPER_CML";
val in_stream = TextIO.openIn source_path;
val generated_source = TextIO.inputAll in_stream;
val _ = TextIO.closeIn in_stream;

(* Parse the exact generated CakeML source through CakeML's own parser and
   normaliser, then extend the basis characteristic-formula program state. *)
val _ = translation_extends "basisProg";
val generated_topdecs =
  cfTacticsLib.process_topdecs [QUOTE generated_source];
val _ =
  ml_translatorLib.ml_prog_update
    (ml_progLib.add_prog generated_topdecs I);
val generated_api_wrapper_st = ml_translatorLib.get_ml_prog_state();

Definition generated_api_io_def:
  generated_api_io s u = IO s u [«api_bridge»]
End

(* One handwritten proof for the common bridge primitive. Per-operation
   wrappers are generated constant-operation-id instantiations of this proof. *)
Theorem generated_api_call_spec:
  !p op opv av input s u s' output.
    STRING_TYPE op opv /\
    generated_api_frame_wf input /\
    generated_api_bridge_transition u s op input s' output ==>
    app (p:'ffi ffi_proj)
      ^(fetch_v "generated_api_call" generated_api_wrapper_st)
      [opv; av]
      (W8ARRAY av input * generated_api_io s u)
      (POSTv v.
        &(v = av) *
        W8ARRAY av output *
        generated_api_io s' u)
Proof
  rpt strip_tac
  \ xcf "generated_api_call" generated_api_wrapper_st
  \ xlet_auto THEN1 xsimpl
  \ xif
  >- (fs [generated_api_frame_wf_def,generated_api_min_frame_def])
  \ xlet
       `POSTv uv.
          &UNIT_TYPE () uv *
          W8ARRAY av output *
          generated_api_io s' u`
  >- (xffi
      \ xsimpl
      \ fs [generated_api_io_def,IO_def,
             generated_api_bridge_transition_def]
      \ qmatch_goalsub_abbrev_tac `FFI_part ss uu ns events`
      \ MAP_EVERY qexists_tac [`emp`,`ss`,`uu`,`ns`,`events`]
      \ xsimpl
      \ fs [])
  \ xvar
  \ xsimpl
QED

(* Construction fails closed if the common generated binding is absent. *)
val _ =
  ignore (fetch_v "generated_api_call" generated_api_wrapper_st)
  handle HOL_ERR _ =>
    raise Fail "generated source does not export generated_api_call";

val _ = export_theory();
