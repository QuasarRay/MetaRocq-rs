From Stdlib Require Import String List Bool.
From MetaRocqRs.OriginalSelfHost Require Import PipelineIR PCUICModuleManifest.

Import ListNotations.
Open Scope string_scope.

Inductive runtime_component_kind :=
| EmbeddedMetaRocq
| EmbeddedPeregrine
| EmbeddedCandleReader
| EmbeddedCakeMLCompiler.

Inductive assurance_class :=
| ProvedRuntime
| VerifiedExternalComponent
| TranslationProducerOnly.

Record runtime_component := {
  runtime_kind : runtime_component_kind;
  runtime_repository : string;
  runtime_revision : string;
  runtime_role : string;
  runtime_assurance : assurance_class
}.

Definition metarocq_component : runtime_component :=
  {| runtime_kind := EmbeddedMetaRocq;
     runtime_repository := "https://github.com/MetaRocq/metarocq.git";
     runtime_revision := "7197056adbb9c15288b4c8d43407bf25786f723e";
     runtime_role := "self-reflective PCUIC quotation and proof pipeline";
     runtime_assurance := ProvedRuntime |}.

Definition peregrine_component : runtime_component :=
  {| runtime_kind := EmbeddedPeregrine;
     runtime_repository := "https://github.com/peregrine-project/peregrine-tool.git";
     runtime_revision := "d768b83ffa7dab35b8d72241f0570b5bb6aedae9";
     runtime_role := "lambda-box and CakeML translation producer";
     runtime_assurance := TranslationProducerOnly |}.

Definition candle_component : runtime_component :=
  {| runtime_kind := EmbeddedCandleReader;
     runtime_repository := "https://github.com/CakeML/cakeml.git";
     runtime_revision := "c98da7fc904c5d6d0e9a75a18fac1796a9bfb1f9";
     runtime_role := "verified OpenTheory reader and Candle HOL kernel";
     runtime_assurance := VerifiedExternalComponent |}.

Definition cakeml_component : runtime_component :=
  {| runtime_kind := EmbeddedCakeMLCompiler;
     runtime_repository := "https://github.com/CakeML/cakeml.git";
     runtime_revision := "c98da7fc904c5d6d0e9a75a18fac1796a9bfb1f9";
     runtime_role := "verified compiler and Candle-capable REPL runtime";
     runtime_assurance := VerifiedExternalComponent |}.

Definition runtime_components : list runtime_component :=
  [metarocq_component; peregrine_component; candle_component; cakeml_component].

(* The pinned Peregrine CakeML backend contains [trust_coq_kernel].  It may
   produce code, but this experiment never treats that axiom as proof evidence. *)
Definition forbidden_peregrine_shortcut : string :=
  "Peregrine.theories.backends.CakeMLBackend.trust_coq_kernel".

Record runtime_architecture := {
  runtime_manifest : list runtime_component;
  runtime_pipeline : list OriginalMetaRocqSelfHost.stage;
  runtime_expected_pcuic_modules : nat;
  runtime_single_machine_image : bool;
  runtime_retains_proof_payload : bool;
  runtime_forbids_peregrine_trust_axiom : bool
}.

Definition selfhost_runtime_architecture : runtime_architecture :=
  {| runtime_manifest := runtime_components;
     runtime_pipeline := OriginalMetaRocqSelfHost.trusted_path;
     runtime_expected_pcuic_modules := PCUICModuleManifest.expected_module_count;
     runtime_single_machine_image := true;
     runtime_retains_proof_payload := true;
     runtime_forbids_peregrine_trust_axiom := true |}.

Definition runtime_architecture_well_formed : bool :=
  Nat.eqb (List.length selfhost_runtime_architecture.(runtime_manifest)) 4
  && selfhost_runtime_architecture.(runtime_single_machine_image)
  && selfhost_runtime_architecture.(runtime_retains_proof_payload)
  && selfhost_runtime_architecture.(runtime_forbids_peregrine_trust_axiom).
