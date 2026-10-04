From Stdlib Require Import String List Bool Arith.
From MetaRocqRs.OriginalSelfHost Require Import
  HOL4ReuseManifest PCUICCertificateIR.

Import ListNotations.
Open Scope string_scope.

Inductive round_trip_stage :=
| RTPCUICSource
| RTOpenTheoryExport
| RTHolideTranslate
| RTLambdapiCheck
| RTRocqKernelCheck
| RTMetaRocqRequote
| RTComparePCUIC.

Definition existing_reverse_bridge : list round_trip_stage :=
  [RTOpenTheoryExport;
   RTHolideTranslate;
   RTLambdapiCheck;
   RTRocqKernelCheck;
   RTMetaRocqRequote].

Record pcuic_round_trip_evidence := {
  rt_source_certificate_count : nat;
  rt_opentheory_article_checked : bool;
  rt_dedukti_independently_checked : bool;
  rt_rocq_kernel_checked : bool;
  rt_pcuic_requoted : bool;
  rt_statement_identity_preserved : bool;
  rt_assumption_ledger_preserved : bool;
  rt_no_new_axioms : bool
}.

Definition pcuic_round_trip_evidence_complete
  (e : pcuic_round_trip_evidence) : bool :=
  negb (Nat.eqb e.(rt_source_certificate_count) 0)
  && e.(rt_opentheory_article_checked)
  && e.(rt_dedukti_independently_checked)
  && e.(rt_rocq_kernel_checked)
  && e.(rt_pcuic_requoted)
  && e.(rt_statement_identity_preserved)
  && e.(rt_assumption_ledger_preserved)
  && e.(rt_no_new_axioms).

Record hol4_reuse_policy := {
  reuse_existing_reverse_bridge : bool;
  reuse_smoke_as_tool_qualification_only : bool;
  forbid_duplicate_hol4_import_pipeline : bool;
  require_pcuic_round_trip_before_publication : bool
}.

Definition selfhost_hol4_reuse_policy : hol4_reuse_policy :=
  {| reuse_existing_reverse_bridge := true;
     reuse_smoke_as_tool_qualification_only := true;
     forbid_duplicate_hol4_import_pipeline := true;
     require_pcuic_round_trip_before_publication := true |}.

Definition hol4_reuse_policy_ok : bool :=
  selfhost_hol4_reuse_policy.(reuse_existing_reverse_bridge)
  && selfhost_hol4_reuse_policy.(reuse_smoke_as_tool_qualification_only)
  && selfhost_hol4_reuse_policy.(forbid_duplicate_hol4_import_pipeline)
  && selfhost_hol4_reuse_policy.(require_pcuic_round_trip_before_publication)
  && reuse_manifest_well_formed.

Theorem hol4_reuse_policy_is_fail_closed :
  hol4_reuse_policy_ok = true.
Proof. reflexivity. Qed.

Theorem missing_requote_blocks_round_trip :
  forall n art dk rocq stmt assumptions axioms,
    pcuic_round_trip_evidence_complete
      {| rt_source_certificate_count := n;
         rt_opentheory_article_checked := art;
         rt_dedukti_independently_checked := dk;
         rt_rocq_kernel_checked := rocq;
         rt_pcuic_requoted := false;
         rt_statement_identity_preserved := stmt;
         rt_assumption_ledger_preserved := assumptions;
         rt_no_new_axioms := axioms |} = false.
Proof.
  intros.
  unfold pcuic_round_trip_evidence_complete.
  destruct (Nat.eqb n 0), art, dk, rocq; reflexivity.
Qed.

Theorem changed_assumption_ledger_blocks_round_trip :
  forall n art dk rocq requote stmt axioms,
    pcuic_round_trip_evidence_complete
      {| rt_source_certificate_count := n;
         rt_opentheory_article_checked := art;
         rt_dedukti_independently_checked := dk;
         rt_rocq_kernel_checked := rocq;
         rt_pcuic_requoted := requote;
         rt_statement_identity_preserved := stmt;
         rt_assumption_ledger_preserved := false;
         rt_no_new_axioms := axioms |} = false.
Proof.
  intros.
  unfold pcuic_round_trip_evidence_complete.
  destruct (Nat.eqb n 0), art, dk, rocq, requote, stmt; reflexivity.
Qed.
