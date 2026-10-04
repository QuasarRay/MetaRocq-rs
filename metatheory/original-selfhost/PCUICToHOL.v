From Stdlib Require Import String List.
From MetaRocqRs.OriginalSelfHost Require Import
  OpenTheoryIR HOLProofIR SelfSnapshot SelfHostRunner.

Import ListNotations.
Open Scope string_scope.

Module PCUICToHOL.

Record lowering_inventory := {
  inventory_modules : nat;
  inventory_globals : nat;
  inventory_expected_theorems : nat
}.

Definition snapshot_global_count
  (snapshots : list SelfSnapshot.module_snapshot) : nat :=
  fold_left
    (fun acc m => acc + List.length m.(SelfSnapshot.snapshot_globals))
    snapshots
    0.

Definition inventory
  (snapshots : list SelfSnapshot.module_snapshot)
  (expected_theorems : nat) : lowering_inventory :=
  {| inventory_modules := List.length snapshots;
     inventory_globals := snapshot_global_count snapshots;
     inventory_expected_theorems := expected_theorems |}.

(* This is the only boundary allowed to turn quoted PCUIC proof material into
   HOL/OpenTheory proofs.  The complete implementation must be proof-producing:
   every returned [export_theorem] contains a HOL kernel derivation, and every
   unsupported PCUIC construct blocks the entire self-verification run.

   Keeping this definition inside the extracted program prevents CI or an
   external translator from silently supplying a precomputed proof bundle. *)
Definition lower_complete_metatheory
  (snapshots : list SelfSnapshot.module_snapshot)
  : OpenTheoryIR.lowering_result SelfHostRunner.translation_bundle :=
  OpenTheoryIR.Unsupported
    "PCUIC-to-HOL proof lowering is not complete for the full MetaRocq metatheory".

End PCUICToHOL.
