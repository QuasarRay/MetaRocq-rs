From Stdlib Require Import String List Bool.
From MetaRocqRs.OriginalSelfHost Require Import
  DualProofLedger RecursiveSelfIdentity.

Record reflective_dual_evidence := {
  reflective_certificate_dual : certificate_dual_evidence;
  reflective_recursive_identity : recursive_identity;
  reflective_recursion_code_in_pcuic_corpus : bool;
  reflective_recursion_exported_by_candle : bool
}.

Definition reflective_dual_verified
  (e : reflective_dual_evidence) : bool :=
  accept_certificate_dual_evidence e.(reflective_certificate_dual)
  && accept_recursive_identity e.(reflective_recursive_identity)
  && e.(reflective_recursion_code_in_pcuic_corpus)
  && e.(reflective_recursion_exported_by_candle).

Theorem recursion_missing_from_pcuic_blocks_self_verification :
  forall dual identity candle,
    reflective_dual_verified
      {| reflective_certificate_dual := dual;
         reflective_recursive_identity := identity;
         reflective_recursion_code_in_pcuic_corpus := false;
         reflective_recursion_exported_by_candle := candle |} = false.
Proof.
  intros.
  unfold reflective_dual_verified.
  destruct (accept_certificate_dual_evidence dual);
    destruct (accept_recursive_identity identity); reflexivity.
Qed.

Theorem recursion_missing_from_candle_blocks_self_verification :
  forall dual identity pcuic,
    reflective_dual_verified
      {| reflective_certificate_dual := dual;
         reflective_recursive_identity := identity;
         reflective_recursion_code_in_pcuic_corpus := pcuic;
         reflective_recursion_exported_by_candle := false |} = false.
Proof.
  intros.
  unfold reflective_dual_verified.
  destruct (accept_certificate_dual_evidence dual);
    destruct (accept_recursive_identity identity);
    destruct pcuic; reflexivity.
Qed.
