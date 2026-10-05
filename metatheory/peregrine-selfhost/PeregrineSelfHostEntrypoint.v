From Stdlib Require Import String List Bool.
From Peregrine Require Import Pipeline Config ConfigUtils.
From MetaRocqRs.PeregrineSelfHost Require Import
  PeregrineProofCorpus PeregrineRuntimeReplay.

Import ListNotations.
Open Scope string_scope.

Inductive peregrine_selfhost_command :=
| RunPeregrine
    (config : string + Peregrine.ConfigUtils.config')
    (attributes : list string)
    (source : string)
    (file_name : string)
| InspectPeregrineProofCorpus
| InspectPeregrineAssumptions
| InspectPeregrineReplayJobs
| ReplayPeregrineRuntimeProofs
| VerifyRetainedReplayEvidence
    (evidence : list peregrine_replay_evidence).

Inductive peregrine_selfhost_response :=
| PeregrineRunResult (r : Peregrine.Pipeline.extraction_result)
| PeregrineProofCorpusResponse (xs : list peregrine_theorem_certificate)
| PeregrineAssumptionResponse (xs : list peregrine_source_assumption)
| PeregrineReplayJobsResponse (xs : list peregrine_replay_job)
| PeregrineRuntimeReplayResult (accepted : bool)
| PeregrineReplayAccepted
| PeregrineReplayBlocked.

Definition peregrine_selfhost_entrypoint
  (cmd : peregrine_selfhost_command) : peregrine_selfhost_response :=
  match cmd with
  | RunPeregrine config attributes source file_name =>
      PeregrineRunResult
        (Peregrine.Pipeline.peregrine_pipeline
           config attributes source file_name)
  | InspectPeregrineProofCorpus =>
      PeregrineProofCorpusResponse peregrine_certificate_corpus
  | InspectPeregrineAssumptions =>
      PeregrineAssumptionResponse peregrine_assumption_ledger
  | InspectPeregrineReplayJobs =>
      PeregrineReplayJobsResponse peregrine_replay_jobs
  | ReplayPeregrineRuntimeProofs =>
      PeregrineRuntimeReplayResult replay_peregrine_runtime_program
  | VerifyRetainedReplayEvidence evidence =>
      if accept_peregrine_replay_corpus evidence
      then PeregrineReplayAccepted
      else PeregrineReplayBlocked
  end.

Definition retained_peregrine_proof_corpus := peregrine_certificate_corpus.
Definition retained_peregrine_assumption_ledger := peregrine_assumption_ledger.
Definition retained_peregrine_replay_jobs := peregrine_replay_jobs.
Definition retained_peregrine_runtime_replay_program :=
  peregrine_runtime_replay_program.


(*
  Closed runtime root for the generated CakeML program.

  CakeML's serialized module evaluates the extracted root as the body of its
  top-level [main] declaration.  Therefore this conditional forces the
  retained replay checker to run during program initialization.  The normal
  dispatcher is only retained in the resulting value when that replay
  succeeds.  This is an executable fail-closed gate, not a replacement for the
  later HOL4 source-to-machine theorem.
*)
Inductive peregrine_selfhost_runtime :=
| PeregrineRuntimeReady
    (dispatch : peregrine_selfhost_command -> peregrine_selfhost_response)
| PeregrineRuntimeReplayRejected.

Definition peregrine_selfhost_runtime_root : peregrine_selfhost_runtime :=
  if replay_peregrine_runtime_program
  then PeregrineRuntimeReady peregrine_selfhost_entrypoint
  else PeregrineRuntimeReplayRejected.
