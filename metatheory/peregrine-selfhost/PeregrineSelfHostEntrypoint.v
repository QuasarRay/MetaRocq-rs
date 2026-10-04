From Stdlib Require Import String List Bool.
From Peregrine Require Import Pipeline Config.
From MetaRocqRs.PeregrineSelfHost Require Import PeregrineProofCorpus.

Import ListNotations.
Open Scope string_scope.

Inductive peregrine_selfhost_command :=
| RunPeregrine
    (config : string + Peregrine.Config.config')
    (attributes : list string)
    (source : string)
    (file_name : string)
| InspectPeregrineProofCorpus
| InspectPeregrineAssumptions
| InspectPeregrineReplayJobs
| VerifyRetainedReplayEvidence
    (evidence : list peregrine_replay_evidence).

Inductive peregrine_selfhost_response :=
| PeregrineRunResult (r : Peregrine.Pipeline.extraction_result)
| PeregrineProofCorpusResponse (xs : list peregrine_theorem_certificate)
| PeregrineAssumptionResponse (xs : list peregrine_source_assumption)
| PeregrineReplayJobsResponse (xs : list peregrine_replay_job)
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
  | VerifyRetainedReplayEvidence evidence =>
      if accept_peregrine_replay_corpus evidence
      then PeregrineReplayAccepted
      else PeregrineReplayBlocked
  end.

Definition retained_peregrine_proof_corpus := peregrine_certificate_corpus.
Definition retained_peregrine_assumption_ledger := peregrine_assumption_ledger.
Definition retained_peregrine_replay_jobs := peregrine_replay_jobs.
