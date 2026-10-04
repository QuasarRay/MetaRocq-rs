open HolKernel boolLib bossLib integerTheory;
val _ = new_theory "MetaRocqMigrationSmoke";

(* Reuse the already-qualified Aegis HOL4/Z3 reconstruction pattern as a
   concrete proof object for exercising the migration backbone.  This is a
   qualification theorem, not the MetaRocq-rs metatheory. *)
val goal = ``!x y:int. (2*x <= 2*y /\ y < x+1) ==> (x = y)``;
val reconstructed = prove (goal, HolSmtLib.Z3_TAC);

fun acceptable expected th =
  let val (oracles, axioms) = Tag.dest_tag (Thm.tag th)
  in null (Thm.hyp th) andalso aconv (Thm.concl th) expected
     andalso List.all (fn name => name = "DISK_THM") oracles
     andalso null axioms
  end;

val _ = if acceptable goal reconstructed then ()
        else raise Fail "migration seed failed scope/tag inspection";
val _ = if acceptable goal (mk_oracle_thm "RejectedProbe" ([], goal))
        orelse acceptable goal (ASSUME goal)
        then raise Fail "migration seed accepted contaminated proof" else ();

val _ = save_thm ("integer_interval", reconstructed);
val _ = export_theory();
