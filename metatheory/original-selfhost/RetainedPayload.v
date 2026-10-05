From Stdlib Require Import String List Bool.
From MetaRocqRs.OriginalSelfHost Require Import
  OpenTheoryIR SelfSnapshot MaterializeSnapshot PCUICModuleManifest.

Import ListNotations.
Open Scope string_scope.

Record retained_proof_payload := {
  retained_pcuic_snapshot : list SelfSnapshot.module_snapshot;
  retained_opentheory_articles :
    OpenTheoryIR.lowering_result (list OpenTheoryIR.article);
  retained_replay_required : bool
}.

(* This is deliberately blocked until the proof-producing PCUIC -> HOL lowering
   exists.  The complete PCUIC snapshot is nevertheless retained in the
   executable data graph so erasure cannot discard the self-reflection input. *)
Definition current_opentheory_payload :
  OpenTheoryIR.lowering_result (list OpenTheoryIR.article) :=
  OpenTheoryIR.Unsupported
    "PCUIC-to-HOL/OpenTheory proof lowering is not yet semantically discharged".

Definition original_selfhost_payload : retained_proof_payload :=
  {| retained_pcuic_snapshot := original_pcuic_metatheory_snapshot;
     retained_opentheory_articles := current_opentheory_payload;
     retained_replay_required := true |}.

Definition snapshot_count_matches_manifest : bool :=
  Nat.eqb
    (List.length original_selfhost_payload.(retained_pcuic_snapshot))
    PCUICModuleManifest.expected_module_count.

Definition proof_payload_publishable : bool :=
  match original_selfhost_payload.(retained_opentheory_articles) with
  | OpenTheoryIR.Lowered _ => snapshot_count_matches_manifest
  | OpenTheoryIR.Unsupported _ => false
  end.
