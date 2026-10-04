From Stdlib Require Import String List Bool.

Import ListNotations.
Open Scope string_scope.

Inductive reuse_kind :=
| ReuseHOL4Theory
| ReusePCUICPolicy
| ReuseCakeMLReplayGate
| ReuseArchitectureDecision.

Record reuse_asset := {
  reuse_path : string;
  reuse_blob_sha : string;
  reuse_kind_of : reuse_kind;
  reuse_role : string
}.

Definition inherited_hol4_assets : list reuse_asset :=
  [ {| reuse_path := "formal/hol4/MetaRocqMigrationSmokeScript.sml";
       reuse_blob_sha := "8c50844ff10f1f225bb765194e10c265291c2294";
       reuse_kind_of := ReuseHOL4Theory;
       reuse_role :=
         "existing HOL4/OpenTheory qualification theorem; reuse rather than recreate" |};
    {| reuse_path := "spec/pcuic-first-metatheory.json";
       reuse_blob_sha := "2b5021b0d24edc72d8e1862584a6cefc91fccb31";
       reuse_kind_of := ReusePCUICPolicy;
       reuse_role :=
         "existing PCUIC-first migration policy and pinned CakeML identity" |};
    {| reuse_path := "tools/original_cakeml_replay_gate.py";
       reuse_blob_sha := "e50235a40c7ba1e86c82a7f9a36985397fbd4733";
       reuse_kind_of := ReuseCakeMLReplayGate;
       reuse_role :=
         "existing fail-closed CakeML replay diagnostics; transport only" |};
    {| reuse_path := "docs/adr/0007-pcuic-first-migration-and-cakeml-replay.md";
       reuse_blob_sha := "c8679ef1cf7ac0230b44e38b06de68a502f7030a";
       reuse_kind_of := ReuseArchitectureDecision;
       reuse_role :=
         "existing architecture decision defining PCUIC as canonical migrated representation" |}
  ].

Definition expected_reuse_asset_count : nat := 4.

Definition reuse_manifest_well_formed : bool :=
  Nat.eqb (List.length inherited_hol4_assets) expected_reuse_asset_count.
