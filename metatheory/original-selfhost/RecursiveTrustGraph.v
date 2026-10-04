From Stdlib Require Import String List Bool Arith PeanoNat.

Import ListNotations.
Open Scope string_scope.

Inductive trust_claim :=
| RecursiveSelfImage
| PCUICSelfTheory
| HOLLoweringDerivation
| CandleArticleAcceptance
| VerifiedCakeMLCompilation
| InstalledMachineImage
| BootstrapSeed.

Definition trust_rank (c : trust_claim) : nat :=
  match c with
  | RecursiveSelfImage => 6
  | PCUICSelfTheory => 5
  | HOLLoweringDerivation => 4
  | CandleArticleAcceptance => 3
  | VerifiedCakeMLCompilation => 2
  | InstalledMachineImage => 1
  | BootstrapSeed => 0
  end.

Record trust_edge := {
  edge_claim : trust_claim;
  edge_verifier : trust_claim
}.

Definition trust_edges : list trust_edge :=
  [{| edge_claim := RecursiveSelfImage; edge_verifier := PCUICSelfTheory |};
   {| edge_claim := PCUICSelfTheory; edge_verifier := HOLLoweringDerivation |};
   {| edge_claim := HOLLoweringDerivation; edge_verifier := CandleArticleAcceptance |};
   {| edge_claim := CandleArticleAcceptance; edge_verifier := VerifiedCakeMLCompilation |};
   {| edge_claim := VerifiedCakeMLCompilation; edge_verifier := InstalledMachineImage |};
   {| edge_claim := InstalledMachineImage; edge_verifier := BootstrapSeed |}].

Definition edge_strictly_decreases (e : trust_edge) : bool :=
  Nat.ltb (trust_rank e.(edge_verifier)) (trust_rank e.(edge_claim)).

Definition trust_graph_well_founded : bool :=
  forallb edge_strictly_decreases trust_edges.

Theorem trust_graph_is_strictly_decreasing :
  trust_graph_well_founded = true.
Proof. reflexivity. Qed.

Record recursive_trust_evidence := {
  ev_pcuic_self : bool;
  ev_hol_lowering : bool;
  ev_candle_acceptance : bool;
  ev_cakeml_compilation : bool;
  ev_source_identity : bool;
  ev_binary_identity : bool;
  ev_bootstrap_seed : bool
}.

Fixpoint verify_claim
  (fuel : nat) (claim : trust_claim) (ev : recursive_trust_evidence) : bool :=
  match fuel with
  | O => false
  | S fuel' =>
      match claim with
      | RecursiveSelfImage =>
          ev.(ev_source_identity) &&
          ev.(ev_binary_identity) &&
          verify_claim fuel' PCUICSelfTheory ev
      | PCUICSelfTheory =>
          ev.(ev_pcuic_self) &&
          ev.(ev_source_identity) &&
          verify_claim fuel' HOLLoweringDerivation ev
      | HOLLoweringDerivation =>
          ev.(ev_hol_lowering) &&
          verify_claim fuel' CandleArticleAcceptance ev
      | CandleArticleAcceptance =>
          ev.(ev_candle_acceptance) &&
          verify_claim fuel' VerifiedCakeMLCompilation ev
      | VerifiedCakeMLCompilation =>
          ev.(ev_cakeml_compilation) &&
          verify_claim fuel' InstalledMachineImage ev
      | InstalledMachineImage =>
          ev.(ev_binary_identity) &&
          verify_claim fuel' BootstrapSeed ev
      | BootstrapSeed => ev.(ev_bootstrap_seed)
      end
  end.

Theorem zero_fuel_never_self_certifies :
  forall ev, verify_claim 0 RecursiveSelfImage ev = false.
Proof. reflexivity. Qed.

Theorem recursive_self_verification_requires_bootstrap_seed :
  forall q l c k s b,
    verify_claim 7 RecursiveSelfImage
      {| ev_pcuic_self := q;
         ev_hol_lowering := l;
         ev_candle_acceptance := c;
         ev_cakeml_compilation := k;
         ev_source_identity := s;
         ev_binary_identity := b;
         ev_bootstrap_seed := false |} = false.
Proof.
  intros q l c k s b.
  destruct q, l, c, k, s, b; reflexivity.
Qed.
