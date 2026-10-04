From Stdlib Require Import String List Bool Arith.
From MetaRocqRs.OriginalSelfHost Require Import
  PCUICCertificateIR HOL4MachineRefinement.

Import ListNotations.
Open Scope string_scope.

Record hol4_certificate_job := {
  hol4_job_source : pcuic_theorem_certificate;
  hol4_job_requires_pcuic_checker : bool;
  hol4_job_requires_forward_hol_encoding : bool;
  hol4_job_requires_hol4_kernel_check : bool;
  hol4_job_requires_source_lambdabox_refinement : bool;
  hol4_job_requires_machine_refinement : bool
}.

Definition hol4_certificate_job_of
  (c : pcuic_theorem_certificate) : hol4_certificate_job :=
  {| hol4_job_source := c;
     hol4_job_requires_pcuic_checker := true;
     hol4_job_requires_forward_hol_encoding := true;
     hol4_job_requires_hol4_kernel_check := true;
     hol4_job_requires_source_lambdabox_refinement := true;
     hol4_job_requires_machine_refinement := true |}.

Definition original_hol4_certificate_ledger : list hol4_certificate_job :=
  List.map hol4_certificate_job_of original_pcuic_certificate_corpus.

Record hol4_certificate_evidence := {
  hol4_certificate_pcuic_checker_accepted : bool;
  hol4_certificate_forward_encoding_proved : bool;
  hol4_certificate_kernel_evidence : hol4_kernel_evidence;
  hol4_certificate_statement_correspondence : bool;
  hol4_certificate_assumption_correspondence : bool;
  hol4_certificate_machine_refinement : hol4_machine_refinement_evidence
}.

Definition accept_hol4_certificate_evidence
  (e : hol4_certificate_evidence) : bool :=
  e.(hol4_certificate_pcuic_checker_accepted)
  && e.(hol4_certificate_forward_encoding_proved)
  && hol4_kernel_evidence_complete e.(hol4_certificate_kernel_evidence)
  && e.(hol4_certificate_statement_correspondence)
  && e.(hol4_certificate_assumption_correspondence)
  && hol4_machine_refinement_complete e.(hol4_certificate_machine_refinement).

Theorem hol4_ledger_covers_every_certificate :
  List.length original_hol4_certificate_ledger = certificate_corpus_size.
Proof.
  unfold original_hol4_certificate_ledger, certificate_corpus_size.
  now rewrite map_length.
Qed.

Theorem missing_hol4_side_blocks_certificate :
  forall pcuic forward stmt assumptions machine,
    accept_hol4_certificate_evidence
      {| hol4_certificate_pcuic_checker_accepted := pcuic;
         hol4_certificate_forward_encoding_proved := forward;
         hol4_certificate_kernel_evidence := unresolved_hol4_kernel_evidence;
         hol4_certificate_statement_correspondence := stmt;
         hol4_certificate_assumption_correspondence := assumptions;
         hol4_certificate_machine_refinement := machine |} = false.
Proof.
  intros.
  unfold accept_hol4_certificate_evidence, hol4_kernel_evidence_complete.
  destruct pcuic, forward; reflexivity.
Qed.
