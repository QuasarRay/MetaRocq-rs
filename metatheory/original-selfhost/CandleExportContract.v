From Stdlib Require Import String List Bool Arith.
From MetaRocqRs.OriginalSelfHost Require Import
  VerifiedRuntimeAnchors HOLProofIR OpenTheoryIR.

Import ListNotations.
Open Scope string_scope.

Inductive candle_soundness_layer :=
| CandleKernelPrefixSoundness
| CandleReasonableResidual
| CandleVerifiedCompilerTransport
| CandleKernelControlledExport
| CandleInstalledMachineImage.

Definition required_candle_soundness_layers : list candle_soundness_layer :=
  [CandleKernelPrefixSoundness;
   CandleReasonableResidual;
   CandleVerifiedCompilerTransport;
   CandleKernelControlledExport;
   CandleInstalledMachineImage].

Definition candle_kernel_export_api : string := "Kernel.print_thm".
Definition candle_opentheory_export_opcode : string := "thm".

Record candle_export_evidence := {
  candle_prefix_soundness_proved : bool;
  candle_residual_reasonable_proved : bool;
  candle_compiler_transport_proved : bool;
  candle_export_channel_kernel_controlled : bool;
  candle_reader_machine_code_proved : bool
}.

Definition candle_export_evidence_complete
  (e : candle_export_evidence) : bool :=
  e.(candle_prefix_soundness_proved)
  && e.(candle_residual_reasonable_proved)
  && e.(candle_compiler_transport_proved)
  && e.(candle_export_channel_kernel_controlled)
  && e.(candle_reader_machine_code_proved).

Definition candle_contract_shape_ok : bool :=
  Nat.eqb (List.length required_candle_soundness_layers) 5
  && verified_runtime_anchor_count_ok.

Theorem candle_contract_has_expected_shape :
  candle_contract_shape_ok = true.
Proof. reflexivity. Qed.

Theorem missing_kernel_control_blocks_export :
  forall prefix residual compiler machine,
    candle_export_evidence_complete
      {| candle_prefix_soundness_proved := prefix;
         candle_residual_reasonable_proved := residual;
         candle_compiler_transport_proved := compiler;
         candle_export_channel_kernel_controlled := false;
         candle_reader_machine_code_proved := machine |} = false.
Proof.
  intros.
  unfold candle_export_evidence_complete.
  destruct prefix, residual, compiler; reflexivity.
Qed.

Theorem missing_machine_code_anchor_blocks_export :
  forall prefix residual compiler channel,
    candle_export_evidence_complete
      {| candle_prefix_soundness_proved := prefix;
         candle_residual_reasonable_proved := residual;
         candle_compiler_transport_proved := compiler;
         candle_export_channel_kernel_controlled := channel;
         candle_reader_machine_code_proved := false |} = false.
Proof.
  intros.
  unfold candle_export_evidence_complete.
  destruct prefix, residual, compiler, channel; reflexivity.
Qed.
