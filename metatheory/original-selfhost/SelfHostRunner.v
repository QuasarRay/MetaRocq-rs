From Stdlib Require Import String List Bool.
From MetaRocqRs.OriginalSelfHost Require Import
  OpenTheoryIR HOLProofIR OpenTheorySerialize.

Import ListNotations.
Open Scope string_scope.

Module SelfHostRunner.

Record candle_backend := {
  check_article : string -> bool
}.

Record translation_bundle := {
  expected_theorem_count : nat;
  translated_theorems : list HOLProofIR.export_theorem
}.

Inductive selfhost_result :=
| SelfHostVerified
    (article : string)
    (theorem_count : nat)
| SelfHostBlocked
    (reason : string)
| SelfHostRejected
    (reason : string).

Definition bundle_complete (b : translation_bundle) : bool :=
  Nat.eqb (List.length b.(translated_theorems))
          b.(expected_theorem_count).

Definition compile_theorems
  (ths : list HOLProofIR.export_theorem)
  : list OpenTheoryIR.token :=
  flat_map HOLProofIR.compile_export ths.

Definition bundle_article (b : translation_bundle) : OpenTheoryIR.article :=
  {| OpenTheoryIR.article_version := 6;
     OpenTheoryIR.article_tokens :=
       [ OpenTheoryIR.IntegerToken 6;
         OpenTheoryIR.OpcodeToken OpenTheoryIR.Version ]
       ++ compile_theorems b.(translated_theorems) |}.

Definition run
  (backend : candle_backend)
  (lowered : OpenTheoryIR.lowering_result translation_bundle)
  : selfhost_result :=
  match lowered with
  | OpenTheoryIR.Unsupported reason =>
      SelfHostBlocked reason
  | OpenTheoryIR.Lowered bundle =>
      if bundle_complete bundle then
        match OpenTheorySerialize.serialize_article (bundle_article bundle) with
        | OpenTheoryIR.Unsupported reason =>
            SelfHostBlocked reason
        | OpenTheoryIR.Lowered article =>
            if backend.(check_article) article
            then SelfHostVerified article (List.length bundle.(translated_theorems))
            else SelfHostRejected
                   "Candle rejected the exact OpenTheory article bytes"
        end
      else
        SelfHostBlocked
          "PCUIC-to-HOL lowering did not produce the expected theorem count"
  end.

End SelfHostRunner.
