(* Distributed under the terms of the MIT license.
   The contract is the pinned MetaRocq PCUIC judgment, not a replacement AST.
   This module deliberately does not import SafeCheckerPlugin.Extraction. *)
From MetaRocq.Utils Require Import utils.
From MetaRocq.Common Require Import config.
From MetaRocq.PCUIC Require Import PCUICAst PCUICTyping PCUICSN BDToPCUIC.
From MetaRocq.SafeChecker Require Import
  PCUICErrors PCUICWfEnv PCUICWfEnvImpl PCUICSafeChecker.

Section OriginalChecker.
  Context {cf : checker_flags} {nor : normalizing_flags}.
  Context {guard_implementation : abstract_guard_impl}.

  (* This is an explicit argument, not a new axiom or an opaque admitted
     instance. A complete executable must supply normalization and a guard
     implementation satisfying guard_correct. The theorem does not do so. *)
  Context (normalize : forall Sigma : global_env_ext,
    wf_ext Sigma -> NormalizationIn Sigma).

  Definition original_check (p : program) (universes : universes_decl) :=
    @typecheck_program cf nor optimized_abstract_env_impl p universes
      (fun _ _ _ _ _ _ Sigma wellformed _ => normalize Sigma wellformed)
      (fun _ _ Sigma wellformed _ => normalize Sigma wellformed).

  (* Keep the computed type in Type. Only the existing dependent certificate
     is projected away; acceptance is the actual upstream checker's result. *)
  Definition checker (p : program) (universes : universes_decl) : option term :=
    match original_check p universes with
    | CorrectDecl certificate => Some certificate.π1
    | EnvError _ _ => None
    end.

  Theorem checker_acceptance_sound (p : program) (universes : universes_decl) A :
    checker p universes = Some A ->
    ∥ wf_ext (p.1, universes) × (p.1, universes) ;;; [] |- p.2 : A ∥.
  Proof.
    unfold checker.
    destruct (original_check p universes) as [[inferred [environment certificate]] | environment error].
    - cbn. intros accepted. inversion accepted; subst inferred.
      destruct certificate as [[related [wellformed derivation]]].
      constructor. split; [exact wellformed |].
      eapply infering_typing; [exact wellformed.1 | constructor | exact derivation].
    - discriminate.
  Qed.
End OriginalChecker.

(* The complete kernel-reported assumptions and the parameterized statement
   are captured verbatim by tools/replay_original_checker.py. *)
Print checker_acceptance_sound.
Print Assumptions checker_acceptance_sound.
