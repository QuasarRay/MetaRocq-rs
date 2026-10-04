From Stdlib Require Import String List Bool Arith.
From MetaRocqRs.OriginalSelfHost Require Import
  PCUICCertificateIR CandleExportContract.

Import ListNotations.
Open Scope string_scope.

Record semantic_claim := {
  claim_id : string;
  claim_pcuic_anchor : string;
  claim_candle_anchor : string;
  claim_machine_code_relevant : bool
}.

Record dual_evidence := {
  dual_pcuic_proved : bool;
  dual_candle_proved : bool;
  dual_machine_transport_proved : bool;
  dual_no_untracked_axiom : bool
}.

Definition accept_dual_claim
  (c : semantic_claim) (e : dual_evidence) : bool :=
  e.(dual_pcuic_proved)
  && e.(dual_candle_proved)
  && e.(dual_no_untracked_axiom)
  && if c.(claim_machine_code_relevant)
     then e.(dual_machine_transport_proved)
     else true.

Definition selfhost_claims : list semantic_claim :=
  [ {| claim_id := "pcuic-metatheory";
       claim_pcuic_anchor := "MetaRocq.PCUIC";
       claim_candle_anchor := "OpenTheory/PCUIC metatheory article set";
       claim_machine_code_relevant := true |};
    {| claim_id := "reflection-runtime";
       claim_pcuic_anchor := "OriginalSelfHost.SelfHostRunner";
       claim_candle_anchor := "OpenTheory/self-reflection-runtime";
       claim_machine_code_relevant := true |};
    {| claim_id := "erasure-retention";
       claim_pcuic_anchor := "OriginalSelfHost.RetainedPayload";
       claim_candle_anchor := "OpenTheory/retained-payload";
       claim_machine_code_relevant := true |};
    {| claim_id := "self-ci-pipeline";
       claim_pcuic_anchor := "OriginalSelfHost.SelfCICD";
       claim_candle_anchor := "OpenTheory/self-ci-pipeline";
       claim_machine_code_relevant := true |}
  ].

Definition empty_dual_evidence : dual_evidence :=
  {| dual_pcuic_proved := false;
     dual_candle_proved := false;
     dual_machine_transport_proved := false;
     dual_no_untracked_axiom := true |}.

Fixpoint all_dual_claims_accepted
  (claims : list semantic_claim)
  (evidence : list dual_evidence) : bool :=
  match claims, evidence with
  | [], [] => true
  | c :: cs, e :: es =>
      accept_dual_claim c e && all_dual_claims_accepted cs es
  | _, _ => false
  end.

(* The semantic-claim ledger above remains the compact architecture-level API.
   This second ledger refines the PCUIC metatheory claim to one job per exact
   quoted proof-bearing constant. *)
Record certificate_dual_job := {
  certificate_dual_source : pcuic_theorem_certificate;
  certificate_requires_pcuic_checker : bool;
  certificate_requires_hol_lowering : bool;
  certificate_requires_candle_export : bool;
  certificate_requires_machine_binding : bool
}.

Definition certificate_dual_job_of
  (c : pcuic_theorem_certificate) : certificate_dual_job :=
  {| certificate_dual_source := c;
     certificate_requires_pcuic_checker := true;
     certificate_requires_hol_lowering := true;
     certificate_requires_candle_export := true;
     certificate_requires_machine_binding := true |}.

Definition original_certificate_dual_ledger : list certificate_dual_job :=
  List.map certificate_dual_job_of original_pcuic_certificate_corpus.

Record certificate_dual_evidence := {
  certificate_pcuic_checker_accepted : bool;
  certificate_forward_lowering_proved : bool;
  certificate_opentheory_reader_accepted : bool;
  certificate_candle_export_evidence : candle_export_evidence;
  certificate_statement_correspondence_proved : bool;
  certificate_assumption_correspondence_proved : bool;
  certificate_machine_image_identity_bound : bool
}.

Definition accept_certificate_dual_evidence
  (e : certificate_dual_evidence) : bool :=
  e.(certificate_pcuic_checker_accepted)
  && e.(certificate_forward_lowering_proved)
  && e.(certificate_opentheory_reader_accepted)
  && candle_export_evidence_complete e.(certificate_candle_export_evidence)
  && e.(certificate_statement_correspondence_proved)
  && e.(certificate_assumption_correspondence_proved)
  && e.(certificate_machine_image_identity_bound).

Theorem certificate_dual_ledger_covers_every_certificate :
  List.length original_certificate_dual_ledger = certificate_corpus_size.
Proof.
  unfold original_certificate_dual_ledger, certificate_corpus_size.
  now rewrite map_length.
Qed.

Theorem missing_certificate_pcuic_side_blocks_publication :
  forall lower ot candle stmt assumptions machine,
    accept_certificate_dual_evidence
      {| certificate_pcuic_checker_accepted := false;
         certificate_forward_lowering_proved := lower;
         certificate_opentheory_reader_accepted := ot;
         certificate_candle_export_evidence := candle;
         certificate_statement_correspondence_proved := stmt;
         certificate_assumption_correspondence_proved := assumptions;
         certificate_machine_image_identity_bound := machine |} = false.
Proof. intros; reflexivity. Qed.

Theorem changed_certificate_statement_blocks_publication :
  forall pcuic lower ot candle assumptions machine,
    accept_certificate_dual_evidence
      {| certificate_pcuic_checker_accepted := pcuic;
         certificate_forward_lowering_proved := lower;
         certificate_opentheory_reader_accepted := ot;
         certificate_candle_export_evidence := candle;
         certificate_statement_correspondence_proved := false;
         certificate_assumption_correspondence_proved := assumptions;
         certificate_machine_image_identity_bound := machine |} = false.
Proof.
  intros.
  unfold accept_certificate_dual_evidence.
  destruct pcuic, lower, ot;
    destruct (candle_export_evidence_complete candle); reflexivity.
Qed.
