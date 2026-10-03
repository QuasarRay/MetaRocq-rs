(* Original definition is imported, not reimplemented. MIT-licensed MetaRocq. *)
From MetaRocq.PCUIC Require Import PCUICAst.
From Peregrine.Plugin Require Import Loader.

(* Small first extraction slice; this is NOT the MetaRocq safe checker. *)
Peregrine Extract Typed "candidate.ast" PCUICAst.isApp.
