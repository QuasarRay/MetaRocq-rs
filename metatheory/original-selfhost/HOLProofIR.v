From Stdlib Require Import String List.
From MetaRocqRs.OriginalSelfHost Require Import OpenTheoryIR.

Import ListNotations.
Open Scope string_scope.

Module HOLProofIR.

(* A deliberately small simply-typed HOL term language.  More type-operator
   arities can be added without changing the proof kernel interface. *)
Inductive hol_type :=
| HVarType (name : string)
| HType0 (name : string)
| HType1 (name : string) (arg : hol_type)
| HType2 (name : string) (left right : hol_type).

Inductive hol_term :=
| HVar (name : string) (ty : hol_type)
| HConst (name : string) (ty : hol_type)
| HApp (fn arg : hol_term)
| HAbs (name : string) (ty : hol_type) (body : hol_term).

(* Only proof-producing OpenTheory kernel rules are represented here.
   In particular, there is intentionally no source-theorem axiom constructor. *)
Inductive hol_proof :=
| HAssume (tm : hol_term)
| HRefl (tm : hol_term)
| HBeta (tm : hol_term)
| HAppThm (fn_eq arg_eq : hol_proof)
| HAbsThm (name : string) (ty : hol_type) (body_eq : hol_proof)
| HSym (eq : hol_proof)
| HTrans (left right : hol_proof)
| HEqMp (eq proposition : hol_proof)
| HDeductAntisym (left right : hol_proof)
| HProveHyp (hyp theorem : hol_proof).

Record export_theorem := {
  export_proof : hol_proof;
  export_hypotheses : list hol_term;
  export_conclusion : hol_term
}.

Definition op (x : OpenTheoryIR.opcode) : OpenTheoryIR.token :=
  OpenTheoryIR.OpcodeToken x.

Fixpoint compile_type (ty : hol_type) : list OpenTheoryIR.token :=
  match ty with
  | HVarType name =>
      [OpenTheoryIR.StringToken name; op OpenTheoryIR.VarType]
  | HType0 name =>
      [OpenTheoryIR.StringToken name; op OpenTheoryIR.OTTypeOp;
       op OpenTheoryIR.Nil; op OpenTheoryIR.OpType]
  | HType1 name arg =>
      [OpenTheoryIR.StringToken name; op OpenTheoryIR.OTTypeOp]
      ++ compile_type arg
      ++ [op OpenTheoryIR.Nil; op OpenTheoryIR.Cons; op OpenTheoryIR.OpType]
  | HType2 name left right =>
      [OpenTheoryIR.StringToken name; op OpenTheoryIR.OTTypeOp]
      ++ compile_type left
      ++ compile_type right
      ++ [op OpenTheoryIR.Nil; op OpenTheoryIR.Cons; op OpenTheoryIR.Cons;
          op OpenTheoryIR.OpType]
  end.

Definition compile_var (name : string) (ty : hol_type)
  : list OpenTheoryIR.token :=
  [OpenTheoryIR.StringToken name]
  ++ compile_type ty
  ++ [op OpenTheoryIR.Var].

Fixpoint compile_term (tm : hol_term) : list OpenTheoryIR.token :=
  match tm with
  | HVar name ty =>
      compile_var name ty ++ [op OpenTheoryIR.VarTerm]
  | HConst name ty =>
      [OpenTheoryIR.StringToken name; op OpenTheoryIR.Const]
      ++ compile_type ty
      ++ [op OpenTheoryIR.ConstTerm]
  | HApp fn arg =>
      compile_term fn ++ compile_term arg ++ [op OpenTheoryIR.AppTerm]
  | HAbs name ty body =>
      compile_var name ty ++ compile_term body ++ [op OpenTheoryIR.AbsTerm]
  end.

Fixpoint compile_term_list (xs : list hol_term) : list OpenTheoryIR.token :=
  match xs with
  | [] => [op OpenTheoryIR.Nil]
  | x :: xs =>
      compile_term x ++ compile_term_list xs ++ [op OpenTheoryIR.Cons]
  end.

Fixpoint compile_proof (pf : hol_proof) : list OpenTheoryIR.token :=
  match pf with
  | HAssume tm =>
      compile_term tm ++ [op OpenTheoryIR.Assume]
  | HRefl tm =>
      compile_term tm ++ [op OpenTheoryIR.Refl]
  | HBeta tm =>
      compile_term tm ++ [op OpenTheoryIR.BetaConv]
  | HAppThm fn_eq arg_eq =>
      compile_proof fn_eq ++ compile_proof arg_eq ++ [op OpenTheoryIR.AppThm]
  | HAbsThm name ty body_eq =>
      compile_var name ty ++ compile_proof body_eq ++ [op OpenTheoryIR.AbsThm]
  | HSym eq =>
      compile_proof eq ++ [op OpenTheoryIR.Sym]
  | HTrans left right =>
      compile_proof left ++ compile_proof right ++ [op OpenTheoryIR.Trans]
  | HEqMp eq proposition =>
      compile_proof eq ++ compile_proof proposition ++ [op OpenTheoryIR.EqMp]
  | HDeductAntisym left right =>
      compile_proof left ++ compile_proof right
      ++ [op OpenTheoryIR.DeductAntisym]
  | HProveHyp hyp theorem =>
      compile_proof hyp ++ compile_proof theorem ++ [op OpenTheoryIR.ProveHyp]
  end.

(* The [thm] command is essential: the verified reader compares the theorem
   produced by the proof program with this declared sequent via ALPHA_THM.
   Therefore a bad compiler cannot obtain an exported theorem merely by leaving
   an unrelated proof object on the VM stack. *)
Definition compile_export (th : export_theorem) : list OpenTheoryIR.token :=
  compile_proof th.(export_proof)
  ++ compile_term_list th.(export_hypotheses)
  ++ compile_term th.(export_conclusion)
  ++ [op OpenTheoryIR.Thm].

Definition theorem_article (th : export_theorem) : OpenTheoryIR.article :=
  {| OpenTheoryIR.article_version := 6;
     OpenTheoryIR.article_tokens :=
       [OpenTheoryIR.IntegerToken 6; op OpenTheoryIR.Version]
       ++ compile_export th |}.

End HOLProofIR.
