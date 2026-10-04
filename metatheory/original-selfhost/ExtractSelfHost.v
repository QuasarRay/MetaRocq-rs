From Peregrine.Plugin Require Import Loader.
From MetaRocqRs.OriginalSelfHost Require Import ExtractionRoot.

(* The resulting lambda-box program is the single MetaRocq-defined root.
   Candle/CakeML source composition is a later build layer; no successful proof
   claim is made merely because this extraction succeeds. *)
Peregrine Extract
  "generated/original-selfhost/selfhost.ast"
  MetaRocqRs.OriginalSelfHost.ExtractionRoot.selfhost_entrypoint.
