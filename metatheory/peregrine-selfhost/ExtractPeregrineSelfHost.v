From Peregrine.Plugin Require Import Loader.
From MetaRocqRs.PeregrineSelfHost Require Import
  MaterializePeregrineSnapshot PeregrineSelfHostEntrypoint.

Peregrine Extract
  "generated/peregrine-selfhost/peregrine-selfhost.ast"
  MetaRocqRs.PeregrineSelfHost.PeregrineSelfHostEntrypoint.peregrine_selfhost_runtime_root.
