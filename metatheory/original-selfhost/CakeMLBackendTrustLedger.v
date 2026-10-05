From Stdlib Require Import String List Bool.

Import ListNotations.
Open Scope string_scope.

Inductive backend_gap_kind :=
| AxiomGap
| AdmittedGap
| MissingSemanticTheorem
| VacuousTransformContract.

Record backend_gap := {
  backend_gap_component : string;
  backend_gap_path : string;
  backend_gap_blob_sha : string;
  backend_gap_name : string;
  backend_gap_kind_of : backend_gap_kind;
  backend_gap_forbidden_as_evidence : bool
}.

Definition cakeml_extraction_revision : string :=
  "cc20d1a2986bd2fec7c6eb0864c8c9a806188b58".

Definition peregrine_revision : string :=
  "d768b83ffa7dab35b8d72241f0570b5bb6aedae9".

Definition cake_backend_gaps : list backend_gap :=
  [ {| backend_gap_component := "Peregrine wrapper";
       backend_gap_path := "theories/backends/CakeMLBackend.v";
       backend_gap_blob_sha := "42e0da7679e217a3b0a94aaf9a1b19667bfb1175";
       backend_gap_name := "cakeml_pipeline final obligation";
       backend_gap_kind_of := AdmittedGap;
       backend_gap_forbidden_as_evidence := true |};
    {| backend_gap_component := "Peregrine wrapper";
       backend_gap_path := "theories/backends/CakeMLBackend.v";
       backend_gap_blob_sha := "42e0da7679e217a3b0a94aaf9a1b19667bfb1175";
       backend_gap_name := "trust_coq_kernel";
       backend_gap_kind_of := AxiomGap;
       backend_gap_forbidden_as_evidence := true |};
    {| backend_gap_component := "rocq-cakeml-extraction 0.1.0";
       backend_gap_path := "theories/Backend/Pipeline.v";
       backend_gap_blob_sha := "7e1482f1a0f14f358689efe0044a41618df214ee";
       backend_gap_name := "assume_can_be_extracted";
       backend_gap_kind_of := AxiomGap;
       backend_gap_forbidden_as_evidence := true |};
    {| backend_gap_component := "rocq-cakeml-extraction 0.1.0";
       backend_gap_path := "theories/Backend/Pipeline.v";
       backend_gap_blob_sha := "7e1482f1a0f14f358689efe0044a41618df214ee";
       backend_gap_name := "compile_to_malfunction preservation";
       backend_gap_kind_of := AdmittedGap;
       backend_gap_forbidden_as_evidence := true |};
    {| backend_gap_component := "rocq-cakeml-extraction 0.1.0";
       backend_gap_path := "theories/Backend/Pipeline.v";
       backend_gap_blob_sha := "7e1482f1a0f14f358689efe0044a41618df214ee";
       backend_gap_name := "compile_to_malfunction True/True observational contract";
       backend_gap_kind_of := VacuousTransformContract;
       backend_gap_forbidden_as_evidence := true |};
    {| backend_gap_component := "rocq-cakeml-extraction 0.1.0";
       backend_gap_path := "theories/Backend/Pipeline.v";
       backend_gap_blob_sha := "7e1482f1a0f14f358689efe0044a41618df214ee";
       backend_gap_name := "trust_coq_kernel";
       backend_gap_kind_of := AxiomGap;
       backend_gap_forbidden_as_evidence := true |};
    {| backend_gap_component := "rocq-cakeml-extraction 0.1.0";
       backend_gap_path := "theories/Backend/Compile.v";
       backend_gap_blob_sha := "b22338bc3113a972bcf793f79be7887bc59153e8";
       backend_gap_name := "EAst to CakeML compile_program semantic preservation";
       backend_gap_kind_of := MissingSemanticTheorem;
       backend_gap_forbidden_as_evidence := true |}
  ].

Definition candidate_support_assets : list (string * string) :=
  [ ("Peregrine/theories/PAst.v",
     "45306f7c193eaa4e47cfe1b7b0f63e211de948b8");
    ("CakeML.Backend/Compile.v",
     "b22338bc3113a972bcf793f79be7887bc59153e8");
    ("CakeML/proofs/equivalence_proofs.v",
     "2f6c7ab14090450ef2dc96d163285ff8f44cf91d");
    ("CakeML/proofs/invariants.v",
     "b85e06f61733800e407fc018848a45ef7974aed6");
    ("CakeML/proofs/helper_lemmas.v",
     "f81378fc2b2159a504ce954658de35b87ba2bde1")
  ].

Fixpoint all_gaps_forbidden (xs : list backend_gap) : bool :=
  match xs with
  | [] => true
  | x :: xs =>
      x.(backend_gap_forbidden_as_evidence) && all_gaps_forbidden xs
  end.

Definition backend_trust_ledger_closed : bool :=
  Nat.eqb (List.length cake_backend_gaps) 7
  && all_gaps_forbidden cake_backend_gaps.
