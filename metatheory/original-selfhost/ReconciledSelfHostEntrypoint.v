From Stdlib Require Import String List.
From MetaRocqRs.OriginalSelfHost Require Import
  CheckedSharedImageEntrypoint PCUICCertificateIR CertificateReplayIR
  DeepEmbeddingStatus CandleExportContract HOL4RoundTripIR
  SelfCICDInterpreter DualProofLedger ReflectiveDualRecursion.

Inductive reconciled_selfhost_command :=
| RunCheckedSelfImage (cmd : checked_shared_command)
| InspectPCUICCertificates
| InspectPCUICAssumptions
| InspectCertificateReplayJobs
| InspectDeepEmbeddingBlockers
| InspectCandleExportLayers
| InspectHOL4RoundTripPolicy
| EvaluateSelfCI (e : self_ci_evidence)
| VerifyCertificateDual (e : certificate_dual_evidence)
| VerifyReflectiveDual (e : reflective_dual_evidence).

Inductive reconciled_selfhost_response :=
| CheckedSelfImageResponse (r : checked_shared_response)
| PCUICCertificatesResponse (xs : list pcuic_theorem_certificate)
| PCUICAssumptionsResponse (xs : list pcuic_source_assumption)
| CertificateReplayJobsResponse (xs : list certificate_replay_job)
| DeepEmbeddingBlockersResponse (xs : list deep_embedding_blocker)
| CandleExportLayersResponse (xs : list candle_soundness_layer)
| HOL4RoundTripPolicyResponse (p : hol4_reuse_policy)
| SelfCIStateResponse (s : self_ci_state)
| CertificateDualAccepted
| CertificateDualBlocked
| ReflectiveDualAccepted
| ReflectiveDualBlocked.

Definition reconciled_selfhost_entrypoint
  (cmd : reconciled_selfhost_command)
  (runtime : runtime_evidence)
  (image : image_evidence)
  (dual : list dual_evidence)
  (identity : recursive_identity) : reconciled_selfhost_response :=
  match cmd with
  | RunCheckedSelfImage c =>
      CheckedSelfImageResponse
        (checked_shared_image_entrypoint c runtime image dual identity)
  | InspectPCUICCertificates =>
      PCUICCertificatesResponse original_pcuic_certificate_corpus
  | InspectPCUICAssumptions =>
      PCUICAssumptionsResponse original_pcuic_assumption_ledger
  | InspectCertificateReplayJobs =>
      CertificateReplayJobsResponse original_pcuic_replay_jobs
  | InspectDeepEmbeddingBlockers =>
      DeepEmbeddingBlockersResponse current_deep_embedding_blockers
  | InspectCandleExportLayers =>
      CandleExportLayersResponse required_candle_soundness_layers
  | InspectHOL4RoundTripPolicy =>
      HOL4RoundTripPolicyResponse selfhost_hol4_reuse_policy
  | EvaluateSelfCI e =>
      SelfCIStateResponse (evaluate_self_ci e)
  | VerifyCertificateDual e =>
      if accept_certificate_dual_evidence e
      then CertificateDualAccepted
      else CertificateDualBlocked
  | VerifyReflectiveDual e =>
      if reflective_dual_verified e
      then ReflectiveDualAccepted
      else ReflectiveDualBlocked
  end.

(* These anchors intentionally make the full certificate corpus, assumption
   ledger and replay program reachable from the single extraction root so they
   survive ordinary proof erasure as executable data. *)
Definition retained_pcuic_certificates : list pcuic_theorem_certificate :=
  original_pcuic_certificate_corpus.

Definition retained_pcuic_assumptions : list pcuic_source_assumption :=
  original_pcuic_assumption_ledger.

Definition retained_certificate_replay_jobs : list certificate_replay_job :=
  original_pcuic_replay_jobs.
