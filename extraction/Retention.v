(* Additive reflection: no original MetaRocq definition is changed. *)
From MetaRocq.Template Require Import All.
Import MonadNotation ListNotations.
Local Open Scope bs_scope.

(* These constructors live in Type. A proof is stored as Ast.term syntax,
   never as a field whose type is the proposition proved by that proof. *)
Inductive retained_declaration : Type :=
| retained_constant : kername -> constant_body -> retained_declaration
| retained_inductive : kername -> mutual_inductive_body -> retained_declaration.

Record retained_module : Type := {
  retained_name : qualid;
  retained_references : list global_reference;
  retained_declarations : list retained_declaration;
  retained_constraints : ConstraintSet.t
}.

Definition retain_reference (r : global_reference)
  : TemplateMonad retained_declaration :=
  match r with
  | ConstRef kn => b <- tmQuoteConstant kn true;;
                   ret (retained_constant kn b)
  | IndRef i | ConstructRef i _ =>
      b <- tmQuoteInductive i.(inductive_mind);;
      ret (retained_inductive i.(inductive_mind) b)
  | VarRef _ => tmFail "Cannot retain an open section variable"
  end.

(* A module snapshot is an inventory, not a dependency-closed program. Keep
   every reference, including constructors, rather than silently dropping one. *)
Definition retain_module (name : qualid) : TemplateMonad retained_module :=
  refs <- tmQuoteModule name;;
  decls <- monad_map retain_reference refs;;
  universes <- tmQuoteUniverses;;
  ret {| retained_name := name;
         retained_references := refs;
         retained_declarations := decls;
         retained_constraints := universes |}.

(* Lookup the quoted root; absence of an opaque body is observable failure. *)
Definition retained_root_body (p : Ast.program) : option Ast.term :=
  match snd p with
  | tConst kn _ =>
    match List.find (fun d => eq_kername kn (fst d)) (declarations (fst p)) with
    | Some (_, ConstantDecl b) => b.(cst_body)
    | _ => None
    end
  | _ => None
  end.

Definition has_retained_root_body (p : Ast.program) : bool :=
  match retained_root_body p with Some _ => true | None => false end.
