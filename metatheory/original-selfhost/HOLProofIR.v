From Stdlib Require Import String List.
From MetaRocqRs.OriginalSelfHost Require Import OpenTheoryIR.

Import ListNotations.
Open Scope string_scope.

Module HOLProofIR.

Inductive hol_type :=
| HVarType (name : string)
| HOpType (name : string) (args : list hol_type).

Inductive hol_term :=
| HVar (name : string) (ty : hol_type)
| HConst (name : string) (ty : hol_type)
| HApp (fn arg : hol_term)
| HAbs (name : string) (ty : hol_type) (body : hol_term).

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

Definition emit_token (t : OpenTheoryIR.token)
  (xs : list OpenTheoryIR.token) : list OpenTheoryIR.token :=
  xs ++ [t].

Definition emit_opcode (op : OpenTheoryIR.opcode)
  (xs : list OpenTheoryIR.token) : list OpenTheoryIR.token :=
  emit_token (OpenTheoryIR.OpcodeToken op) xs.

Definition emit_name (s : string)
  (xs : list OpenTheoryIR.token) : list OpenTheoryIR.token :=
  emit_token (OpenTheoryIR.StringToken s) xs.

Fixpoint compile_type (ty : hol_type) : list OpenTheoryIR.token :=
  match ty with
  | HVarType name =>
      [ OpenTheoryIR.StringToken name;
        OpenTheoryIR.OpcodeToken OpenTheoryIR.VarType ]
  | HOpType name args =>
      [ OpenTheoryIR.StringToken name;
        OpenTheoryIR.OpcodeToken OpenTheoryIR.TypeOp ]
      ++ compile_type_list args
      ++ [ OpenTheoryIR.OpcodeToken OpenTheoryIR.OpType ]
  end
with compile_type_list (tys : list hol_type) : list OpenTheoryIR.token :=
  match tys with
  | [] => [OpenTheoryIR.OpcodeToken OpenTheoryIR.Nil]
  | ty :: tys =>
      compile_type ty
      ++ compile_type_list tys
      ++ [OpenTheoryIR.OpcodeToken OpenTheoryIR.Cons]
  end.

Definition compile_var (name : string) (ty : hol_type)
  : list OpenTheoryIR.token :=
  [OpenTheoryIR.StringToken name]
  ++ compile_type ty
  ++ [OpenTheoryIR.OpcodeToken OpenTheoryIR.Var].

Fixpoint compile_term (tm : hol_term) : list OpenTheoryIR.token :=
  match tm with
  | HVar name ty =>
      compile_var name ty
      ++ [OpenTheoryIR.OpcodeToken OpenTheoryIR.VarTerm]
  | HConst name ty =>
      [ OpenTheoryIR.StringToken name;
        OpenTheoryIR.OpcodeToken OpenTheoryIR.Const ]
      ++ compile_type ty
      ++ [OpenTheoryIR.OpcodeToken OpenTheoryIR.ConstTerm]
  | HApp fn arg =>
      compile_term fn
      ++ compile_term arg
      ++ [OpenTheoryIR.OpcodeToken OpenTheoryIR.AppTerm]
  | HAbs name ty body =>
      compile_var name ty
      ++ compile_term body
      ++ [OpenTheoryIR.OpcodeToken OpenTheoryIR.AbsTerm]
  end.

Fixpoint compile_proof (pf : hol_proof) : list OpenTheoryIR.token :=
  match pf with
  | HAssume tm =>
      compile_term tm
      ++ [OpenTheoryIR.OpcodeToken OpenTheoryIR.Assume]
  | HRefl tm =>
      compile_term tm
      ++ [OpenTheoryIR.OpcodeToken OpenTheoryIR.Refl]
  | HBeta tm =>
      compile_term tm
      ++ [OpenTheoryIR.OpcodeToken OpenTheoryIR.BetaConv]
  | HAppThm fn_eq arg_eq =>
      compile_proof fn_eq
      ++ compile_proof arg_eq
      ++ [OpenTheoryIR.OpcodeToken OpenTheoryIR.AppThm]
  | HAbsThm name ty body_eq =>
      compile_var name ty
      ++ compile_proof body_eq
      ++ [OpenTheoryIR.OpcodeToken OpenTheoryIR.AbsThm]
  | HSym eq =>
      compile_proof eq
      ++ [OpenTheoryIR.OpcodeToken OpenTheoryIR.Sym]
  | HTrans left right =>
      compile_proof left
      ++ compile_proof right
      ++ [OpenTheoryIR.OpcodeToken OpenTheoryIR.Trans]
  | HEqMp eq proposition =>
      compile_proof eq
      ++ compile_proof proposition
      ++ [OpenTheoryIR.OpcodeToken OpenTheoryIR.EqMp]
  | HDeductAntisym left right =>
      compile_proof left
      ++ compile_proof right
      ++ [OpenTheoryIR.OpcodeToken OpenTheoryIR.DeductAntisym]
  | HProveHyp hyp theorem =>
      compile_proof hyp
      ++ compile_proof theorem
      ++ [OpenTheoryIR.OpcodeToken OpenTheoryIR.ProveHyp]
  end.

Definition proof_article (pf : hol_proof) : OpenTheoryIR.article :=
  {| OpenTheoryIR.article_version := 6;
     OpenTheoryIR.article_tokens :=
       [ OpenTheoryIR.IntegerToken 6;
         OpenTheoryIR.OpcodeToken OpenTheoryIR.Version ]
       ++ compile_proof pf |}.

End HOLProofIR.
