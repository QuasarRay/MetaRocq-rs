Theory GeneratedApiWrapperCompile
Ancestors
  compiler
Libs
  preamble eval_cake_compile_x64Lib

fun require_env name =
  case OS.Process.getEnv name of
    SOME s => s
  | NONE => raise Fail ("missing required environment variable: " ^ name);

val source_path = require_env "GENERATED_API_WRAPPER_CML";
val output_asm = require_env "GENERATED_API_WRAPPER_ASM";

val in_stream = TextIO.openIn source_path;
val source = TextIO.inputAll in_stream;
val _ = TextIO.closeIn in_stream;

val source_tm = stringSyntax.fromMLstring source;

val generated_api_wrapper_source_def =
  Define `generated_api_wrapper_source = ^source_tm`;

val parse_eval =
  EVAL `parse_cml_input generated_api_wrapper_source`;

val parse_rhs = rhs (concl parse_eval);
val (parse_ctor, parsed_prog_tm) =
  dest_comb parse_rhs
  handle HOL_ERR _ =>
    raise Fail "CakeML source parser did not return a sum constructor";

val _ =
  if same_const parse_ctor `INR` then ()
  else raise Fail "Generated CakeML wrapper source failed verified parsing";

val generated_api_wrapper_prog_def =
  Define `generated_api_wrapper_prog = ^parsed_prog_tm`;

Theorem generated_api_wrapper_parses:
  parse_cml_input generated_api_wrapper_source =
  INR generated_api_wrapper_prog
Proof
  rw [parse_eval, generated_api_wrapper_prog_def]
QED

val generated_api_wrapper_compiled =
  eval_cake_compile_x64
    "generated_api_wrapper_" generated_api_wrapper_prog_def output_asm
  |> check_thm;

val _ =
  save_thm ("generated_api_wrapper_compiled",
            generated_api_wrapper_compiled);

fun require_clean_closed name th =
  let val tag = Thm.tag th
  in
    if null (Thm.hyp th) andalso
       (Tag.isEmpty tag orelse Tag.isDisk tag)
    then ()
    else raise Fail ("contaminated or open theorem: " ^ name)
  end;

val _ = require_clean_closed "generated_api_wrapper_parses"
  generated_api_wrapper_parses;
val _ = require_clean_closed "generated_api_wrapper_compiled"
  generated_api_wrapper_compiled;

val generated_api_wrapper_machine_code_def =
  Define `generated_api_wrapper_machine_code =
          generated_api_wrapper_code`
  |> check_thm;

val _ = export_theory();
