From Stdlib Require Import String Bool.
From MetaRocqRs.OriginalSelfHost Require Import
  SourceLambdaBoxRefinement HOL4MachineRefinement.

Open Scope string_scope.

Record hol4_recursive_identity := {
  hol4_identity_source_snapshot_digest : string;
  hol4_identity_pcuic_certificate_digest : string;
  hol4_identity_lambdabox_digest : string;
  hol4_identity_cakeml_program_digest : string;
  hol4_identity_machine_image_digest : string;
  hol4_identity_final_theorem_digest : string;
  hol4_identity_source_lambdabox : source_lambdabox_evidence;
  hol4_identity_machine_refinement : hol4_machine_refinement_evidence;
  hol4_identity_runtime_reproduced_same_digests : bool;
  hol4_identity_runtime_replayed_same_certificate_corpus : bool;
  hol4_identity_runtime_rechecked_final_theorem : bool
}.

Definition identity_digest_present (s : string) : bool :=
  negb (String.eqb s EmptyString).

Definition accept_hol4_recursive_identity (i : hol4_recursive_identity) : bool :=
  identity_digest_present i.(hol4_identity_source_snapshot_digest)
  && identity_digest_present i.(hol4_identity_pcuic_certificate_digest)
  && identity_digest_present i.(hol4_identity_lambdabox_digest)
  && identity_digest_present i.(hol4_identity_cakeml_program_digest)
  && identity_digest_present i.(hol4_identity_machine_image_digest)
  && identity_digest_present i.(hol4_identity_final_theorem_digest)
  && source_lambdabox_evidence_complete i.(hol4_identity_source_lambdabox)
  && hol4_machine_refinement_complete i.(hol4_identity_machine_refinement)
  && i.(hol4_identity_runtime_reproduced_same_digests)
  && i.(hol4_identity_runtime_replayed_same_certificate_corpus)
  && i.(hol4_identity_runtime_rechecked_final_theorem).

Definition unresolved_hol4_recursive_identity : hol4_recursive_identity :=
  {| hol4_identity_source_snapshot_digest := "";
     hol4_identity_pcuic_certificate_digest := "";
     hol4_identity_lambdabox_digest := "";
     hol4_identity_cakeml_program_digest := "";
     hol4_identity_machine_image_digest := "";
     hol4_identity_final_theorem_digest := "";
     hol4_identity_source_lambdabox := unresolved_source_lambdabox_evidence;
     hol4_identity_machine_refinement := unresolved_hol4_machine_refinement;
     hol4_identity_runtime_reproduced_same_digests := false;
     hol4_identity_runtime_replayed_same_certificate_corpus := false;
     hol4_identity_runtime_rechecked_final_theorem := false |}.

Theorem unresolved_recursive_identity_is_blocked :
  accept_hol4_recursive_identity unresolved_hol4_recursive_identity = false.
Proof. reflexivity. Qed.
