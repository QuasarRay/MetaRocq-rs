From Stdlib Require Import Bool List.
From MetaRocq.Common Require Import config.
From MetaRocq.Template Require Import Loader Checker.
From MetaRocq.Template Require Import TemplateMonad.
From MetaRocq.Utils Require Import utils.
From Peregrine Require Import Pipeline.
From MetaRocqRs.PeregrineSelfHost Require Import PeregrineProofCorpus.
From MetaRocqRs.PeregrineGenerated Require Import PeregrineReplayAllGlobals.

Import MonadNotation.

(*
  Non-canonical executable replay glue.

  The runtime replay object quotes an unreduced root referencing every
  declaration emitted by tmQuoteModule for the complete pinned module manifest.
  Bypass opacity so proof bodies and their dependencies survive as program data.

  MetaRocq.Template.Checker is deliberately used here only as an executable
  replay engine. Upstream documents that checker as fuel-bounded and
  unverified; therefore success here is never treated as the final semantic
  proof. The later HOL4 source-to-machine gate remains authoritative.
*)
Definition quote_peregrine_runtime_replay_program :=
  MetaRocq.Template.TemplateMonad.Core.tmQuoteRecTransp
    PeregrineReplayAllGlobals.peregrine_all_declarations_root true.

Definition materialize_peregrine_runtime_replay_program : TemplateMonad unit :=
  MetaRocq.Template.TemplateMonad.Core.tmBind
    quote_peregrine_runtime_replay_program
    (fun p =>
       MetaRocq.Template.TemplateMonad.Core.tmBind
         (MetaRocq.Template.TemplateMonad.Core.tmDefinition
            "peregrine_runtime_replay_program"%bs p)
         (fun _ => MetaRocq.Template.TemplateMonad.Core.tmReturn tt)).

MetaRocq Run materialize_peregrine_runtime_replay_program.

Definition replay_program_contains_certificate
  (c : peregrine_theorem_certificate) : bool :=
  match MetaRocq.Template.Ast.Env.lookup_env
          (fst peregrine_runtime_replay_program)
          c.(peregrine_certificate_name) with
  | Some (MetaRocq.Template.Ast.Env.ConstantDecl body) =>
      match body.(MetaRocq.Template.Ast.Env.cst_body) with
      | Some _ => true
      | None => false
      end
  | _ => false
  end.

Definition replay_covers_retained_certificate_corpus : bool :=
  negb (Nat.eqb (List.length peregrine_certificate_corpus) 0) &&
  forallb replay_program_contains_certificate peregrine_certificate_corpus.

(* Evaluate the actual quoted data, including opacity bypass. This prevents a
   reduced unit root, omitted opaque proof, or empty corpus from passing merely
   because the root-materialization receipt exists. *)
Example replay_corpus_has_all_retained_bodies :
  replay_covers_retained_certificate_corpus = true.
Proof. vm_compute. reflexivity. Qed.

Definition replay_peregrine_runtime_program : bool :=
  replay_covers_retained_certificate_corpus &&
  match
    @MetaRocq.Template.Checker.typecheck_program
      config.default_checker_flags
      MetaRocq.Template.Checker.default_fuel
      peregrine_runtime_replay_program
  with
  | MetaRocq.Template.Checker.CorrectDecl _ => true
  | MetaRocq.Template.Checker.EnvError _ => false
  end.
