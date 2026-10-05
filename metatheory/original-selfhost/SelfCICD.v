From Stdlib Require Import String List Bool.

Import ListNotations.
Open Scope string_scope.

Inductive ci_artifact :=
| SourceSnapshot
| PCUICSnapshot
| OpenTheoryBundle
| LambdaBoxImage
| CakeMLSource
| CakeMLMachineCode
| CandleReplayCertificate
| SelfReplayReport.

Inductive ci_action :=
| VerifyPinnedSources
| MaterializePCUICSnapshot
| ProduceOpenTheory
| CheckOpenTheoryWithCandle
| ExtractSelfToLambdaBox
| TranslateLambdaBoxWithPeregrine
| CompileWithCakeMLInLogic
| ReplayMachineImage
| CompareSelfIdentity.

Record ci_job := {
  ci_name : string;
  ci_action_of : ci_action;
  ci_inputs : list ci_artifact;
  ci_outputs : list ci_artifact;
  ci_required : bool
}.

Definition self_ci_pipeline : list ci_job :=
  [ {| ci_name := "verify-pins";
       ci_action_of := VerifyPinnedSources;
       ci_inputs := [];
       ci_outputs := [SourceSnapshot];
       ci_required := true |};
    {| ci_name := "materialize-pcuic";
       ci_action_of := MaterializePCUICSnapshot;
       ci_inputs := [SourceSnapshot];
       ci_outputs := [PCUICSnapshot];
       ci_required := true |};
    {| ci_name := "produce-opentheory";
       ci_action_of := ProduceOpenTheory;
       ci_inputs := [PCUICSnapshot];
       ci_outputs := [OpenTheoryBundle];
       ci_required := true |};
    {| ci_name := "candle-check";
       ci_action_of := CheckOpenTheoryWithCandle;
       ci_inputs := [OpenTheoryBundle];
       ci_outputs := [CandleReplayCertificate];
       ci_required := true |};
    {| ci_name := "extract-lambdabox";
       ci_action_of := ExtractSelfToLambdaBox;
       ci_inputs := [PCUICSnapshot; OpenTheoryBundle];
       ci_outputs := [LambdaBoxImage];
       ci_required := true |};
    {| ci_name := "peregrine-cakeml";
       ci_action_of := TranslateLambdaBoxWithPeregrine;
       ci_inputs := [LambdaBoxImage];
       ci_outputs := [CakeMLSource];
       ci_required := true |};
    {| ci_name := "cakeml-in-logic";
       ci_action_of := CompileWithCakeMLInLogic;
       ci_inputs := [CakeMLSource; CandleReplayCertificate];
       ci_outputs := [CakeMLMachineCode];
       ci_required := true |};
    {| ci_name := "machine-replay";
       ci_action_of := ReplayMachineImage;
       ci_inputs := [CakeMLMachineCode; OpenTheoryBundle];
       ci_outputs := [SelfReplayReport];
       ci_required := true |};
    {| ci_name := "compare-self-identity";
       ci_action_of := CompareSelfIdentity;
       ci_inputs := [SourceSnapshot; CakeMLMachineCode; SelfReplayReport];
       ci_outputs := [SelfReplayReport];
       ci_required := true |}
  ].

Fixpoint all_jobs_required (xs : list ci_job) : bool :=
  match xs with
  | [] => true
  | x :: xs => x.(ci_required) && all_jobs_required xs
  end.

Definition self_ci_structure_closed : bool :=
  Nat.eqb (List.length self_ci_pipeline) 9
  && all_jobs_required self_ci_pipeline.
