From Stdlib Require Import List.
From ExtLib Require Import Monads.
From MetaRocq.Utils Require Import utils.
From MetaRocq.Common Require Import Kernames.
From MetaRocq.Template Require Import Loader TemplateMonad.

Record replay_inventory_markers := {
  inventory_module_marker : string;
  inventory_root_marker : string;
  inventory_done_marker : string;
  inventory_complete_marker : string;
  inventory_classify_bodies : bool
}.

Definition emit_declaration_root (m : replay_inventory_markers)
  (r : global_reference) : TemplateMonad unit :=
  match r with
  | ConstRef kn =>
      if m.(inventory_classify_bodies)
      then tmBind (tmQuoteConstant kn true)
        (fun body => tmMsg (m.(inventory_root_marker) ^
          (match body.(MetaRocq.Template.Ast.Env.cst_body) with
           | Some _ => "CONST "
           | None => "ASSUMPTION "
           end) ^ string_of_kername kn))
      else tmMsg (m.(inventory_root_marker) ^ "CONST " ^ string_of_kername kn)
  | IndRef ind =>
      tmMsg (m.(inventory_root_marker) ^ "IND " ^ string_of_kername ind.(inductive_mind))
  | ConstructRef ind _ =>
      tmMsg (m.(inventory_root_marker) ^ "IND " ^ string_of_kername ind.(inductive_mind))
  | VarRef id => tmFail ("Open source variable in proof corpus: " ^ id)
  end.

Fixpoint emit_declaration_roots (m : replay_inventory_markers)
  (rs : list global_reference) : TemplateMonad unit :=
  match rs with
  | nil => tmReturn tt
  | r :: rs => tmBind (emit_declaration_root m r)
      (fun _ => emit_declaration_roots m rs)
  end.

Definition emit_declaration_module (m : replay_inventory_markers)
  (q : qualid) : TemplateMonad unit :=
  tmBind (tmMsg (m.(inventory_module_marker) ^ q))
    (fun _ => tmBind (tmQuoteModule q)
      (fun rs => tmBind (emit_declaration_roots m rs)
        (fun _ => tmMsg (m.(inventory_done_marker) ^ q ^ " " ^
          string_of_nat (List.length rs))))).

Fixpoint emit_declaration_modules (m : replay_inventory_markers)
  (qs : list qualid) : TemplateMonad unit :=
  match qs with
  | nil => tmReturn tt
  | q :: qs => tmBind (emit_declaration_module m q)
      (fun _ => emit_declaration_modules m qs)
  end.

Definition emit_declaration_inventory (m : replay_inventory_markers)
  (qs : list qualid) : TemplateMonad unit :=
  tmBind (emit_declaration_modules m qs)
    (fun _ => tmMsg m.(inventory_complete_marker)).
