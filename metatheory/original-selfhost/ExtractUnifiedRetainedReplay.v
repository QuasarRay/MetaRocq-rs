From Peregrine.Plugin Require Import Loader.
From MetaRocqRs.OriginalSelfHost Require Import UnifiedRetainedReplay.

(* Candidate artifact only: pending replay/refinement obligations are data in
   the same program as the retained source declarations and opaque proofs. *)
Peregrine Extract
  "generated/peregrine-selfhost/three-project-replay/retained-three-projects.ast"
  MetaRocqRs.OriginalSelfHost.UnifiedRetainedReplay.unified_retained_runtime_root.
