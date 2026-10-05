(* Actual original CakeML output; qualification does not close the project E2E gap. *)
Theory OriginalCompilerOutputAutomation
Ancestors
  OriginalBootstrapCompilerProbe arithmetic integer list words
Libs
  HolSmtLib

Theorem probe_output_sizes:
  LENGTH original_bootstrap_probe_code = 67910 /\
  LENGTH original_bootstrap_probe_data = 354
Proof
  metis_tac [original_bootstrap_probe_compiled]
QED

(* The code and data are from the kernel-checked compiler evaluation above.
   These integer bounds concern an abstract contiguous image layout. *)
Theorem probe_code_address_bounds_z3:
  !base i:int.
    0 <= base /\
    base + &(LENGTH original_bootstrap_probe_code +
             8 * LENGTH original_bootstrap_probe_data) < 18446744073709551616 /\
    0 <= i /\ i < &(LENGTH original_bootstrap_probe_code) ==>
    0 <= base + i /\ base + i < 18446744073709551616
Proof
  REWRITE_TAC [probe_output_sizes] >>
  HolSmtLib.Z3_TAC
QED

Theorem probe_code_data_offsets_disjoint_z3:
  !base i j:int.
    0 <= i /\ i < &(LENGTH original_bootstrap_probe_code) /\
    0 <= j /\ j < &(LENGTH original_bootstrap_probe_data) ==>
    base + i < base + &(LENGTH original_bootstrap_probe_code) + 8 * j
Proof
  REWRITE_TAC [probe_output_sizes] >>
  HolSmtLib.Z3_TAC
QED

fun acceptable expected th =
  let val (oracles, axioms) = Tag.dest_tag (Thm.tag th)
  in null (Thm.hyp th) andalso aconv (Thm.concl th) expected
     andalso List.all (fn name => name = "DISK_THM") oracles
     andalso null axioms
  end;

val inspected = [
  ("probe_output_sizes",
   ``LENGTH original_bootstrap_probe_code = 67910 /\
     LENGTH original_bootstrap_probe_data = 354``, probe_output_sizes),
  ("probe_code_address_bounds_z3",
   ``!base i:int.
      0 <= base /\
      base + &(LENGTH original_bootstrap_probe_code +
               8 * LENGTH original_bootstrap_probe_data) < 18446744073709551616 /\
      0 <= i /\ i < &(LENGTH original_bootstrap_probe_code) ==>
      0 <= base + i /\ base + i < 18446744073709551616``, probe_code_address_bounds_z3),
  ("probe_code_data_offsets_disjoint_z3",
   ``!base i j:int.
      0 <= i /\ i < &(LENGTH original_bootstrap_probe_code) /\
      0 <= j /\ j < &(LENGTH original_bootstrap_probe_data) ==>
      base + i < base + &(LENGTH original_bootstrap_probe_code) + 8 * j``,
   probe_code_data_offsets_disjoint_z3)];

val _ = List.app (fn (name, expected, th) =>
  if acceptable expected th then ()
  else raise Fail ("Open or contaminated compiler-output theorem: " ^ name)) inspected;

val control_goal = ``original_bootstrap_probe_code <> []``;
val _ = if acceptable control_goal (ASSUME control_goal) orelse
           acceptable control_goal (mk_oracle_thm "RejectedAutomationProbe" ([], control_goal)) orelse
           acceptable control_goal TRUTH
        then raise Fail "Compiler automation inspection accepted a negative control"
        else ();

val out = TextIO.openOut "compiler-output-inspection.json";
val _ = TextIO.output (out,
  "{\"theory\":\"OriginalCompilerOutputAutomation\",\"closed_theorems\":3,\"z3_reconstructed_theorems\":2,\"negative_controls\":3,\"code_bytes\":67910,\"data_words\":354,\"claim\":\"compiler-output qualification; NOT MetaRocq E2E refinement\"}\n");
val _ = TextIO.closeOut out;
