From Stdlib Require Import String Bool.
From MetaRocqRs.OriginalSelfHost Require Import
  ValidatedCakeMLGateway SingleImageContract.

Open Scope string_scope.

Record recursive_identity := {
  identity_source_snapshot_digest : string;
  identity_retained_pcuic_digest : string;
  identity_opentheory_digest : string;
  identity_cakeml_suffix_digest : string;
  identity_machine_image_digest : string;
  identity_ci_plan_digest : string;
  identity_runtime_reports_same_architecture : bool;
  identity_machine_replay_reports_same_claims : bool
}.

Definition nonempty (s : string) : bool :=
  negb (String.eqb s EmptyString).

Definition accept_recursive_identity (i : recursive_identity) : bool :=
  nonempty i.(identity_source_snapshot_digest)
  && nonempty i.(identity_retained_pcuic_digest)
  && nonempty i.(identity_opentheory_digest)
  && nonempty i.(identity_cakeml_suffix_digest)
  && nonempty i.(identity_machine_image_digest)
  && nonempty i.(identity_ci_plan_digest)
  && i.(identity_runtime_reports_same_architecture)
  && i.(identity_machine_replay_reports_same_claims)
  && validated_gateway_publishable.

Definition unresolved_recursive_identity : recursive_identity :=
  {| identity_source_snapshot_digest := "";
     identity_retained_pcuic_digest := "";
     identity_opentheory_digest := "";
     identity_cakeml_suffix_digest := "";
     identity_machine_image_digest := "";
     identity_ci_plan_digest := "";
     identity_runtime_reports_same_architecture := false;
     identity_machine_replay_reports_same_claims := false |}.
