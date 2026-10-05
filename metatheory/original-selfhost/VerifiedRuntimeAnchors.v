From Stdlib Require Import String List Bool Arith.

Import ListNotations.
Open Scope string_scope.

Inductive verified_anchor_kind :=
| OpenTheoryReaderAnchor
| CandleSemanticsAnchor
| CakeMLCompilerAnchor
| CakeMLReplAnchor
| X64BootstrapAnchor.

Record verified_theorem_anchor := {
  anchor_kind : verified_anchor_kind;
  anchor_repository : string;
  anchor_revision : string;
  anchor_path : string;
  anchor_blob_sha1 : string;
  anchor_theory : string;
  anchor_theorem : string;
  anchor_role : string
}.

Definition cakeml_revision : string :=
  "c98da7fc904c5d6d0e9a75a18fac1796a9bfb1f9".

Definition opentheory_reader_machine_code : verified_theorem_anchor :=
  {| anchor_kind := OpenTheoryReaderAnchor;
     anchor_repository := "https://github.com/CakeML/cakeml.git";
     anchor_revision := cakeml_revision;
     anchor_path := "examples/opentheory/compilation/proofs/readerProgProofScript.sml";
     anchor_blob_sha1 := "3abf706794e448f4abce2350ede7712a01118ddb";
     anchor_theory := "readerProgProof";
     anchor_theorem := "machine_code_sound";
     anchor_role :=
       "accepted OpenTheory sequents are HOL-valid and connected to installed x64 machine code" |}.

Definition candle_prover_semantics : verified_theorem_anchor :=
  {| anchor_kind := CandleSemanticsAnchor;
     anchor_repository := "https://github.com/CakeML/cakeml.git";
     anchor_revision := cakeml_revision;
     anchor_path := "candle/prover/candle_prover_semanticsScript.sml";
     anchor_blob_sha1 := "5b3a22644c604619aeb5039684ac8c5789c9622c";
     anchor_theory := "candle_prover_semantics";
     anchor_theorem := "semantics_thm";
     anchor_role := "top-level Candle prover semantics constrains all emitted theorem events" |}.

Definition compiler64_semantics : verified_theorem_anchor :=
  {| anchor_kind := CakeMLCompilerAnchor;
     anchor_repository := "https://github.com/CakeML/cakeml.git";
     anchor_revision := cakeml_revision;
     anchor_path := "compiler/bootstrap/translation/compiler64ProgScript.sml";
     anchor_blob_sha1 := "c3cecc7f72250a3d30df442b9198f13c1b4d2e36";
     anchor_theory := "compiler64Prog";
     anchor_theorem := "semantics_compiler64_prog";
     anchor_role :=
       "64-bit compiler semantics; the same source routes --candle through the compiler REPL" |}.

Definition repl_semantics : verified_theorem_anchor :=
  {| anchor_kind := CakeMLReplAnchor;
     anchor_repository := "https://github.com/CakeML/cakeml.git";
     anchor_revision := cakeml_revision;
     anchor_path := "compiler/bootstrap/compilation/x64/64/proofs/replProofScript.sml";
     anchor_blob_sha1 := "436c95b6dc64236f33bc2fd7826c841803c11854";
     anchor_theory := "replProof";
     anchor_theorem := "semantics_prog_compiler64_prog";
     anchor_role := "verified semantics of the compiler64 program in REPL mode" |}.

Definition x64_candle_top_level : verified_theorem_anchor :=
  {| anchor_kind := X64BootstrapAnchor;
     anchor_repository := "https://github.com/CakeML/cakeml.git";
     anchor_revision := cakeml_revision;
     anchor_path := "compiler/bootstrap/compilation/x64/64/proofs/x64BootstrapProofScript.sml";
     anchor_blob_sha1 := "71255c97591eef9717739e310b20c65dc509a671";
     anchor_theory := "x64BootstrapProof";
     anchor_theorem := "candle_top_level_soundness";
     anchor_role :=
       "end-to-end x64 bootstrap theorem importing REPL proof and Candle prover semantics" |}.

Definition verified_runtime_anchors : list verified_theorem_anchor :=
  [opentheory_reader_machine_code;
   candle_prover_semantics;
   compiler64_semantics;
   repl_semantics;
   x64_candle_top_level].

Definition verified_runtime_anchor_count_ok : bool :=
  Nat.eqb (List.length verified_runtime_anchors) 5.

Theorem verified_runtime_anchor_shape :
  verified_runtime_anchor_count_ok = true.
Proof. reflexivity. Qed.
