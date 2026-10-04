From Stdlib Require Import String List Bool.

Import ListNotations.
Open Scope string_scope.

Record semantic_claim := {
  claim_id : string;
  claim_pcuic_anchor : string;
  claim_candle_anchor : string;
  claim_machine_code_relevant : bool
}.

Record dual_evidence := {
  dual_pcuic_proved : bool;
  dual_candle_proved : bool;
  dual_machine_transport_proved : bool;
  dual_no_untracked_axiom : bool
}.

Definition accept_dual_claim
  (c : semantic_claim) (e : dual_evidence) : bool :=
  e.(dual_pcuic_proved)
  && e.(dual_candle_proved)
  && e.(dual_no_untracked_axiom)
  && if c.(claim_machine_code_relevant)
     then e.(dual_machine_transport_proved)
     else true.

Definition selfhost_claims : list semantic_claim :=
  [ {| claim_id := "pcuic-metatheory";
       claim_pcuic_anchor := "MetaRocq.PCUIC";
       claim_candle_anchor := "OpenTheory/PCUIC metatheory article set";
       claim_machine_code_relevant := true |};
    {| claim_id := "reflection-runtime";
       claim_pcuic_anchor := "OriginalSelfHost.SelfHostRunner";
       claim_candle_anchor := "OpenTheory/self-reflection-runtime";
       claim_machine_code_relevant := true |};
    {| claim_id := "erasure-retention";
       claim_pcuic_anchor := "OriginalSelfHost.RetainedPayload";
       claim_candle_anchor := "OpenTheory/retained-payload";
       claim_machine_code_relevant := true |};
    {| claim_id := "self-ci-pipeline";
       claim_pcuic_anchor := "OriginalSelfHost.SelfCICD";
       claim_candle_anchor := "OpenTheory/self-ci-pipeline";
       claim_machine_code_relevant := true |}
  ].

Definition empty_dual_evidence : dual_evidence :=
  {| dual_pcuic_proved := false;
     dual_candle_proved := false;
     dual_machine_transport_proved := false;
     dual_no_untracked_axiom := true |}.

Fixpoint all_dual_claims_accepted
  (claims : list semantic_claim)
  (evidence : list dual_evidence) : bool :=
  match claims, evidence with
  | [], [] => true
  | c :: cs, e :: es =>
      accept_dual_claim c e && all_dual_claims_accepted cs es
  | _, _ => false
  end.
