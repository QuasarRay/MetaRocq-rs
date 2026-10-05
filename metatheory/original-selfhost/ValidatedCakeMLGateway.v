From Stdlib Require Import String List.
From ExtLib Require Import Monads.
From MetaRocq.Utils Require Import ResultMonad.
From Peregrine Require Import Utils.
From MetaRocqRs.OriginalSelfHost Require Import
  EmbeddedPeregrine CandidateCakeMLCompiler
  CakeMLTranslationCertificate CakeMLBackendTrustLedger.

Import MonadNotation.
Local Open Scope monad.

Definition prepare_and_candidate_compile
  (attrs : list bytestring.String.string) (source : bytestring.String.string)
  : result' candidate_cakeml_ast :=
  p <- prepare_cakeml attrs source ;;
  candidate_compile_cakeml_ast p.

Inductive validated_cakeml_status :=
| CandidateOnly
| SemanticallyCertified.

Record validated_cakeml_gateway := {
  gateway_status : validated_cakeml_status;
  gateway_backend_ledger_closed : bool;
  gateway_certificate : cakeml_translation_certificate
}.

Definition current_validated_gateway : validated_cakeml_gateway :=
  {| gateway_status := CandidateOnly;
     gateway_backend_ledger_closed := backend_trust_ledger_closed;
     gateway_certificate := unresolved_cakeml_translation |}.

Definition validated_gateway_publishable : bool :=
  current_validated_gateway.(gateway_backend_ledger_closed)
  && match current_validated_gateway.(gateway_status) with
     | CandidateOnly => false
     | SemanticallyCertified =>
         accept_cakeml_translation
           current_validated_gateway.(gateway_certificate)
     end.
