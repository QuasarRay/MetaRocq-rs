From Stdlib Require Import List.
From MetaRocq.TemplatePCUIC Require Import Loader.
From MetaRocq.Template Require Import TemplateMonad.
From MetaRocq.PCUIC Require Import PCUICAst PCUICProgram.
From MetaRocq.Common Require Import Kernames.
From MetaRocq.Utils Require Import utils.
From MetaRocqRs.OriginalSelfHost Require Import PCUICModuleManifest.

Import ListNotations MonadNotation.

Module SelfSnapshot.

Inductive quoted_global :=
| SnapshotConstant
    (name : kername)
    (body : constant_body)
| SnapshotInductive
    (name : kername)
    (body : mutual_inductive_body)
| SnapshotVariable
    (name : ident).

Record module_snapshot := {
  snapshot_module_name : qualid;
  snapshot_globals : list quoted_global
}.

Definition quote_global (r : global_reference)
  : TemplateMonad quoted_global :=
  match r with
  | VarRef id =>
      tmReturn (SnapshotVariable id)
  | ConstRef kn =>
      body <- MetaRocq.TemplatePCUIC.PCUICTemplateMonad.Core.tmQuoteConstant
                kn true ;;
      tmReturn (SnapshotConstant kn body)
  | IndRef ind =>
      body <- MetaRocq.TemplatePCUIC.PCUICTemplateMonad.Core.tmQuoteInductive
                ind.(inductive_mind) ;;
      tmReturn (SnapshotInductive ind.(inductive_mind) body)
  | ConstructRef ind _ =>
      body <- MetaRocq.TemplatePCUIC.PCUICTemplateMonad.Core.tmQuoteInductive
                ind.(inductive_mind) ;;
      tmReturn (SnapshotInductive ind.(inductive_mind) body)
  end.

Fixpoint quote_globals (rs : list global_reference)
  : TemplateMonad (list quoted_global) :=
  match rs with
  | [] => tmReturn []
  | r :: rs =>
      q <- quote_global r ;;
      qs <- quote_globals rs ;;
      tmReturn (q :: qs)
  end.

Definition quote_module (q : qualid)
  : TemplateMonad module_snapshot :=
  refs <- MetaRocq.Template.TemplateMonad.Core.tmQuoteModule q ;;
  globals <- quote_globals refs ;;
  tmReturn {| snapshot_module_name := q;
              snapshot_globals := globals |}.

Fixpoint quote_modules (qs : list qualid)
  : TemplateMonad (list module_snapshot) :=
  match qs with
  | [] => tmReturn []
  | q :: qs =>
      m <- quote_module q ;;
      ms <- quote_modules qs ;;
      tmReturn (m :: ms)
  end.

Definition quote_pinned_pcuic_metatheory
  : TemplateMonad (list module_snapshot) :=
  quote_modules PCUICModuleManifest.pcuic_metatheory_modules.

Definition materialize_pinned_pcuic_metatheory : TemplateMonad unit :=
  snapshots <- quote_pinned_pcuic_metatheory ;;
  MetaRocq.Template.TemplateMonad.Core.tmDefinition
    "original_pcuic_metatheory_snapshot"%bs snapshots.

End SelfSnapshot.
