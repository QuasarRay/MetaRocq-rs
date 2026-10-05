Theory OriginalCompilerOutputAutomationContract
Ancestors
  OriginalCompilerOutputAutomation OriginalBootstrapCompilerProbe words
Libs
  CompilerOutputAutomationLib

(* Exercise the same reusable library invoked by the Peregrine producer on
   actual CakeML output. No project source-replay claim is made here. *)
val compiled = original_bootstrap_probe_compiled;
val code = ``original_bootstrap_probe_code``;
val data = ``original_bootstrap_probe_data``;
val facts = CompilerOutputAutomationLib.image_layout_facts
  {compiled = compiled, code = code, data = data};
val expectations = [
  ("code_length", ``LENGTH original_bootstrap_probe_code = 67910``),
  ("data_length", ``LENGTH original_bootstrap_probe_data = 354``),
  ("code_address_bounds_z3", concl probe_code_address_bounds_z3),
  ("code_data_offsets_disjoint_z3", concl probe_code_data_offsets_disjoint_z3)];
val _ = if length facts = length expectations then ()
        else raise Fail "Incorrect compiler-output fact inventory";
val _ = ListPair.app
  (fn ((name,goal,th),(expected_name,expected_goal)) =>
    if name = expected_name andalso aconv goal expected_goal then
      (CompilerOutputAutomationLib.inspect_exact name expected_goal th;
       ignore (save_thm ("library_" ^ name, th)))
    else raise Fail "Compiler-output library changed its declared goal")
  (facts,expectations);

fun must_reject name thunk =
  if ((thunk (); false) handle Fail _ => true)
  then () else raise Fail ("Compiler-output library accepted " ^ name);
val length_goal = ``LENGTH original_bootstrap_probe_code = 67910``;
val _ = must_reject "open input" (fn () =>
  ignore (CompilerOutputAutomationLib.image_layout_facts
    {compiled = ASSUME length_goal, code = code, data = data}));
val _ = must_reject "oracle-backed input" (fn () =>
  ignore (CompilerOutputAutomationLib.image_layout_facts
    {compiled = mk_oracle_thm "RejectedCompilerInput" ([],length_goal),
     code = code, data = data}));
val _ = must_reject "unrelated theorem" (fn () =>
  ignore (CompilerOutputAutomationLib.image_layout_facts
    {compiled = TRUTH, code = code, data = data}));
val _ = must_reject "wrong code type" (fn () =>
  ignore (CompilerOutputAutomationLib.image_layout_facts
    {compiled = compiled, code = ``0:num``, data = data}));
val _ = must_reject "wrong data type" (fn () =>
  ignore (CompilerOutputAutomationLib.image_layout_facts
    {compiled = compiled, code = code, data = ``[]:word8 list``}));
val _ = must_reject "unbound same-type code" (fn () =>
  ignore (CompilerOutputAutomationLib.image_layout_facts
    {compiled = compiled, code = ``[]:word8 list``, data = data}));
val _ = must_reject "unbound same-type data" (fn () =>
  ignore (CompilerOutputAutomationLib.image_layout_facts
    {compiled = compiled, code = code, data = ``[]:word64 list``}));

val out = TextIO.openOut "compiler-output-library-inspection.json";
val _ = TextIO.output (out,
  "{\"theory\":\"OriginalCompilerOutputAutomationContract\",\"closed_theorems\":4,\"z3_reconstructed_theorems\":2,\"negative_inputs_rejected\":7,\"exact_goals_checked\":true,\"claim\":\"reusable compiler-output automation qualification; NOT MetaRocq E2E refinement\"}\n");
val _ = TextIO.closeOut out;
