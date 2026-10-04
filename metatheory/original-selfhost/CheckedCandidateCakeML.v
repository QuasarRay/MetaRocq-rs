From Stdlib Require Import String List Bool.
From MetaRocq.Utils Require Import ResultMonad bytestring.
From Peregrine Require Import PAst.
From CakeML.Backend Require Import Compile.
From MetaRocqRs.OriginalSelfHost Require Import
  EmbeddedPeregrine CandidateCakeMLCompiler
  EAstSupportedFragment CakeMLNoRaise.

Import MonadNotation.
Local Open Scope bs_scope.

Definition checked_candidate_compile_past
  (p : PAst) : result' candidate_cakeml_ast :=
  ep <- PAst_to_EAst p ;;
  if east_program_supported ep then
    let out := Compile.compile_program ep in
    if candidate_cakeml_no_raise out
    then Ok out
    else Err "generated CakeML contains a Raise node"%bs
  else Err "EAst program is outside the checked CakeML fragment"%bs.

Definition prepare_and_checked_compile
  (attrs : list string) (source : string)
  : result' candidate_cakeml_ast :=
  p <- prepare_cakeml attrs source ;;
  checked_candidate_compile_past p.

Lemma checked_candidate_compile_past_sound
  (p : PAst) (out : candidate_cakeml_ast) :
  checked_candidate_compile_past p = Ok out ->
  exists ep,
    PAst_to_EAst p = Ok ep
    /\ east_program_supported ep = true
    /\ out = Compile.compile_program ep
    /\ candidate_cakeml_no_raise out = true.
Proof.
  unfold checked_candidate_compile_past.
  destruct (PAst_to_EAst p) as [ep|err] eqn:Hep; cbn; try discriminate.
  destruct (east_program_supported ep) eqn:Hsupported; cbn; try discriminate.
  remember (Compile.compile_program ep) as compiled eqn:Hcompiled.
  destruct (candidate_cakeml_no_raise compiled) eqn:Hraise; cbn; try discriminate.
  intros H.
  inversion H; subst.
  exists ep.
  repeat split; auto.
Qed.

Lemma prepare_and_checked_compile_no_raise
  (attrs : list string) (source : string)
  (out : candidate_cakeml_ast) :
  prepare_and_checked_compile attrs source = Ok out ->
  candidate_cakeml_no_raise out = true.
Proof.
  unfold prepare_and_checked_compile.
  destruct (prepare_cakeml attrs source) as [p|err] eqn:Hprepare;
    cbn; try discriminate.
  intros Hcompile.
  destruct (checked_candidate_compile_past_sound p out Hcompile)
    as [ep [Hep [Hsupported [Hout Hraise]]]].
  exact Hraise.
Qed.

Lemma prepare_and_checked_compile_supported
  (attrs : list string) (source : string)
  (out : candidate_cakeml_ast) :
  prepare_and_checked_compile attrs source = Ok out ->
  exists p ep,
    prepare_cakeml attrs source = Ok p
    /\ PAst_to_EAst p = Ok ep
    /\ east_program_supported ep = true
    /\ out = Compile.compile_program ep.
Proof.
  unfold prepare_and_checked_compile.
  destruct (prepare_cakeml attrs source) as [p|err] eqn:Hprepare;
    cbn; try discriminate.
  intros Hcompile.
  destruct (checked_candidate_compile_past_sound p out Hcompile)
    as [ep [Hep [Hsupported [Hout Hraise]]]].
  exists p, ep.
  repeat split; auto.
Qed.
