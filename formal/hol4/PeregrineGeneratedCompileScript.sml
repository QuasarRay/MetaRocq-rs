Theory PeregrineGeneratedCompile
Ancestors
  compiler
Libs
  preamble eval_cake_compile_x64Lib

fun require_env name =
  case OS.Process.getEnv name of
    SOME s => s
  | NONE => raise Fail ("missing required environment variable: " ^ name);

val serialized_path = require_env "PEREGRINE_CAKEML_SEXP";
val output_asm = require_env "PEREGRINE_MACHINE_ASM";

val in_stream = TextIO.openIn serialized_path;
val serialized = TextIO.inputAll in_stream;
val _ = TextIO.closeIn in_stream;

val serialized_tm = stringSyntax.fromMLstring serialized;

val peregrine_serialized_cakeml_input_def =
  Define `peregrine_serialized_cakeml_input = ^serialized_tm`;

(* Evaluate the verified CakeML S-expression parser in HOL.  The native
   Peregrine process is only a producer of [serialized]; this theory binds the
   exact bytes it produced to the exact CakeML AST that is compiled below. *)
val parse_eval =
  EVAL `parse_sexp_input peregrine_serialized_cakeml_input`;

val parse_rhs = rhs (concl parse_eval);
val (parse_ctor, parsed_prog_tm) =
  dest_comb parse_rhs
  handle HOL_ERR _ =>
    raise Fail "CakeML S-expression parser did not return a sum constructor";

val _ =
  if same_const parse_ctor `INR` then ()
  else raise Fail "Peregrine CakeML S-expression failed CakeML's verified parser";

val peregrine_selfhost_prog_def =
  Define `peregrine_selfhost_prog = ^parsed_prog_tm`;

Theorem peregrine_serialized_cakeml_parses =
  parse_sexp_input peregrine_serialized_cakeml_input =
  INR peregrine_selfhost_prog
Proof
  rw [parse_eval, peregrine_selfhost_prog_def]
QED

(* This is the exact theorem-producing CakeML compiler evaluation.  It proves
   what exact target program the exact parsed AST compiles to.  Application
   semantics and the Peregrine source/replay refinement are composed later;
   this theorem alone does not authorize the final E2E claim. *)
val peregrine_selfhost_compiled =
  eval_cake_compile_x64 "" peregrine_selfhost_prog_def output_asm
  |> check_thm;

val _ =
  save_thm ("peregrine_selfhost_compiled", peregrine_selfhost_compiled);

val _ = export_theory();
