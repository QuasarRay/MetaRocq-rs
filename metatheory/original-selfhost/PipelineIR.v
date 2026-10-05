From Stdlib Require Import String List Bool.

Import ListNotations.
Open Scope string_scope.

Module OriginalMetaRocqSelfHost.

Inductive stage :=
| SnapshotMetaRocq
| LowerMetatheory
| EmitOpenTheory
| CheckWithCandle
| ExtractLambdaBox
| LowerLambdaBoxToCakeML
| ReplaySelfVerification.

Inductive artifact_kind :=
| MetaRocqSourceSnapshot
| PCUICMetatheoryIR
| OpenTheoryArticle
| CandleCertificate
| LambdaBoxProgram
| CakeMLProgram
| CakeMLExecutable
| ReplayReport.

Record artifact := {
  artifact_name : string;
  artifact_kind_of : artifact_kind;
  artifact_digest : option string
}.

Record step := {
  step_stage : stage;
  step_inputs : list artifact_kind;
  step_outputs : list artifact_kind;
  step_required : bool
}.

Definition canonical_pipeline : list step :=
  [ {| step_stage := SnapshotMetaRocq;
       step_inputs := [];
       step_outputs := [MetaRocqSourceSnapshot; PCUICMetatheoryIR];
       step_required := true |};
    {| step_stage := LowerMetatheory;
       step_inputs := [MetaRocqSourceSnapshot; PCUICMetatheoryIR];
       step_outputs := [OpenTheoryArticle];
       step_required := true |};
    {| step_stage := EmitOpenTheory;
       step_inputs := [OpenTheoryArticle];
       step_outputs := [OpenTheoryArticle];
       step_required := true |};
    {| step_stage := CheckWithCandle;
       step_inputs := [OpenTheoryArticle];
       step_outputs := [CandleCertificate];
       step_required := true |};
    {| step_stage := ExtractLambdaBox;
       step_inputs := [MetaRocqSourceSnapshot; PCUICMetatheoryIR];
       step_outputs := [LambdaBoxProgram];
       step_required := true |};
    {| step_stage := LowerLambdaBoxToCakeML;
       step_inputs := [LambdaBoxProgram];
       step_outputs := [CakeMLProgram; CakeMLExecutable];
       step_required := true |};
    {| step_stage := ReplaySelfVerification;
       step_inputs := [CakeMLExecutable; OpenTheoryArticle; CandleCertificate];
       step_outputs := [ReplayReport];
       step_required := true |}
  ].

Definition stage_name (s : stage) : string :=
  match s with
  | SnapshotMetaRocq => "snapshot-metarocq"
  | LowerMetatheory => "lower-metatheory"
  | EmitOpenTheory => "emit-opentheory"
  | CheckWithCandle => "check-with-candle"
  | ExtractLambdaBox => "extract-lambdabox"
  | LowerLambdaBoxToCakeML => "lower-lambdabox-to-cakeml"
  | ReplaySelfVerification => "replay-self-verification"
  end.

Definition artifact_kind_name (k : artifact_kind) : string :=
  match k with
  | MetaRocqSourceSnapshot => "metarocq-source-snapshot"
  | PCUICMetatheoryIR => "pcuic-metatheory-ir"
  | OpenTheoryArticle => "opentheory-article"
  | CandleCertificate => "candle-certificate"
  | LambdaBoxProgram => "lambdabox-program"
  | CakeMLProgram => "cakeml-program"
  | CakeMLExecutable => "cakeml-executable"
  | ReplayReport => "replay-report"
  end.

Inductive gate_result :=
| GatePassed (outputs : list artifact)
| GateBlocked (reason : string).

Definition bind_gate
  (r : gate_result)
  (k : list artifact -> gate_result) : gate_result :=
  match r with
  | GatePassed xs => k xs
  | GateBlocked reason => GateBlocked reason
  end.

Definition fail_closed (ok : bool) (reason : string)
  (outputs : list artifact) : gate_result :=
  if ok then GatePassed outputs else GateBlocked reason.

Definition trusted_path : list stage :=
  map step_stage (filter step_required canonical_pipeline).

End OriginalMetaRocqSelfHost.
