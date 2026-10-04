From Stdlib Require Import String List Bool Arith.

Import ListNotations.
Open Scope string_scope.

Inductive hol4_reuse_asset_kind :=
| HOL4BootstrapQualification
| HOL4MigrationSmoke
| HOL4OpenTheoryCore
| HOL4CheckedTranslator
| HOL4PCUICHarvester
| OriginalCakeMLReplayGate
| HOL4BridgeLock
| HOL4ImportedQuoteTemplate.

Record hol4_reuse_asset := {
  hol4_asset_kind : hol4_reuse_asset_kind;
  hol4_asset_path : string;
  hol4_asset_blob_sha1 : string;
  hol4_asset_role : string;
  hol4_asset_is_semantic_equivalence_proof : bool
}.

Definition hol4_bootstrap_asset : hol4_reuse_asset :=
  {| hol4_asset_kind := HOL4BootstrapQualification;
     hol4_asset_path := "formal/hol4/MetaRocqBootstrapScript.sml";
     hol4_asset_blob_sha1 := "f049e59d96e873866adf8f4eb7c68f3e09bcb2a5";
     hol4_asset_role :=
       "HOL4/Z3 adapter qualification only; explicitly not a PCUIC theorem";
     hol4_asset_is_semantic_equivalence_proof := false |}.

Definition hol4_smoke_asset : hol4_reuse_asset :=
  {| hol4_asset_kind := HOL4MigrationSmoke;
     hol4_asset_path := "formal/hol4/MetaRocqMigrationSmokeScript.sml";
     hol4_asset_blob_sha1 := "8c50844ff10f1f225bb765194e10c265291c2294";
     hol4_asset_role :=
       "kernel theorem used to qualify HOL4 OpenTheory migration";
     hol4_asset_is_semantic_equivalence_proof := false |}.

Definition hol4_core_asset : hol4_reuse_asset :=
  {| hol4_asset_kind := HOL4OpenTheoryCore;
     hol4_asset_path := "tools/hol4_pcuic_core.py";
     hol4_asset_blob_sha1 := "ead3b1c54e1eebd3021599725a82f260c60c8002";
     hol4_asset_role :=
       "pinned source identity, confinement, HOL4 build and official OpenTheory export";
     hol4_asset_is_semantic_equivalence_proof := false |}.

Definition hol4_translate_asset : hol4_reuse_asset :=
  {| hol4_asset_kind := HOL4CheckedTranslator;
     hol4_asset_path := "tools/hol4_pcuic_translate.py";
     hol4_asset_blob_sha1 := "ef8fde4f9a953f8789e50a905d7117ab3dfaca0c";
     hol4_asset_role :=
       "OpenTheory to Holide/Dedukti, independent Lambdapi check, Rocq export and kernel check";
     hol4_asset_is_semantic_equivalence_proof := false |}.

Definition hol4_harvest_asset : hol4_reuse_asset :=
  {| hol4_asset_kind := HOL4PCUICHarvester;
     hol4_asset_path := "tools/harvest_hol4_pcuic.py";
     hol4_asset_blob_sha1 := "3daec8784322bcec9754c5fe875d332b394454ea";
     hol4_asset_role :=
       "re-quote checked imported Rocq theorem to canonical PCUIC program";
     hol4_asset_is_semantic_equivalence_proof := false |}.

Definition original_cakeml_gate_asset : hol4_reuse_asset :=
  {| hol4_asset_kind := OriginalCakeMLReplayGate;
     hol4_asset_path := "tools/original_cakeml_replay_gate.py";
     hol4_asset_blob_sha1 := "e50235a40c7ba1e86c82a7f9a36985397fbd4733";
     hol4_asset_role :=
       "existing fail-closed diagnostic gate for Original-MetaRocq CakeML replay";
     hol4_asset_is_semantic_equivalence_proof := false |}.

Definition hol4_lock_asset : hol4_reuse_asset :=
  {| hol4_asset_kind := HOL4BridgeLock;
     hol4_asset_path := "spec/hol4-opentheory-pcuic.lock.json";
     hol4_asset_blob_sha1 := "5953a7ea19b98d91c0f69b5fa3d7d2df1494d063";
     hol4_asset_role :=
       "immutable HOL4/Holide/Lambdapi/coq-hol-light/MetaRocq source identities";
     hol4_asset_is_semantic_equivalence_proof := false |}.

Definition hol4_quote_template_asset : hol4_reuse_asset :=
  {| hol4_asset_kind := HOL4ImportedQuoteTemplate;
     hol4_asset_path := "metatheory/bootstrap/Hol4ImportedQuote.v.in";
     hol4_asset_blob_sha1 := "71829bc048bc397651a951840818b1c230e441ef";
     hol4_asset_role :=
       "MetaRocq recursive quotation of a Rocq-kernel-checked imported theorem";
     hol4_asset_is_semantic_equivalence_proof := false |}.

Definition inherited_hol4_reuse_assets : list hol4_reuse_asset :=
  [hol4_bootstrap_asset;
   hol4_smoke_asset;
   hol4_core_asset;
   hol4_translate_asset;
   hol4_harvest_asset;
   original_cakeml_gate_asset;
   hol4_lock_asset;
   hol4_quote_template_asset].

Definition inherited_hol4_asset_count_ok : bool :=
  Nat.eqb (List.length inherited_hol4_reuse_assets) 8.

Definition no_reused_asset_claims_semantic_equivalence : bool :=
  forallb
    (fun a => negb a.(hol4_asset_is_semantic_equivalence_proof))
    inherited_hol4_reuse_assets.

Theorem inherited_hol4_reuse_contract_is_conservative :
  inherited_hol4_asset_count_ok = true /\
  no_reused_asset_claims_semantic_equivalence = true.
Proof. split; reflexivity. Qed.
