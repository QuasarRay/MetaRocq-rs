From Stdlib Require Import String List Bool.
From MetaRocqRs.OriginalSelfHost Require Import
  MetaCIExtractionRoot DualProofLedger ReflectiveDualRecursion
  CandleExportContract.

Inductive dual_proof_command :=
| RunMetaCICommand (cmd : meta_ci_command)
| InspectDualProofLedger
| InspectCandleExportContract
| VerifyDualProofEvidence (e : dual_proof_evidence)
| VerifyReflectiveDualEvidence (e : reflective_dual_evidence).

Inductive dual_proof_response :=
| MetaCIResponse (r : meta_ci_response)
| DualProofLedgerResponse (jobs : list dual_proof_job)
| CandleContractResponse (layers : list candle_soundness_layer)
| DualProofAccepted
| DualProofBlocked
| ReflectiveDualAccepted
| ReflectiveDualBlocked.

Definition run_dual_proof_command
  (cmd : dual_proof_command) : dual_proof_response :=
  match cmd with
  | RunMetaCICommand c =>
      MetaCIResponse (meta_ci_entrypoint c)
  | InspectDualProofLedger =>
      DualProofLedgerResponse original_dual_proof_ledger
  | InspectCandleExportContract =>
      CandleContractResponse required_candle_soundness_layers
  | VerifyDualProofEvidence e =>
      if dual_proof_publishable e
      then DualProofAccepted
      else DualProofBlocked
  | VerifyReflectiveDualEvidence e =>
      if reflective_dual_verified e
      then ReflectiveDualAccepted
      else ReflectiveDualBlocked
  end.

Definition dual_proof_entrypoint := run_dual_proof_command.

Definition retained_dual_proof_ledger : list dual_proof_job :=
  original_dual_proof_ledger.

Definition retained_candle_soundness_layers : list candle_soundness_layer :=
  required_candle_soundness_layers.
