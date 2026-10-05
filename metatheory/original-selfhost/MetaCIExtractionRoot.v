From MetaRocqRs.OriginalSelfHost Require Import
  SelfHostCI SelfHostCIInterpreter CakeMLImageIR
  SingleImageRunner SingleImageExtractionRoot.

Inductive meta_ci_command :=
| EvaluateCI (e : ci_evidence)
| RunImage (cmd : single_image_command) (e : single_image_evidence)
| InspectCIProgram
| InspectImageComposition.

Inductive meta_ci_response :=
| CIStateResponse (s : ci_state)
| ImageResponse (r : single_image_response)
| CIProgramResponse (p : list ci_instruction)
| ImageCompositionResponse (p : image_composition_plan).

Definition meta_ci_entrypoint (cmd : meta_ci_command) : meta_ci_response :=
  match cmd with
  | EvaluateCI e => CIStateResponse (evaluate_ci e)
  | RunImage c e => ImageResponse (single_image_entrypoint c e)
  | InspectCIProgram => CIProgramResponse selfhost_ci_program
  | InspectImageComposition => ImageCompositionResponse single_image_composition_plan
  end.

Definition retained_ci_program : list ci_instruction := selfhost_ci_program.
Definition retained_image_composition : image_composition_plan :=
  single_image_composition_plan.
