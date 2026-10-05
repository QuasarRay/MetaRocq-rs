From Peregrine Require Import Extraction.
From MetaRocqRs.PeregrineSelfHost Require Import
  PeregrineCheckedCakeMLProducer.

(*
  Reuse Peregrine's own Rocq -> OCaml extraction configuration.  The generated
  executable is an engineering producer only; it does not add or replace any
  formal correctness theorem.
*)
Set Extraction Output Directory
  "generated/peregrine-selfhost/checked-extraction/".

Separate Extraction
  PeregrineCheckedCakeMLProducer.checked_lambdabox_to_serialized_cakeml.
