From MetaRocqRs.OriginalSelfHost Require Import
  SelfHostRunner RuntimeImage RetainedPayload.

(* [selfhost_entrypoint] deliberately exposes architecture and retained payload
   inspection commands in addition to verification.  This makes the complete
   PCUIC self-snapshot and proof program reachable from the extraction root,
   rather than relying on proof terms that ordinary erasure would remove. *)
Definition selfhost_entrypoint
  (cmd : selfhost_command) (e : runtime_evidence) : selfhost_response :=
  run_selfhost cmd e.

Definition retained_architecture_anchor : runtime_architecture :=
  selfhost_runtime_architecture.

Definition retained_payload_anchor : retained_proof_payload :=
  original_selfhost_payload.
