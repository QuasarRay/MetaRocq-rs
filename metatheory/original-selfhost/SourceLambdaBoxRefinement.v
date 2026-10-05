From Stdlib Require Import String Bool.

Open Scope string_scope.

Record source_lambdabox_evidence := {
  source_snapshot_digest : string;
  lambdabox_digest : string;
  source_snapshot_matches_pinned_modules : bool;
  source_quotation_complete : bool;
  metarocq_erasure_correctness_instantiated : bool;
  extracted_root_is_self_reflective : bool;
  source_lambdabox_semantics_preserved : bool;
  source_lambdabox_round_trip_bound : bool;
  source_lambdabox_no_untracked_axioms : bool
}.

Definition digest_present (s : string) : bool :=
  negb (String.eqb s EmptyString).

Definition source_lambdabox_evidence_complete
  (e : source_lambdabox_evidence) : bool :=
  digest_present e.(source_snapshot_digest)
  && digest_present e.(lambdabox_digest)
  && e.(source_snapshot_matches_pinned_modules)
  && e.(source_quotation_complete)
  && e.(metarocq_erasure_correctness_instantiated)
  && e.(extracted_root_is_self_reflective)
  && e.(source_lambdabox_semantics_preserved)
  && e.(source_lambdabox_round_trip_bound)
  && e.(source_lambdabox_no_untracked_axioms).

Definition unresolved_source_lambdabox_evidence : source_lambdabox_evidence :=
  {| source_snapshot_digest := "";
     lambdabox_digest := "";
     source_snapshot_matches_pinned_modules := false;
     source_quotation_complete := false;
     metarocq_erasure_correctness_instantiated := false;
     extracted_root_is_self_reflective := false;
     source_lambdabox_semantics_preserved := false;
     source_lambdabox_round_trip_bound := false;
     source_lambdabox_no_untracked_axioms := true |}.

Theorem missing_erasure_refinement_blocks_source_lambdabox :
  forall sd ld snapshot quoted root sem rt axioms,
    source_lambdabox_evidence_complete
      {| source_snapshot_digest := sd;
         lambdabox_digest := ld;
         source_snapshot_matches_pinned_modules := snapshot;
         source_quotation_complete := quoted;
         metarocq_erasure_correctness_instantiated := false;
         extracted_root_is_self_reflective := root;
         source_lambdabox_semantics_preserved := sem;
         source_lambdabox_round_trip_bound := rt;
         source_lambdabox_no_untracked_axioms := axioms |} = false.
Proof.
  intros.
  unfold source_lambdabox_evidence_complete.
  destruct (digest_present sd), (digest_present ld), snapshot, quoted; reflexivity.
Qed.
