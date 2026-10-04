From Peregrine.Plugin Require Import Loader.
From MetaRocqRs.OriginalSelfHost Require Import SelfHostProgram.

(* The lambda-box entry point is self-contained with respect to MetaRocq proof
   material: it reads the baked PCUIC snapshot and invokes the internal
   PCUIC-to-HOL lowering.  The only external argument is the verified Candle
   checker function that is linked into the same CakeML program. *)
Peregrine Extract
  "generated/original-metarocq-selfhost/selfhost-runner.ast"
  MetaRocqRs.OriginalSelfHost.SelfHostProgram.selfhost_main.
