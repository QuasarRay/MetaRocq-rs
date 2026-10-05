open HolKernel boolLib bossLib;

val _ = new_theory "MetaRocqSelfHostKernel";

(* Kernel qualification only. The end-to-end MetaRocq theorem is generated
   separately from the exact CakeML program and must pass check_thm before
   the publication gate can open. *)
val kernel_goal = ``!p:bool. p ==> p``;
val kernel_thm = prove (kernel_goal, rw []);

fun clean expected th =
  let
    val (oracles, axioms) = Tag.dest_tag (Thm.tag th)
  in
    null (Thm.hyp th) andalso
    aconv (Thm.concl th) expected andalso
    null oracles andalso
    null axioms
  end;

val _ =
  if clean kernel_goal kernel_thm then ()
  else raise Fail "HOL4 kernel qualification theorem is contaminated";

val _ = kernel_thm |> check_thm;
val _ = save_thm ("kernel_qualified", kernel_thm);
val _ = export_theory();
