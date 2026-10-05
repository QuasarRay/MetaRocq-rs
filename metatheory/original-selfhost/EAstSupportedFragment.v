From Stdlib Require Import List Bool Arith.
From MetaRocq.Erasure Require Import EAst EGlobalEnv.
From CakeML.Backend Require Import Compile.

Import ListNotations.

Fixpoint east_term_supported
  (Σ : EAst.global_declarations) (t : EAst.term) : bool :=
  match t with
  | EAst.tVar _ => true
  | EAst.tLambda _ body =>
      east_term_supported Σ body
  | EAst.tLetIn _ def body =>
      east_term_supported Σ def && east_term_supported Σ body
  | EAst.tApp fn arg =>
      east_term_supported Σ fn && east_term_supported Σ arg
  | EAst.tConst kn =>
      match EGlobalEnv.lookup_constant Σ kn with
      | Some _ => true
      | None => false
      end
  | EAst.tConstruct ind c args =>
      match Compile.lookup_constructor_names Σ ind with
      | Some names =>
          Nat.ltb c (List.length names)
          && forallb (east_term_supported Σ) args
      | None => false
      end
  | EAst.tCase ind discr branches =>
      match Compile.lookup_constructor_names Σ (fst ind) with
      | Some names =>
          Nat.eqb (List.length names) (List.length branches)
          && east_term_supported Σ discr
          && forallb
               (fun br => east_term_supported Σ (snd br))
               branches
      | None => false
      end
  | EAst.tFix mfix idx =>
      Nat.ltb idx (List.length mfix)
      && forallb
           (fun d =>
              EAst.isLambda d.(EAst.dbody)
              && east_term_supported Σ d.(EAst.dbody))
           mfix
  | EAst.tRel _
  | EAst.tEvar _ _
  | EAst.tProj _ _
  | EAst.tCoFix _ _
  | EAst.tPrim _
  | EAst.tLazy _
  | EAst.tForce _
  | EAst.tBox => false
  end.

Fixpoint east_env_supported (Σ : EAst.global_declarations) : bool :=
  match Σ with
  | [] => true
  | (_, EAst.ConstantDecl cb) :: rest =>
      match cb.(EAst.cst_body) with
      | Some body =>
          east_term_supported rest body
          && east_env_supported rest
      | None => false
      end
  | (_, EAst.InductiveDecl _) :: rest =>
      east_env_supported rest
  end.

Definition east_program_supported (p : EAst.program) : bool :=
  east_env_supported (fst p)
  && east_term_supported (fst p) (snd p).
