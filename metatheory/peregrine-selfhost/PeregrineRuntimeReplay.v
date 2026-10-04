From Stdlib Require Import Bool.
From MetaRocq.Common Require Import config.
From MetaRocq.Template Require Import Loader Checker.
From Peregrine Require Import Pipeline.

Import MonadNotation.

(*
  Non-canonical executable replay glue.

  The runtime replay object is a dependency-closed quotation of Peregrine's
  pipeline before erasure. Bypass opacity so retained proof bodies and their
  dependencies are present in the quoted program.

  MetaRocq.Template.Checker is deliberately used here only as an executable
  replay engine. Upstream documents that checker as fuel-bounded and
  unverified; therefore success here is never treated as the final semantic
  proof. The later HOL4 source-to-machine gate remains authoritative.
*)
Definition quote_peregrine_runtime_replay_program :=
  MetaRocq.Template.TemplateMonad.Core.tmQuoteRecTransp
    Peregrine.Pipeline.peregrine_pipeline true.

Definition materialize_peregrine_runtime_replay_program : TemplateMonad unit :=
  p <- quote_peregrine_runtime_replay_program ;;
  MetaRocq.Template.TemplateMonad.Core.tmDefinition
    "peregrine_runtime_replay_program"%bs p.

MetaRocq Run materialize_peregrine_runtime_replay_program.

Definition replay_peregrine_runtime_program : bool :=
  match
    @MetaRocq.Template.Checker.typecheck_program
      config.default_checker_flags
      MetaRocq.Template.Checker.default_fuel
      peregrine_runtime_replay_program
  with
  | MetaRocq.Template.Checker.CorrectDecl _ => true
  | MetaRocq.Template.Checker.EnvError _ => false
  end.
