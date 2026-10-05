From Stdlib Require Import List.
From MetaRocqRs.PeregrineSelfHost Require Import PeregrineSnapshot.

MetaRocq Run materialize_pinned_peregrine.

Definition peregrine_snapshot_module_count : nat :=
  List.length peregrine_source_snapshot.
