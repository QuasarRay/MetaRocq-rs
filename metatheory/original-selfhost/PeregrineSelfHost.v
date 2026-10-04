From Peregrine.Plugin Require Import Loader.
From MetaRocqRs.OriginalSelfHost Require Import SelfHostRunner.

(* Extract the MetaRocq-owned acceptance pipeline itself.  The extracted
   component remains parameterized by [candle_backend]; the CakeML linkage
   layer must supply the verified reader implementation rather than an
   unverified boolean oracle. *)
Peregrine Extract
  "generated/original-metarocq-selfhost/selfhost-runner.ast"
  MetaRocqRs.OriginalSelfHost.SelfHostRunner.run.
