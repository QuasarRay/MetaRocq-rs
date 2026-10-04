From Stdlib Require Import Ascii String List Bool.
From MetaRocq.Utils Require Import MRString.
From MetaRocqRs.OriginalSelfHost Require Import OpenTheoryIR.

Import ListNotations.
Open Scope string_scope.

Module OpenTheorySerialize.

Definition ascii_quote : ascii := ascii_of_nat 34.
Definition ascii_backslash : ascii := ascii_of_nat 92.
Definition ascii_lf : ascii := ascii_of_nat 10.
Definition ascii_cr : ascii := ascii_of_nat 13.

Fixpoint safe_literal (s : string) : bool :=
  match s with
  | EmptyString => true
  | String c rest =>
      negb (Ascii.eqb c ascii_quote
            || Ascii.eqb c ascii_backslash
            || Ascii.eqb c ascii_lf
            || Ascii.eqb c ascii_cr)
      && safe_literal rest
  end.

Definition newline : string := String ascii_lf EmptyString.
Definition quote : string := String ascii_quote EmptyString.

Definition serialize_token
  (t : OpenTheoryIR.token) : OpenTheoryIR.lowering_result string :=
  match t with
  | OpenTheoryIR.IntegerToken n =>
      OpenTheoryIR.Lowered (MRString.string_of_nat n)
  | OpenTheoryIR.StringToken s =>
      if safe_literal s
      then OpenTheoryIR.Lowered (quote ++ s ++ quote)
      else OpenTheoryIR.Unsupported
             "OpenTheory literal requires escaping; serializer fails closed"
  | OpenTheoryIR.OpcodeToken op =>
      OpenTheoryIR.Lowered (OpenTheoryIR.opcode_name op)
  end.

Fixpoint serialize_tokens
  (xs : list OpenTheoryIR.token) : OpenTheoryIR.lowering_result string :=
  match xs with
  | [] => OpenTheoryIR.Lowered EmptyString
  | x :: xs =>
      match serialize_token x with
      | OpenTheoryIR.Unsupported reason => OpenTheoryIR.Unsupported reason
      | OpenTheoryIR.Lowered line =>
          match serialize_tokens xs with
          | OpenTheoryIR.Unsupported reason => OpenTheoryIR.Unsupported reason
          | OpenTheoryIR.Lowered rest =>
              OpenTheoryIR.Lowered (line ++ newline ++ rest)
          end
      end
  end.

Definition serialize_article
  (a : OpenTheoryIR.article) : OpenTheoryIR.lowering_result string :=
  serialize_tokens a.(OpenTheoryIR.article_tokens).

End OpenTheorySerialize.
