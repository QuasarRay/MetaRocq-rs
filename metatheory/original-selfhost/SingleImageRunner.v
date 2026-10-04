From Stdlib Require Import String List Bool.
From MetaRocqRs.OriginalSelfHost Require Import
  SelfHostRunner VerifiedRuntimeAnchors RecursiveTrustGraph SingleImageContract.

Open Scope string_scope.

Record single_image_evidence := {
  image_selfhost_evidence : runtime_evidence;
  image_recursive_evidence : recursive_trust_evidence;
  image_metasource_bytes_match : bool;
  image_peregrine_bytes_match : bool;
  image_candle_bytes_match : bool;
  image_compiler_bytes_match : bool;
  image_link_layout_match : bool
}.

Inductive single_image_command :=
| RunSelfHostCommand (cmd : selfhost_command)
| InspectVerifiedRuntimeAnchors
| InspectRecursiveTrustGraph
| VerifySingleImage.

Inductive single_image_response :=
| DelegatedSelfHostResponse (r : selfhost_response)
| VerifiedAnchorsResponse (xs : list verified_theorem_anchor)
| RecursiveTrustGraphResponse (xs : list trust_edge)
| SingleImageVerified
| SingleImageBlocked (reason : string).

Definition verify_single_image (ev : single_image_evidence)
  : single_image_response :=
  if negb single_image_contract_structurally_valid then
    SingleImageBlocked "single-image contract structure is invalid"
  else
    match run_selfhost VerifySelf ev.(image_selfhost_evidence) with
    | SelfVerified =>
        if negb
             (verify_claim 7 RecursiveSelfImage
                ev.(image_recursive_evidence))
        then SingleImageBlocked "recursive trust chain did not terminate in the bootstrap seed"
        else if negb ev.(image_metasource_bytes_match)
             then SingleImageBlocked "embedded MetaRocq source identity mismatch"
        else if negb ev.(image_peregrine_bytes_match)
             then SingleImageBlocked "embedded Peregrine source identity mismatch"
        else if negb ev.(image_candle_bytes_match)
             then SingleImageBlocked "embedded Candle/OpenTheory source identity mismatch"
        else if negb ev.(image_compiler_bytes_match)
             then SingleImageBlocked "embedded CakeML compiler source identity mismatch"
        else if negb ev.(image_link_layout_match)
             then SingleImageBlocked "machine image does not contain the required linked members"
        else SingleImageVerified
    | SelfBlocked reason => SingleImageBlocked reason
    | _ => SingleImageBlocked "selfhost verification did not return a proof result"
    end.

Definition run_single_image
  (cmd : single_image_command) (ev : single_image_evidence)
  : single_image_response :=
  match cmd with
  | RunSelfHostCommand c =>
      DelegatedSelfHostResponse
        (run_selfhost c ev.(image_selfhost_evidence))
  | InspectVerifiedRuntimeAnchors =>
      VerifiedAnchorsResponse verified_runtime_anchors
  | InspectRecursiveTrustGraph =>
      RecursiveTrustGraphResponse trust_edges
  | VerifySingleImage => verify_single_image ev
  end.
