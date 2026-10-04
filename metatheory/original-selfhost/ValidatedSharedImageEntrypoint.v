From Stdlib Require Import String List.
From MetaRocq.Utils Require Import ResultMonad.
From MetaRocqRs.OriginalSelfHost Require Import
  SharedImageEntrypoint ValidatedCakeMLGateway
  CakeMLBackendTrustLedger CakeMLTranslationCertificate
  CandidateCakeMLCompiler.

Inductive validated_shared_command :=
| RunSharedImage (cmd : shared_image_command)
| CandidateCompileCakeML (attrs : list string) (source : string)
| InspectCakeMLBackendTrust
| InspectCakeMLTranslationCertificate
| VerifyValidatedCakeMLGateway.

Inductive validated_shared_response :=
| SharedLayerResponse (r : shared_image_response)
| CandidateCakeMLResponse (r : result' candidate_cakeml_ast)
| BackendTrustLedgerResponse (gaps : list backend_gap)
| TranslationCertificateResponse (c : cakeml_translation_certificate)
| ValidatedGatewayAccepted
| ValidatedGatewayBlocked.

Definition validated_shared_image_entrypoint
  (cmd : validated_shared_command)
  (runtime : runtime_evidence)
  (image : image_evidence)
  (dual : list dual_evidence)
  (identity : recursive_identity) : validated_shared_response :=
  match cmd with
  | RunSharedImage c =>
      SharedLayerResponse
        (shared_image_entrypoint c runtime image dual identity)
  | CandidateCompileCakeML attrs source =>
      CandidateCakeMLResponse
        (prepare_and_candidate_compile attrs source)
  | InspectCakeMLBackendTrust =>
      BackendTrustLedgerResponse cake_backend_gaps
  | InspectCakeMLTranslationCertificate =>
      TranslationCertificateResponse
        current_validated_gateway.(gateway_certificate)
  | VerifyValidatedCakeMLGateway =>
      if validated_gateway_publishable
      then ValidatedGatewayAccepted
      else ValidatedGatewayBlocked
  end.
