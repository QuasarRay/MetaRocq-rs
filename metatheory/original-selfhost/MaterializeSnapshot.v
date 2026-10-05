From MetaRocqRs.OriginalSelfHost Require Import SelfSnapshot.

MetaRocq Run SelfSnapshot.materialize_pinned_pcuic_metatheory.

Definition snapshot_module_count : nat :=
  List.length original_pcuic_metatheory_snapshot.
