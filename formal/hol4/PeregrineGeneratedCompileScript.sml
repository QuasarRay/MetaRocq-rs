Theory PeregrineGeneratedCompile
Ancestors
  compiler
Libs
  preamble eval_cake_compile_x64Lib

fun require_env name =
  case OS.Process.getEnv name of
    SOME s => s
  | NONE => raise Fail ("missing required environment variable: " ^ name);

(* The build wrapper materializes and hashes this exact dependency. Reading a
   stable path also prevents an unrelated environment value from selecting
   bytes different from Holmake's declared input. *)
val serialized_path =
  "../../generated/peregrine-selfhost/hol4/compiler-input.sexp";
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

(* This is the exact theorem-producing CakeML compiler evaluation.  The
   non-empty prefix deliberately gives the generated code/data/oracle/info
   constants stable Peregrine-specific names.  In particular, the helper
   creates [peregrine_code] as the exact compiler-produced byte object in HOL;
   [output_asm] is only its exported assembler representation. *)
val peregrine_selfhost_compiled =
  eval_cake_compile_x64
    "peregrine_" peregrine_selfhost_prog_def output_asm
  |> check_thm;

val _ =
  save_thm ("peregrine_selfhost_compiled", peregrine_selfhost_compiled);

(* A compiler-evaluation theorem must be closed and free from extra axioms or
   oracle tags other than HOL4's normal DISK_THM dependency-load marker.
   This is the same tag policy as CakeML's check_thm. Checking these objects
   it does not supply the later source-semantics composition theorem. *)
fun require_clean_closed name th =
  let val tag = Thm.tag th
  in
    if null (Thm.hyp th) andalso (Tag.isEmpty tag orelse Tag.isDisk tag) then ()
    else raise Fail ("contaminated or open compiler theorem: " ^ name)
  end;

val _ = require_clean_closed "peregrine_serialized_cakeml_parses"
  peregrine_serialized_cakeml_parses;
val _ = require_clean_closed "peregrine_selfhost_compiled"
  peregrine_selfhost_compiled;

(* Retain an explicit, stable byte-level alias for downstream source-to-machine
   composition.  This definition is not a source-semantics theorem; it simply
   names the exact code object already produced by the checked compiler
   evaluation above. *)
val peregrine_machine_code_def =
  Define `peregrine_machine_code = peregrine_code`
  |> check_thm;

val _ = export_theory();
