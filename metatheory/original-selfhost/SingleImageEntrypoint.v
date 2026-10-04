From Stdlib Require Import List.
From MetaRocqRs.OriginalSelfHost Require Import
  SelfHostRunner SingleImageContract SelfCICD CandleMachineChain DualProofLedger.

Inductive single_image_command :=
| RunMetaRocq (cmd : selfhost_command)
| InspectSingleImage
| InspectSelfCI
| InspectMachineChain
| VerifySingleImage.

Inductive single_image_response :=
| MetaRocqResponse (r : selfhost_response)
| SingleImageResponse (c : single_image_contract)
| SelfCIResponse (p : list ci_job)
| MachineChainResponse (p : list chain_obligation)
| SingleImageVerified
| SingleImageBlocked.

Definition single_image_entrypoint
  (cmd : single_image_command)
  (runtime : runtime_evidence)
  (image : image_evidence)
  (dual : list dual_evidence) : single_image_response :=
  match cmd with
  | RunMetaRocq c => MetaRocqResponse (run_selfhost c runtime)
  | InspectSingleImage => SingleImageResponse original_metarocq_single_image
  | InspectSelfCI => SelfCIResponse self_ci_pipeline
  | InspectMachineChain => MachineChainResponse candle_machine_chain
  | VerifySingleImage =>
      if accept_single_image image dual
      then SingleImageVerified
      else SingleImageBlocked
  end.
