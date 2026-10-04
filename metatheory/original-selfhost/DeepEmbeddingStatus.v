From Stdlib Require Import String List Bool.
From MetaRocqRs.OriginalSelfHost Require Import
  PCUICCertificateIR PCUICDeepEmbeddingSchema SafeCheckerContract
  CertificateReplayIR HOL4RoundTripIR.

Import ListNotations.
Open Scope string_scope.

Inductive deep_embedding_blocker :=
| MissingHOLDatatypePrelude
| MissingPCUICEncodingRoundTrip
| MissingCheckerEncodingFaithfulness
| MissingCheckerSoundnessInHOL
| UndischargedGuardChecking
| UnaccountedSourceAssumptions
| MissingIndependentRoundTrip.

Definition current_deep_embedding_blockers : list deep_embedding_blocker :=
  [MissingHOLDatatypePrelude;
   MissingPCUICEncodingRoundTrip;
   MissingCheckerEncodingFaithfulness;
   MissingCheckerSoundnessInHOL;
   UndischargedGuardChecking;
   UnaccountedSourceAssumptions;
   MissingIndependentRoundTrip].

Definition deep_embedding_currently_publishable : bool := false.

Theorem deep_embedding_fails_closed :
  deep_embedding_currently_publishable = false.
Proof. reflexivity. Qed.
