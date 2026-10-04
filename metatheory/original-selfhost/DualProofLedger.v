From Stdlib Require Import String List Bool Arith.
From MetaRocqRs.OriginalSelfHost Require Import
  PCUICCertificateIR CandleExportContract.

Import ListNotations.
Open Scope string_scope.

Record dual_proof_job := {
  dual_source_certificate : pcuic_theorem_certificate;
  dual_requires_pcuic_checker : bool;
  dual_requires_hol_lowering : bool;
  dual_requires_candle_export : bool;
  dual_requires_machine_code_binding : bool
}.

Definition dual_proof_job_of_certificate
  (c : pcuic_theorem_certificate) : dual_proof_job :=
  {| dual_source_certificate := c;
     dual_requires_pcuic_checker := true;
     dual_requires_hol_lowering := true;
     dual_requires_candle_export := true;
     dual_requires_machine_code_binding := true |}.

Definition original_dual_proof_ledger : list dual_proof_job :=
  List.map dual_proof_job_of_certificate original_pcuic_certificate_corpus.

Record dual_proof_evidence := {
  dual_pcuic_checker_accepted : bool;
  dual_forward_lowering_proved : bool;
  dual_opentheory_reader_accepted : bool;
  dual_candle_export_evidence : candle_export_evidence;
  dual_statement_correspondence_proved : bool;
  dual_assumption_correspondence_proved : bool;
  dual_machine_image_identity_bound : bool
}.

Definition dual_proof_publishable (e : dual_proof_evidence) : bool :=
  e.(dual_pcuic_checker_accepted)
  && e.(dual_forward_lowering_proved)
  && e.(dual_opentheory_reader_accepted)
  && candle_export_evidence_complete e.(dual_candle_export_evidence)
  && e.(dual_statement_correspondence_proved)
  && e.(dual_assumption_correspondence_proved)
  && e.(dual_machine_image_identity_bound).

Theorem dual_ledger_covers_every_certificate :
  List.length original_dual_proof_ledger = certificate_corpus_size.
Proof.
  unfold original_dual_proof_ledger, certificate_corpus_size.
  now rewrite map_length.
Qed.

Theorem missing_pcuic_side_blocks_publication :
  forall lower ot candle stmt assumptions machine,
    dual_proof_publishable
      {| dual_pcuic_checker_accepted := false;
         dual_forward_lowering_proved := lower;
         dual_opentheory_reader_accepted := ot;
         dual_candle_export_evidence := candle;
         dual_statement_correspondence_proved := stmt;
         dual_assumption_correspondence_proved := assumptions;
         dual_machine_image_identity_bound := machine |} = false.
Proof. intros; reflexivity. Qed.

Theorem missing_candle_side_blocks_publication :
  forall pcuic lower ot prefix residual compiler channel reader stmt assumptions machine,
    dual_proof_publishable
      {| dual_pcuic_checker_accepted := pcuic;
         dual_forward_lowering_proved := lower;
         dual_opentheory_reader_accepted := ot;
         dual_candle_export_evidence :=
           {| candle_prefix_soundness_proved := prefix;
              candle_residual_reasonable_proved := residual;
              candle_compiler_transport_proved := compiler;
              candle_export_channel_kernel_controlled := channel;
              candle_reader_machine_code_proved := false |};
         dual_statement_correspondence_proved := stmt;
         dual_assumption_correspondence_proved := assumptions;
         dual_machine_image_identity_bound := machine |} = false.
Proof.
  intros.
  unfold dual_proof_publishable, candle_export_evidence_complete.
  destruct pcuic, lower, ot, prefix, residual, compiler, channel; reflexivity.
Qed.

Theorem changed_statement_blocks_publication :
  forall pcuic lower ot candle assumptions machine,
    dual_proof_publishable
      {| dual_pcuic_checker_accepted := pcuic;
         dual_forward_lowering_proved := lower;
         dual_opentheory_reader_accepted := ot;
         dual_candle_export_evidence := candle;
         dual_statement_correspondence_proved := false;
         dual_assumption_correspondence_proved := assumptions;
         dual_machine_image_identity_bound := machine |} = false.
Proof.
  intros.
  unfold dual_proof_publishable.
  destruct pcuic, lower, ot;
    destruct (candle_export_evidence_complete candle); reflexivity.
Qed.
