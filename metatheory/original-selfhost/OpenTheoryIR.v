From Stdlib Require Import String List.

Import ListNotations.
Open Scope string_scope.

Module OpenTheoryIR.

(* This command vocabulary is intentionally kept isomorphic to the verified
   CakeML OpenTheory reader in examples/opentheory/readerScript.sml. *)
Inductive opcode :=
| AbsTerm | AbsThm | AppTerm | AppThm | Assume | Axiom | BetaConv
| Cons | Const | ConstTerm | DeductAntisym | Def | DefineConst
| DefineConstList | DefineTypeOp | EqMp | HdTl | Nil | OpType | Pop
| Pragma | ProveHyp | Ref | Refl | Remove | Subst | Sym | Thm | Trans
| TypeOp | Var | VarTerm | VarType | Version.

Inductive token :=
| IntegerToken (n : nat)
| StringToken (s : string)
| OpcodeToken (op : opcode).

Definition opcode_name (op : opcode) : string :=
  match op with
  | AbsTerm => "absTerm"
  | AbsThm => "absThm"
  | AppTerm => "appTerm"
  | AppThm => "appThm"
  | Assume => "assume"
  | Axiom => "axiom"
  | BetaConv => "betaConv"
  | Cons => "cons"
  | Const => "const"
  | ConstTerm => "constTerm"
  | DeductAntisym => "deductAntisym"
  | Def => "def"
  | DefineConst => "defineConst"
  | DefineConstList => "defineConstList"
  | DefineTypeOp => "defineTypeOp"
  | EqMp => "eqMp"
  | HdTl => "hdTl"
  | Nil => "nil"
  | OpType => "opType"
  | Pop => "pop"
  | Pragma => "pragma"
  | ProveHyp => "proveHyp"
  | Ref => "ref"
  | Refl => "refl"
  | Remove => "remove"
  | Subst => "subst"
  | Sym => "sym"
  | Thm => "thm"
  | Trans => "trans"
  | TypeOp => "typeOp"
  | Var => "var"
  | VarTerm => "varTerm"
  | VarType => "varType"
  | Version => "version"
  end.

Record article := {
  article_version : nat;
  article_tokens : list token
}.

Definition empty_article : article :=
  {| article_version := 6; article_tokens := [] |}.

Definition emit (t : token) (a : article) : article :=
  {| article_version := article_version a;
     article_tokens := article_tokens a ++ [t] |}.

Definition emit_op (op : opcode) (a : article) : article :=
  emit (OpcodeToken op) a.

Definition emit_string (s : string) (a : article) : article :=
  emit (StringToken s) a.

Definition emit_nat (n : nat) (a : article) : article :=
  emit (IntegerToken n) a.

(* OpenTheory proof generation must never manufacture a proof hole.  Any
   PCUIC-to-HOL lowering pass returns this result type and can only publish an
   article through [Lowered]. *)
Inductive lowering_result (A : Type) :=
| Lowered (value : A)
| Unsupported (reason : string).

Arguments Lowered {A} _.
Arguments Unsupported {A} _.

Definition bind_lowering {A B}
  (r : lowering_result A)
  (k : A -> lowering_result B) : lowering_result B :=
  match r with
  | Lowered x => k x
  | Unsupported reason => Unsupported reason
  end.

Definition publishable (r : lowering_result article) : bool :=
  match r with
  | Lowered _ => true
  | Unsupported _ => false
  end.

End OpenTheoryIR.
