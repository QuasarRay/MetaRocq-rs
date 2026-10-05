From Stdlib Require Import String List.
From MetaRocq.Utils Require Import ResultMonad.
From Peregrine Require Import Utils.
From MetaRocqRs.OriginalSelfHost Require Import
  ValidatedSharedImageEntrypoint CheckedCandidateCakeML
  CandidateCakeMLCompiler.

Inductive checked_shared_command :=
| RunValidatedImage (cmd : validated_shared_command)
| CheckedCompileCakeML (attrs : list bytestring.String.string)
    (source : bytestring.String.string).

Inductive checked_shared_response :=
| ValidatedLayerResponse (r : validated_shared_response)
| CheckedCakeMLResponse (r : result' candidate_cakeml_ast).

Definition checked_shared_image_entrypoint
  (cmd : checked_shared_command)
  (runtime : runtime_evidence)
  (image : image_evidence)
  (dual : list dual_evidence)
  (identity : recursive_identity) : checked_shared_response :=
  match cmd with
  | RunValidatedImage c =>
      ValidatedLayerResponse
        (validated_shared_image_entrypoint c runtime image dual identity)
  | CheckedCompileCakeML attrs source =>
      CheckedCakeMLResponse
        (prepare_and_checked_compile attrs source)
  end.
