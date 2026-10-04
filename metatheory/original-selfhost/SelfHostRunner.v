From Stdlib Require Import String List Bool.
From MetaRocqRs.OriginalSelfHost Require Import
  RuntimeImage RetainedPayload PipelineIR.

Open Scope string_scope.

Inductive selfhost_command :=
| VerifySelf
| InspectArchitecture
| InspectRetainedPayload.

Record runtime_evidence := {
  evidence_source_identity_matches : bool;
  evidence_candle_accepts_all_articles : bool;
  evidence_cakeml_verified_compile_path : bool;
  evidence_binary_replay_matches : bool;
  evidence_used_peregrine_trust_axiom : bool
}.

Inductive selfhost_response :=
| SelfVerified
| SelfBlocked (reason : string)
| ArchitectureResponse (a : runtime_architecture)
| PayloadResponse (p : retained_proof_payload).

Definition verify_evidence (e : runtime_evidence) : selfhost_response :=
  if negb runtime_architecture_well_formed then
    SelfBlocked "runtime architecture manifest is inconsistent"
  else if negb snapshot_count_matches_manifest then
    SelfBlocked "baked PCUIC snapshot does not match pinned module manifest"
  else if negb proof_payload_publishable then
    SelfBlocked "OpenTheory proof payload is not publishable"
  else if negb e.(evidence_source_identity_matches) then
    SelfBlocked "runtime source identities do not match the pinned self image"
  else if e.(evidence_used_peregrine_trust_axiom) then
    SelfBlocked "forbidden Peregrine trust_coq_kernel shortcut was used"
  else if negb e.(evidence_candle_accepts_all_articles) then
    SelfBlocked "embedded Candle/OpenTheory checker rejected the proof payload"
  else if negb e.(evidence_cakeml_verified_compile_path) then
    SelfBlocked "machine image is not connected to the verified CakeML compiler path"
  else if negb e.(evidence_binary_replay_matches) then
    SelfBlocked "machine-code replay did not reproduce the retained proof result"
  else SelfVerified.

Definition run_selfhost
  (cmd : selfhost_command) (e : runtime_evidence) : selfhost_response :=
  match cmd with
  | VerifySelf => verify_evidence e
  | InspectArchitecture => ArchitectureResponse selfhost_runtime_architecture
  | InspectRetainedPayload => PayloadResponse original_selfhost_payload
  end.
