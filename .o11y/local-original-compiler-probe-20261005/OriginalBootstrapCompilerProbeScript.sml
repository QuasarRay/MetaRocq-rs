(* Qualify the original CakeML compiler evaluator, not a project binary. *)
Theory OriginalBootstrapCompilerProbe
Ancestors
  ast
Libs
  preamble eval_cake_compile_x64Lib

Definition original_bootstrap_probe_prog_def:
  original_bootstrap_probe_prog = [] : ast$dec list
End

fun require_clean_closed name th =
  if null (Thm.hyp th) andalso
     (Tag.isEmpty (Thm.tag th) orelse Tag.isDisk (Thm.tag th))
  then ()
  else raise Fail ("Open or contaminated compiler probe theorem: " ^ name);

val original_bootstrap_probe_evaluated =
  eval_cake_compile_x64 "original_bootstrap_probe_"
    original_bootstrap_probe_prog_def "original-bootstrap-probe.S"
  |> check_thm;

val _ = require_clean_closed "original_bootstrap_probe_evaluated"
  original_bootstrap_probe_evaluated;
val _ = save_thm ("original_bootstrap_probe_evaluated",
  original_bootstrap_probe_evaluated);

Definition original_bootstrap_probe_machine_code_def:
  original_bootstrap_probe_machine_code = original_bootstrap_probe_code
End

val _ = require_clean_closed "original_bootstrap_probe_machine_code_def"
  original_bootstrap_probe_machine_code_def;
val _ = print "Kernel-checked closed in-logic x64 compiler probe.\n";
val _ = print "Qualification only: no Peregrine, MetaRocq, or Rocq binary certificate.\n";
