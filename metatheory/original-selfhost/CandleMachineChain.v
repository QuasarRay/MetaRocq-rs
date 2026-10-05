From Stdlib Require Import String List Bool.

Import ListNotations.
Open Scope string_scope.

Inductive chain_stage :=
| PCUICProofDerivation
| OpenTheoryProofProgram
| CandleArticleAcceptance
| CandleSourceInvariant
| CakeMLCompilerCorrectness
| MachineCodeImage
| MachineCodeReplay.

Record chain_obligation := {
  chain_stage_of : chain_stage;
  chain_reference : string;
  chain_upstream_verified : bool;
  chain_local_binding_proved : bool
}.

(* The verified Candle/OpenTheory and CakeML theorems already exist upstream at
   the pinned CakeML revision.  This branch still has to prove that its own
   generated artifacts are the exact objects to which those theorems apply. *)
Definition candle_machine_chain : list chain_obligation :=
  [ {| chain_stage_of := PCUICProofDerivation;
       chain_reference := "MetaRocq PCUIC proof objects";
       chain_upstream_verified := false;
       chain_local_binding_proved := false |};
    {| chain_stage_of := OpenTheoryProofProgram;
       chain_reference := "OriginalSelfHost.HOLProofIR/OpenTheorySerialize";
       chain_upstream_verified := false;
       chain_local_binding_proved := false |};
    {| chain_stage_of := CandleArticleAcceptance;
       chain_reference :=
         "CakeML examples/opentheory/readerSoundnessScript.sml @ c98da7fc...";
       chain_upstream_verified := true;
       chain_local_binding_proved := false |};
    {| chain_stage_of := CandleSourceInvariant;
       chain_reference :=
         "Candle whole-program theorem-value invariant / v_ok pattern";
       chain_upstream_verified := true;
       chain_local_binding_proved := false |};
    {| chain_stage_of := CakeMLCompilerCorrectness;
       chain_reference :=
         "CakeML verified compiler + Candle REPL compiler theorem @ c98da7fc...";
       chain_upstream_verified := true;
       chain_local_binding_proved := false |};
    {| chain_stage_of := MachineCodeImage;
       chain_reference := "single-image machine code produced in-logic";
       chain_upstream_verified := true;
       chain_local_binding_proved := false |};
    {| chain_stage_of := MachineCodeReplay;
       chain_reference := "self image executes retained proof replay";
       chain_upstream_verified := false;
       chain_local_binding_proved := false |}
  ].

Fixpoint every_local_binding_proved (xs : list chain_obligation) : bool :=
  match xs with
  | [] => true
  | x :: xs =>
      x.(chain_local_binding_proved) && every_local_binding_proved xs
  end.

Definition machine_chain_closed : bool :=
  every_local_binding_proved candle_machine_chain.
