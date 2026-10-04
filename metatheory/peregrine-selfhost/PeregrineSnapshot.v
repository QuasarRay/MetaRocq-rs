From MetaRocq.TemplatePCUIC Require Import Loader.
From MetaRocqRs.OriginalSelfHost Require Import SelfSnapshot.
From MetaRocqRs.PeregrineSelfHost Require Import
  PeregrineSourceManifest PeregrineLoadAll.

Import MonadNotation.

Definition quote_pinned_peregrine
  : TemplateMonad (list SelfSnapshot.module_snapshot) :=
  SelfSnapshot.quote_modules PeregrineSourceManifest.peregrine_modules.

Definition materialize_pinned_peregrine : TemplateMonad unit :=
  snapshots <- quote_pinned_peregrine ;;
  MetaRocq.Template.TemplateMonad.Core.tmDefinition
    "peregrine_source_snapshot"%bs snapshots.
