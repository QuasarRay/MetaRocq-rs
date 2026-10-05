From MetaRocq.Utils Require Import utils.
From MetaRocqRs.OriginalSelfHost Require Import DeclarationReplayInventory.
From MetaRocqRs.UnifiedGenerated Require Import UnifiedModuleManifest UnifiedLoadAll.

(* Every mapped module is loaded. Bodies are classified by Rocq's quotation,
   not by searching proof scripts. A missing module or open variable fails. *)
Definition unified_inventory_markers : replay_inventory_markers :=
  {| inventory_module_marker := "UNIFIED_REPLAY_MODULE ";
     inventory_root_marker := "UNIFIED_REPLAY_ROOT ";
     inventory_done_marker := "UNIFIED_REPLAY_MODULE_DONE ";
     inventory_complete_marker := "UNIFIED_REPLAY_COMPLETE";
     inventory_classify_bodies := true |}.

MetaRocq Run (emit_declaration_inventory unified_inventory_markers
  UnifiedModuleManifest.unified_modules).
