(* Quotation and its kernel check compile separately, releasing their working memory. *)
From Peregrine.Plugin Require Import Loader.
Require Import RetainedQuote.

Peregrine Extract Typed "retained.ast" retained_export.
