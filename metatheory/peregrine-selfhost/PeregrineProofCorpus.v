From Stdlib Require Import String List Bool Arith.
From MetaRocq.PCUIC Require Import PCUICAst.
From MetaRocqRs.OriginalSelfHost Require Import SelfSnapshot.
From MetaRocqRs.PeregrineSelfHost Require Import MaterializePeregrineSnapshot.

Import ListNotations.
Open Scope string_scope.

Record peregrine_theorem_certificate := {
  peregrine_certificate_name : kername;
  peregrine_certificate_statement : term;
  peregrine_certificate_proof : term
}.

Record peregrine_source_assumption := {
  peregrine_assumption_name : kername;
  peregrine_assumption_statement : term
}.

Definition certificates_of_global
  (g : SelfSnapshot.quoted_global) : list peregrine_theorem_certificate :=
  match g with
  | SelfSnapshot.SnapshotConstant name body =>
      match body.(cst_body) with
      | Some proof =>
          [{| peregrine_certificate_name := name;
              peregrine_certificate_statement := body.(cst_type);
              peregrine_certificate_proof := proof |}]
      | None => []
      end
  | _ => []
  end.

Definition assumptions_of_global
  (g : SelfSnapshot.quoted_global) : list peregrine_source_assumption :=
  match g with
  | SelfSnapshot.SnapshotConstant name body =>
      match body.(cst_body) with
      | Some _ => []
      | None =>
          [{| peregrine_assumption_name := name;
              peregrine_assumption_statement := body.(cst_type) |}]
      end
  | _ => []
  end.

Definition certificates_of_module
  (m : SelfSnapshot.module_snapshot) : list peregrine_theorem_certificate :=
  flat_map certificates_of_global m.(SelfSnapshot.snapshot_globals).

Definition assumptions_of_module
  (m : SelfSnapshot.module_snapshot) : list peregrine_source_assumption :=
  flat_map assumptions_of_global m.(SelfSnapshot.snapshot_globals).

Definition peregrine_certificate_corpus : list peregrine_theorem_certificate :=
  flat_map certificates_of_module peregrine_source_snapshot.

Definition peregrine_assumption_ledger : list peregrine_source_assumption :=
  flat_map assumptions_of_module peregrine_source_snapshot.

Record peregrine_replay_job := {
  replay_source : peregrine_theorem_certificate;
  replay_requires_pcuic_safechecker : bool;
  replay_requires_hol4_kernel : bool;
  replay_requires_machine_binding : bool
}.

Definition replay_job_of
  (c : peregrine_theorem_certificate) : peregrine_replay_job :=
  {| replay_source := c;
     replay_requires_pcuic_safechecker := true;
     replay_requires_hol4_kernel := true;
     replay_requires_machine_binding := true |}.

Definition peregrine_replay_jobs : list peregrine_replay_job :=
  List.map replay_job_of peregrine_certificate_corpus.

Record peregrine_replay_evidence := {
  replay_pcuic_safechecker_accepted : bool;
  replay_hol4_kernel_accepted : bool;
  replay_statement_correspondence : bool;
  replay_assumption_correspondence : bool;
  replay_machine_refinement_bound : bool
}.

Definition accept_replay_evidence (e : peregrine_replay_evidence) : bool :=
  e.(replay_pcuic_safechecker_accepted)
  && e.(replay_hol4_kernel_accepted)
  && e.(replay_statement_correspondence)
  && e.(replay_assumption_correspondence)
  && e.(replay_machine_refinement_bound).

Fixpoint accept_replay_corpus
  (jobs : list peregrine_replay_job)
  (evidence : list peregrine_replay_evidence) : bool :=
  match jobs, evidence with
  | [], [] => true
  | _ :: jobs', e :: evidence' =>
      accept_replay_evidence e && accept_replay_corpus jobs' evidence'
  | _, _ => false
  end.

Definition accept_peregrine_replay_corpus
  (evidence : list peregrine_replay_evidence) : bool :=
  accept_replay_corpus peregrine_replay_jobs evidence.

Definition peregrine_certificate_corpus_size : nat :=
  List.length peregrine_certificate_corpus.

Definition peregrine_assumption_ledger_size : nat :=
  List.length peregrine_assumption_ledger.

Theorem replay_ledger_covers_certificate_corpus :
  List.length peregrine_replay_jobs = peregrine_certificate_corpus_size.
Proof.
  unfold peregrine_replay_jobs, peregrine_certificate_corpus_size.
  now rewrite map_length.
Qed.

Theorem unresolved_replay_evidence_rejected :
  forall p h s a m,
    h = false ->
    accept_replay_evidence
      {| replay_pcuic_safechecker_accepted := p;
         replay_hol4_kernel_accepted := h;
         replay_statement_correspondence := s;
         replay_assumption_correspondence := a;
         replay_machine_refinement_bound := m |} = false.
Proof.
  intros p h s a m ->.
  unfold accept_replay_evidence.
  destruct p; reflexivity.
Qed.
