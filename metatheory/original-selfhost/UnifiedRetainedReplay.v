From Stdlib Require Import List Bool.
From Stdlib Require Import FMapAVL.
From MetaRocq.Utils Require Import utils.
From MetaRocq.Common Require Import Kernames.
From MetaRocq.Template Require Import Loader TemplateMonad.
From MetaRocqRs.UnifiedGenerated Require Import
  UnifiedModuleManifest UnifiedReplayAllGlobals.

(* Quote the unreduced all-declaration root, including opaque bodies.
   The resulting syntax is ordinary Type-valued program data; Prop erasure
   does not erase these AST constructors or the quoted proof terms. *)
MetaRocq Run
  (tmBind (tmQuoteRecTransp
    UnifiedReplayAllGlobals.unified_all_declarations_root true)
    (fun p => tmBind (tmDefinition "unified_retained_program" p)
      (fun _ => tmReturn tt))).

(* Reuse the standard verified map implementation; avoid scanning the complete
   environment for each of the thousands of retained declaration roots. *)
Module UnifiedNameMap := FMapAVL.Make bytestring.StringOTOrig.
Definition unified_declaration_index :=
  fold_right (fun declaration index =>
    UnifiedNameMap.add (string_of_kername (fst declaration)) (snd declaration) index)
    (UnifiedNameMap.empty MetaRocq.Template.Ast.Env.global_decl)
    (fst unified_retained_program).(MetaRocq.Template.Ast.Env.declarations).

Definition unified_body_present (name : string) : bool :=
  match UnifiedNameMap.find name unified_declaration_index with
  | Some declaration =>
    match declaration with
    | MetaRocq.Template.Ast.Env.ConstantDecl body =>
        match body.(MetaRocq.Template.Ast.Env.cst_body) with
        | Some _ => true
        | None => false
        end
    | _ => false
    end
  | None => false
  end.

Definition unified_inductive_present (name : string) : bool :=
  match UnifiedNameMap.find name unified_declaration_index with
  | Some declaration =>
    match declaration with
    | MetaRocq.Template.Ast.Env.InductiveDecl _ => true
    | _ => false
    end
  | None => false
  end.

Definition unified_assumption_present (name : string) : bool :=
  match UnifiedNameMap.find name unified_declaration_index with
  | Some declaration =>
    match declaration with
    | MetaRocq.Template.Ast.Env.ConstantDecl body =>
        match body.(MetaRocq.Template.Ast.Env.cst_body) with
        | Some _ => false
        | None => true
        end
    | _ => false
    end
  | None => false
  end.

Definition unified_retention_coverage : bool :=
  negb (Nat.eqb unified_expected_modules 0) &&
  forallb unified_body_present unified_expected_body_names &&
  forallb unified_inductive_present unified_expected_inductive_names &&
  forallb unified_assumption_present unified_expected_assumption_names.

Example unified_emitted_declarations_retained : unified_retention_coverage = true.
Proof. vm_compute. reflexivity. Qed.

Inductive unified_replay_obligation :=
| UnmappedSourceModules (count : nat)
| VerifiedGallinaGuardImplementation
| SourceReplayToHOL4Refinement
| PeregrineCakeMLPipelineCorrectness
| ExactMachineCodeSourceSpecificationTheorem.

Record unified_retained_replay_image := {
  unified_source_and_proof_terms : MetaRocq.Template.Ast.Env.program;
  unified_body_roots : list string;
  unified_assumption_roots : list string;
  unified_retention_checked : bool;
  unified_open_obligations : list unified_replay_obligation
}.

(* No fabricated checker, normalization proof, or HOL4 theorem is supplied.
   This is a single retained-image extraction root, awaiting verified replay.
   Inspection/quotation success cannot turn it into a certified executable. *)
Definition unified_retained_runtime_root : unified_retained_replay_image :=
  {| unified_source_and_proof_terms := unified_retained_program;
     unified_body_roots := unified_expected_body_names;
     unified_assumption_roots := unified_expected_assumption_names;
     unified_retention_checked := unified_retention_coverage;
     unified_open_obligations :=
       [UnmappedSourceModules unified_unmapped_source_count;
        VerifiedGallinaGuardImplementation;
        SourceReplayToHOL4Refinement;
        PeregrineCakeMLPipelineCorrectness;
        ExactMachineCodeSourceSpecificationTheorem] |}.
