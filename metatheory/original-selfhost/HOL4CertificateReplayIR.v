From Stdlib Require Import String List Bool.
From MetaRocqRs.OriginalSelfHost Require Import PCUICCertificateIR.

Import ListNotations.

Inductive hol4_certificate_replay_stage :=
| HOL4EncodePCUICPrelude
| HOL4EncodeCertificateStatement
| HOL4EncodeCertificateProof
| HOL4ExecuteSafeChecker
| HOL4ReconstructKernelTheorem
| HOL4CheckStatementIdentity
| HOL4CheckAssumptionLedger
| HOL4KernelCheckTheorem.

Record hol4_certificate_replay_job := {
  hol4_replay_certificate : pcuic_theorem_certificate;
  hol4_replay_stages : list hol4_certificate_replay_stage
}.

Definition hol4_certificate_replay_stages : list hol4_certificate_replay_stage :=
  [HOL4EncodePCUICPrelude;
   HOL4EncodeCertificateStatement;
   HOL4EncodeCertificateProof;
   HOL4ExecuteSafeChecker;
   HOL4ReconstructKernelTheorem;
   HOL4CheckStatementIdentity;
   HOL4CheckAssumptionLedger;
   HOL4KernelCheckTheorem].

Definition hol4_replay_job_of_certificate
  (c : pcuic_theorem_certificate) : hol4_certificate_replay_job :=
  {| hol4_replay_certificate := c;
     hol4_replay_stages := hol4_certificate_replay_stages |}.

Definition original_hol4_replay_jobs : list hol4_certificate_replay_job :=
  List.map hol4_replay_job_of_certificate original_pcuic_certificate_corpus.

Theorem hol4_replay_jobs_cover_certificate_corpus :
  List.length original_hol4_replay_jobs = certificate_corpus_size.
Proof.
  unfold original_hol4_replay_jobs, certificate_corpus_size.
  now rewrite map_length.
Qed.
