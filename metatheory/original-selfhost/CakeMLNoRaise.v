From Stdlib Require Import String List Bool.
From CakeML Require Import ast.
From MetaRocqRs.OriginalSelfHost Require Import CandidateCakeMLCompiler.

Import ListNotations.

Fixpoint cake_exp_no_raise (e : exp) : bool :=
  match e with
  | Lit _ => true
  | Raise _ => false
  | Handle body handlers =>
      cake_exp_no_raise body
      && forallb (fun h => cake_exp_no_raise (snd h)) handlers
  | Con _ args =>
      forallb cake_exp_no_raise args
  | Var _ => true
  | App _ args =>
      forallb cake_exp_no_raise args
  | Fun _ body =>
      cake_exp_no_raise body
  | Let _ def body =>
      cake_exp_no_raise def && cake_exp_no_raise body
  | Mat discr branches =>
      cake_exp_no_raise discr
      && forallb (fun br => cake_exp_no_raise (snd br)) branches
  | Letrec defs body =>
      forallb
        (fun d =>
           let '(_, _, rhs) := d in cake_exp_no_raise rhs)
        defs
      && cake_exp_no_raise body
  end.

Fixpoint cake_env_no_raise
  (env : list (string * option exp)) : bool :=
  match env with
  | [] => true
  | (_, None) :: rest =>
      cake_env_no_raise rest
  | (_, Some rhs) :: rest =>
      cake_exp_no_raise rhs && cake_env_no_raise rest
  end.

Definition candidate_cakeml_no_raise
  (p : candidate_cakeml_ast) : bool :=
  cake_env_no_raise (fst p) && cake_exp_no_raise (snd p).
