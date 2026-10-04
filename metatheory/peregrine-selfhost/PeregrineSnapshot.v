From MetaRocq.TemplatePCUIC Require Import Loader.
From MetaRocq.Template Require Import TemplateMonad.
From MetaRocq.Utils Require Import utils.
From MetaRocqRs.OriginalSelfHost Require Import SelfSnapshot.
From MetaRocqRs.PeregrineSelfHost Require Import
  PeregrineSourceManifest PeregrineLoadAll.

Import MonadNotation.

Definition quote_pinned_peregrine
  : TemplateMonad (list SelfSnapshot.module_snapshot) :=
  SelfSnapshot.quote_modules PeregrineSourceManifest.peregrine_modules.

Definition materialize_pinned_peregrine : TemplateMonad unit :=
  MetaRocq.Template.TemplateMonad.Core.tmBind
    quote_pinned_peregrine
    (fun snapshots =>
       MetaRocq.Template.TemplateMonad.Core.tmBind
         (MetaRocq.Template.TemplateMonad.Core.tmDefinition
            "peregrine_source_snapshot"%bs snapshots)
         (fun _ => MetaRocq.Template.TemplateMonad.Core.tmReturn tt)).
