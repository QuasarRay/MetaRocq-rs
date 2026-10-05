Theory OriginalCompilerOutputTacticToe
Ancestors
  OriginalCompilerOutputAutomation OriginalBootstrapCompilerProbe list
Libs
  CompilerOutputAutomationLib

val (_,probe_code_nonempty_tactictoe) =
  CompilerOutputAutomationLib.code_nonempty_tactictoe
    {compiled = original_bootstrap_probe_compiled,
     code = ``original_bootstrap_probe_code``};
val _ = save_thm ("probe_code_nonempty_tactictoe", probe_code_nonempty_tactictoe);

val expected = ``original_bootstrap_probe_code <> []``;
val (oracles, axioms) = Tag.dest_tag (Thm.tag probe_code_nonempty_tactictoe);
val _ = if null (Thm.hyp probe_code_nonempty_tactictoe) andalso
           aconv (Thm.concl probe_code_nonempty_tactictoe) expected andalso
           List.all (fn name => name = "DISK_THM") oracles andalso null axioms
        then () else raise Fail "Open, contaminated, or wrong TacticToe theorem";
val out = TextIO.openOut "compiler-output-tactictoe-inspection.json";
val _ = TextIO.output (out,
  "{\"theorem\":\"OriginalCompilerOutputTacticToe.probe_code_nonempty_tactictoe\",\"exact_goal_checked\":true,\"hypotheses\":0,\"non_disk_oracles\":0,\"local_axioms\":0,\"claim\":\"compiler-output qualification; NOT MetaRocq E2E refinement\"}\n");
val _ = TextIO.closeOut out;
