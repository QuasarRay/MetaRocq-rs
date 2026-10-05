From Stdlib Require Import List.
From MetaRocq.Utils Require Import utils.
From MetaRocq.Common Require Import Kernames.
From MetaRocq.Template Require Import Loader TemplateMonad.
From MetaRocqRs.PeregrineSelfHost Require Import
  PeregrineSourceManifest PeregrineLoadAll.

(* The source of the root list is Rocq's loaded module environment, not a
   regexp over theorem declarations. Constructor references target their
   mutual inductive declaration. Open variables block the
   build; they are never dropped from a claimed closed source corpus. *)
Definition emit_replay_root (r : global_reference) : TemplateMonad unit :=
  match r with
  | ConstRef kn =>
      tmMsg ("PEREGRINE_REPLAY_ROOT CONST " ^ string_of_kername kn)
  | IndRef ind =>
      tmMsg ("PEREGRINE_REPLAY_ROOT IND " ^
        string_of_kername ind.(inductive_mind))
  | ConstructRef ind _ =>
      tmMsg ("PEREGRINE_REPLAY_ROOT IND " ^
        string_of_kername ind.(inductive_mind))
  | VarRef id => tmFail ("Open source variable in proof corpus: " ^ id)
  end.

Fixpoint emit_replay_roots (rs : list global_reference)
  : TemplateMonad unit :=
  match rs with
  | nil => tmReturn tt
  | r :: rs => tmBind (emit_replay_root r) (fun _ => emit_replay_roots rs)
  end.

Definition emit_replay_module (q : qualid) : TemplateMonad unit :=
  tmBind (tmMsg ("PEREGRINE_REPLAY_MODULE " ^ q))
    (fun _ => tmBind (tmQuoteModule q)
      (fun rs => tmBind (emit_replay_roots rs)
        (fun _ => tmMsg ("PEREGRINE_REPLAY_MODULE_DONE " ^ q ^ " " ^
          string_of_nat (List.length rs))))).

Fixpoint emit_replay_modules (qs : list qualid) : TemplateMonad unit :=
  match qs with
  | nil => tmReturn tt
  | q :: qs => tmBind (emit_replay_module q) (fun _ => emit_replay_modules qs)
  end.

MetaRocq Run
  (tmBind (emit_replay_modules PeregrineSourceManifest.peregrine_modules)
    (fun _ => tmMsg "PEREGRINE_REPLAY_COMPLETE")).
