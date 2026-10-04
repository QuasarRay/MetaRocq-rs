open HolKernel boolLib bossLib;

val _ = new_theory "PeregrineSelfHostContract";

(* Qualification/fail-closed contract only. This is intentionally not the
   missing Peregrine source-to-machine theorem. *)
val incomplete_goal =
  ``!source replay cakeml machine:bool.
      ~(source /\\ replay /\\ cakeml /\\ machine /\\ F)``;

val incomplete_thm = prove (incomplete_goal, rw []);

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
  if clean incomplete_goal incomplete_thm then ()
  else raise Fail "Peregrine selfhost fail-closed qualification theorem contaminated";

val _ = incomplete_thm |> check_thm;
val _ = save_thm ("peregrine_selfhost_incomplete_rejected", incomplete_thm);
val _ = export_theory();
