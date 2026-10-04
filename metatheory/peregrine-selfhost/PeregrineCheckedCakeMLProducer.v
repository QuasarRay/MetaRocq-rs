From Stdlib Require Import String List.
From MetaRocq.Utils Require Import ResultMonad.
From MetaRocq.Common Require Import Kernames.
From MetaRocq.Erasure Require Import EAst.
From CeresBS Require Import CeresSerialize.
From CakeML.Backend Require Import Serialize.
From Peregrine Require Import PAst.
From MetaRocqRs.OriginalSelfHost Require Import
  EmbeddedPeregrine CheckedCandidateCakeML.

Import ListNotations.
Import MonadNotation.

(*
  Executable engineering adapter only.

  This module deliberately contains no new correctness theorem.  It reuses the
  already-existing checked Peregrine frontend / PAst-to-EAst / CakeML compiler
  path and the pinned CakeML serializer so that execution can produce a
  candidate without invoking Peregrine.CakeMLBackend.cakeml_pipeline.

  The final source-to-machine correctness theorem remains a separate,
  fail-closed formalization gate.
*)

Fixpoint checked_cakeml_export_names (t : EAst.term) : list ident :=
  match t with
  | EAst.tConst kn => [Kernames.string_of_kername kn]
  | EAst.tApp u v =>
      checked_cakeml_export_names u ++ checked_cakeml_export_names v
  | _ => []
  end.

Definition checked_lambdabox_to_serialized_cakeml
  (attrs : list string) (source : string) :=
  p <- EmbeddedPeregrine.prepare_cakeml attrs source ;;
  ep <- PAst_to_EAst p ;;
  out <- CheckedCandidateCakeML.checked_candidate_compile_past p ;;
  let nms := checked_cakeml_export_names (snd ep) in
  let code :=
    @CeresSerialize.to_string _
      (Serialize_module (List.rev nms)) out in
  Ok (nms, code).
