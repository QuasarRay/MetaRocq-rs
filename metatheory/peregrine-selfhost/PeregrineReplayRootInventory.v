From MetaRocq.Utils Require Import utils.
From MetaRocqRs.OriginalSelfHost Require Import DeclarationReplayInventory.
From MetaRocqRs.PeregrineSelfHost Require Import
  PeregrineSourceManifest PeregrineLoadAll.

(* Preserve the established Peregrine inventory protocol and reuse the
   Rocq declaration enumerator for the larger original-source bundle. *)
Definition peregrine_inventory_markers : replay_inventory_markers :=
  {| inventory_module_marker := "PEREGRINE_REPLAY_MODULE ";
     inventory_root_marker := "PEREGRINE_REPLAY_ROOT ";
     inventory_done_marker := "PEREGRINE_REPLAY_MODULE_DONE ";
     inventory_complete_marker := "PEREGRINE_REPLAY_COMPLETE";
     inventory_classify_bodies := false |}.

MetaRocq Run (emit_declaration_inventory peregrine_inventory_markers
  PeregrineSourceManifest.peregrine_modules).
