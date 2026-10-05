From Stdlib Require Import String List Bool Arith.
From MetaRocqRs.OriginalSelfHost Require Import
  PCUICCertificateIR PCUICDeepEmbeddingSchema SafeCheckerContract.

Import ListNotations.
Open Scope string_scope.

Inductive certificate_replay_stage :=
| EncodePCUICPrelude
| EncodeCertificateStatement
| EncodeCertificateProof
| ExecuteSafeChecker
| ReconstructHOLAcceptance
| ReplayOpenTheoryInCandle.

Record certificate_replay_job := {
  replay_certificate : pcuic_theorem_certificate;
  replay_stages : list certificate_replay_stage
}.

Definition certificate_replay_stages : list certificate_replay_stage :=
  [EncodePCUICPrelude;
   EncodeCertificateStatement;
   EncodeCertificateProof;
   ExecuteSafeChecker;
   ReconstructHOLAcceptance;
   ReplayOpenTheoryInCandle].

Definition replay_job_of_certificate
  (c : pcuic_theorem_certificate) : certificate_replay_job :=
  {| replay_certificate := c;
     replay_stages := certificate_replay_stages |}.

Definition original_pcuic_replay_jobs : list certificate_replay_job :=
  List.map replay_job_of_certificate original_pcuic_certificate_corpus.

Record checker_bridge_evidence := {
  bridge_hol_prelude : hol_prelude_evidence;
  bridge_normalization_discharged_or_declared : bool;
  bridge_guard_discharged : bool;
  bridge_source_assumptions_accounted : bool;
  bridge_candle_reader_machine_theorem : bool
}.

Definition checker_bridge_ready (e : checker_bridge_evidence) : bool :=
  hol_prelude_evidence_complete e.(bridge_hol_prelude)
  && e.(bridge_normalization_discharged_or_declared)
  && e.(bridge_guard_discharged)
  && e.(bridge_source_assumptions_accounted)
  && e.(bridge_candle_reader_machine_theorem).

Definition replay_corpus_publishable (e : checker_bridge_evidence) : bool :=
  checker_bridge_ready e
  && negb (Nat.eqb (List.length original_pcuic_replay_jobs) 0).

Theorem missing_checker_soundness_blocks_corpus :
  forall termt ctxt env univ prim ctor distinct inj typ red cum rt faithful
         norm guard assumptions candle,
    replay_corpus_publishable
      {| bridge_hol_prelude :=
           {| prelude_term_type := termt;
              prelude_context_type := ctxt;
              prelude_global_env_type := env;
              prelude_universe_types := univ;
              prelude_primitive_types := prim;
              prelude_term_constructors := ctor;
              prelude_constructor_distinctness := distinct;
              prelude_constructor_injectivity := inj;
              prelude_typing_relation := typ;
              prelude_reduction_relation := red;
              prelude_cumulativity_relation := cum;
              prelude_round_trip := rt;
              prelude_checker_faithful := faithful;
              prelude_checker_sound := false |};
         bridge_normalization_discharged_or_declared := norm;
         bridge_guard_discharged := guard;
         bridge_source_assumptions_accounted := assumptions;
         bridge_candle_reader_machine_theorem := candle |} = false.
Proof.
  intros.
  unfold replay_corpus_publishable, checker_bridge_ready,
    hol_prelude_evidence_complete.
  destruct termt, ctxt, env, univ, prim, ctor, distinct, inj, typ, red, cum,
    rt, faithful; reflexivity.
Qed.
