From Stdlib Require Import String List Bool.
From MetaRocqRs.OriginalSelfHost Require Import
  CandlePrefixManifest MetaRocqSuffixSafety EmbeddedPeregrine
  SingleImageContract.

Import ListNotations.
Open Scope string_scope.

Record shared_cakeml_source_image := {
  shared_prefix_revision : string;
  shared_prefix_program : string;
  shared_suffix : cakeml_suffix_certificate;
  shared_candle_prefix_theorems_bound : bool;
  shared_compiler_theorem_bound : bool;
  shared_peregrine_frontend_embedded : bool
}.

Definition metarocq_candle_shared_source : shared_cakeml_source_image :=
  {| shared_prefix_revision :=
       "c98da7fc904c5d6d0e9a75a18fac1796a9bfb1f9";
     shared_prefix_program := "compiler64_prog";
     shared_suffix := unresolved_metaself_suffix;
     shared_candle_prefix_theorems_bound := candle_prefix_binding_count_ok;
     shared_compiler_theorem_bound := candle_prefix_binding_count_ok;
     shared_peregrine_frontend_embedded := true |}.

Definition shared_source_publishable
  (s : shared_cakeml_source_image) : bool :=
  s.(shared_candle_prefix_theorems_bound)
  && s.(shared_compiler_theorem_bound)
  && s.(shared_peregrine_frontend_embedded)
  && embedded_peregrine_backend_publishable
  && accept_suffix_certificate s.(shared_suffix).

(* This deliberately remains false until the Peregrine CakeML proof holes are
   reconstructed and the generated MetaRocq CakeML declarations have an
   EVERY safe_dec proof compatible with Candle's theorem. *)
Definition shared_source_ready : bool :=
  shared_source_publishable metarocq_candle_shared_source.
