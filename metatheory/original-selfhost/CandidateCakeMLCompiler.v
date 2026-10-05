From Stdlib Require Import String List.
From ExtLib Require Import Monads.
From MetaRocq.Utils Require Import ResultMonad.
From Peregrine Require Import PAst.
From CakeML Require Import ast.
From CakeML.Backend Require Import Compile.

Import MonadNotation.
Local Open Scope monad.

Definition candidate_cakeml_ast : Type :=
  list (string * option exp) * exp.

(* Pure syntax producer only.  This deliberately bypasses
   Peregrine.CakeMLBackend.cakeml_pipeline, its Admitted obligation,
   assume_can_be_extracted and both trust_coq_kernel axioms. *)
Definition candidate_compile_cakeml_ast
  (p : PAst) : result' candidate_cakeml_ast :=
  ep <- PAst_to_EAst p ;;
  Ok (Compile.compile_program ep).
