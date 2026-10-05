From Stdlib Require Import String List Bool.

Import ListNotations.
Open Scope string_scope.

Inductive hol4_kernel_requirement :=
| HOL4KernelBuiltFromPinnedSource
| HOL4KernelTheoremObjectChecked
| HOL4NoUnexpectedOracles
| HOL4NoUnexpectedAxioms
| HOL4StatementIdentityChecked
| HOL4AssumptionLedgerChecked.

Definition pinned_hol4_revision : string :=
  "40dd5b03de658f4bd9e3f4225fb0f1602ac90467".

Record hol4_kernel_evidence := {
  hol4_kernel_pinned_source_built : bool;
  hol4_kernel_theorem_object_checked : bool;
  hol4_kernel_no_unexpected_oracles : bool;
  hol4_kernel_no_unexpected_axioms : bool;
  hol4_kernel_statement_identity_checked : bool;
  hol4_kernel_assumption_ledger_checked : bool
}.

Definition hol4_kernel_evidence_complete (e : hol4_kernel_evidence) : bool :=
  e.(hol4_kernel_pinned_source_built)
  && e.(hol4_kernel_theorem_object_checked)
  && e.(hol4_kernel_no_unexpected_oracles)
  && e.(hol4_kernel_no_unexpected_axioms)
  && e.(hol4_kernel_statement_identity_checked)
  && e.(hol4_kernel_assumption_ledger_checked).

Definition unresolved_hol4_kernel_evidence : hol4_kernel_evidence :=
  {| hol4_kernel_pinned_source_built := false;
     hol4_kernel_theorem_object_checked := false;
     hol4_kernel_no_unexpected_oracles := false;
     hol4_kernel_no_unexpected_axioms := false;
     hol4_kernel_statement_identity_checked := false;
     hol4_kernel_assumption_ledger_checked := false |}.

Theorem missing_hol4_kernel_check_blocks_acceptance :
  forall built oracles axioms stmt assumptions,
    hol4_kernel_evidence_complete
      {| hol4_kernel_pinned_source_built := built;
         hol4_kernel_theorem_object_checked := false;
         hol4_kernel_no_unexpected_oracles := oracles;
         hol4_kernel_no_unexpected_axioms := axioms;
         hol4_kernel_statement_identity_checked := stmt;
         hol4_kernel_assumption_ledger_checked := assumptions |} = false.
Proof.
  intros.
  unfold hol4_kernel_evidence_complete.
  destruct built; reflexivity.
Qed.
