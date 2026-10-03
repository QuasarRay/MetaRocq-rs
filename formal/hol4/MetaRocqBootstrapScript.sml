(* Tool qualification only; this is not a model or theorem of PCUIC. *)
open HolKernel boolLib bossLib integerTheory;
val _ = new_theory "MetaRocqBootstrap";

Theorem z3_identity:
  !x:int. x + 0 = x
Proof
  HolSmtLib.Z3_TAC
QED

(* Check the exported theorem's oracle tag as well as its hypotheses.
   Standard HOL axioms are still part of the foundational trust base. *)
val (oracles, _) = Tag.dest_tag (Thm.tag z3_identity);
val _ = if null oracles andalso null (Thm.hyp z3_identity) then ()
        else raise Fail "Z3 smoke theorem contains oracle tags or hypotheses";
val _ = export_theory();
