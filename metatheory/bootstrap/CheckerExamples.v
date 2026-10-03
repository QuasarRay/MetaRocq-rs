(* Regression statements about the actual checker. These remain universally
   conditional on the explicit guard and normalization arguments. *)
From MetaRocq.Utils Require Import utils.
From MetaRocq.Common Require Import config.
From MetaRocq.PCUIC Require Import PCUICAst PCUICTyping PCUICSN.
From MetaRocq.SafeChecker Require Import PCUICWfEnvImpl.
From MetaRocqRs.Bootstrap Require Import OriginalChecker.

Definition checked_universes : @normalizing_flags default_checker_flags.
Proof. constructor. reflexivity. Defined.

Definition regression_environment : global_env :=
  {| universes := (LevelSet.singleton Level.lzero, ConstraintSet.empty);
     declarations := [];
     retroknowledge := Retroknowledge.empty |}.

Section Examples.
  Context (certified_guard : abstract_guard_impl).
  Context (normalize : forall Sigma : global_env_ext,
    @wf_ext default_checker_flags Sigma ->
    @NormalizationIn default_checker_flags checked_universes Sigma).

  Let run := @checker default_checker_flags checked_universes certified_guard normalize.

  Example accepts_prop :
    run (regression_environment, tSort sProp) Monomorphic_ctx =
      Some (tSort (Sort.super sProp)).
  Proof. vm_compute. reflexivity. Qed.

  Example rejects_unbound_rel :
    run (regression_environment, tRel 0) Monomorphic_ctx = None.
  Proof. vm_compute. reflexivity. Qed.

  Example rejects_missing_constant :
    run (regression_environment, tConst (MPfile [], "missing") []) Monomorphic_ctx = None.
  Proof. vm_compute. reflexivity. Qed.

  Example rejects_missing_set_universe :
    run (empty_global_env, tSort sProp) Monomorphic_ctx = None.
  Proof. vm_compute. reflexivity. Qed.

  (* A deliberately incorrect acceptance claim must not be provable by the
     computation used for the positive example. Fail does not add an axiom. *)
  Goal run (regression_environment, tRel 0) Monomorphic_ctx = Some (tSort sProp).
    Fail solve [vm_compute; reflexivity].
  Abort.
End Examples.

Print Assumptions accepts_prop.
Print Assumptions rejects_unbound_rel.
Print Assumptions rejects_missing_constant.
Print Assumptions rejects_missing_set_universe.
