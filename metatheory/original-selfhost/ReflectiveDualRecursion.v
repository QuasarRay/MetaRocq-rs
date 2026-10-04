From Stdlib Require Import String List Bool Arith.
From MetaRocqRs.OriginalSelfHost Require Import
  RecursiveTrustGraph DualProofLedger.

Open Scope string_scope.

Record reflective_dual_evidence := {
  reflective_dual_proof : dual_proof_evidence;
  reflective_recursive_trust : recursive_trust_evidence;
  reflective_recursion_code_in_pcuic_corpus : bool;
  reflective_recursion_exported_by_candle : bool
}.

Definition reflective_dual_verified
  (e : reflective_dual_evidence) : bool :=
  dual_proof_publishable e.(reflective_dual_proof)
  && verify_claim 7 RecursiveSelfImage e.(reflective_recursive_trust)
  && e.(reflective_recursion_code_in_pcuic_corpus)
  && e.(reflective_recursion_exported_by_candle).

Theorem recursion_missing_from_pcuic_blocks_self_verification :
  forall dual trust candle,
    reflective_dual_verified
      {| reflective_dual_proof := dual;
         reflective_recursive_trust := trust;
         reflective_recursion_code_in_pcuic_corpus := false;
         reflective_recursion_exported_by_candle := candle |} = false.
Proof.
  intros.
  unfold reflective_dual_verified.
  destruct (dual_proof_publishable dual);
    destruct (verify_claim 7 RecursiveSelfImage trust); reflexivity.
Qed.

Theorem recursion_missing_from_candle_blocks_self_verification :
  forall dual trust pcuic,
    reflective_dual_verified
      {| reflective_dual_proof := dual;
         reflective_recursive_trust := trust;
         reflective_recursion_code_in_pcuic_corpus := pcuic;
         reflective_recursion_exported_by_candle := false |} = false.
Proof.
  intros.
  unfold reflective_dual_verified.
  destruct (dual_proof_publishable dual);
    destruct (verify_claim 7 RecursiveSelfImage trust);
    destruct pcuic; reflexivity.
Qed.
