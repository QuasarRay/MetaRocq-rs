From Stdlib Require Import List.
From MetaRocq.Utils Require Import ResultMonad bytestring.
From Peregrine Require Import PAst.
From MetaRocqRs.OriginalSelfHost Require Import
  SingleImageEntrypoint CandlePrefixComposition RecursiveSelfIdentity
  EmbeddedPeregrine.

Inductive shared_image_command :=
| RunSingleImage (cmd : single_image_command)
| InspectCandlePrefix
| ValidateLambdaBoxForEmbeddedPeregrine (attrs : list string) (source : string)
| VerifyRecursiveIdentity.

Inductive shared_image_response :=
| SingleImageLayerResponse (r : single_image_response)
| CandlePrefixResponse (s : shared_cakeml_source_image)
| PeregrineValidationResponse (r : result' PAst)
| RecursiveIdentityAccepted
| RecursiveIdentityBlocked.

Definition shared_image_entrypoint
  (cmd : shared_image_command)
  (runtime : runtime_evidence)
  (image : image_evidence)
  (dual : list dual_evidence)
  (identity : recursive_identity) : shared_image_response :=
  match cmd with
  | RunSingleImage c =>
      SingleImageLayerResponse
        (single_image_entrypoint c runtime image dual)
  | InspectCandlePrefix =>
      CandlePrefixResponse metarocq_candle_shared_source
  | ValidateLambdaBoxForEmbeddedPeregrine attrs source =>
      PeregrineValidationResponse (prepare_cakeml attrs source)
  | VerifyRecursiveIdentity =>
      if accept_recursive_identity identity
      then RecursiveIdentityAccepted
      else RecursiveIdentityBlocked
  end.
