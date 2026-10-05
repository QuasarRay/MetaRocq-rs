From MetaRocqRs.OriginalSelfHost Require Import
  SingleImageRunner SingleImageContract VerifiedRuntimeAnchors RecursiveTrustGraph.

Definition single_image_entrypoint
  (cmd : single_image_command) (ev : single_image_evidence)
  : single_image_response :=
  run_single_image cmd ev.

(* Retain both parallel single-image proof architectures. *)
Definition retained_single_image_contract : single_image_contract :=
  original_metarocq_single_image.

Definition retained_anchored_single_image_contract :
  anchored_single_image_contract :=
  original_metarocq_anchored_single_image_contract.

Definition retained_machine_theorem_anchors :
  list verified_theorem_anchor :=
  verified_runtime_anchors.

Definition retained_recursive_trust_graph : list trust_edge :=
  trust_edges.
