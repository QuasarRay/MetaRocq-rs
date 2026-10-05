From Tactician Require Import Ltac1.
From Stdlib Require Import List Bool.
From MetaRocq.Template Require Import Loader TemplateMonad.

(* Learn the chunk-coverage reasoning used by the retained declaration root.
   This is tool qualification, not the missing replay-checker soundness proof. *)
Lemma retained_chunk_coverage_training {A} (present : A -> bool) left right :
  forallb present left = true -> forallb present right = true ->
  forallb present (left ++ right) = true.
Proof.
  intros Hl Hr. rewrite forallb_app, Hl, Hr. reflexivity.
Qed.

Lemma retained_chunk_coverage_synthesized {A} (present : A -> bool) first second :
  forallb present first = true -> forallb present second = true ->
  forallb present (first ++ second) = true.
Proof. Timeout 30 synth. Qed.

Print Assumptions retained_chunk_coverage_synthesized.

(* The generated proof becomes ordinary Type-valued AST data. Tactician is
   needed at build time only, not to inspect this retained proof term. *)
MetaRocq Run
  (tmBind (tmQuoteRecTransp retained_chunk_coverage_synthesized true)
    (fun p => tmBind (tmDefinition "tactician_retained_coverage_proof" p)
      (fun _ => tmReturn tt))).
