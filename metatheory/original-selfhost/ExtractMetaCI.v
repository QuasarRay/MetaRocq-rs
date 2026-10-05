From Peregrine.Plugin Require Import Loader.
From MetaRocqRs.OriginalSelfHost Require Import MetaCIExtractionRoot.

Peregrine Extract
  "generated/original-selfhost/meta-ci.ast"
  MetaRocqRs.OriginalSelfHost.MetaCIExtractionRoot.meta_ci_entrypoint.
