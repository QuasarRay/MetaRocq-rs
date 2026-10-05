From Stdlib Require Import String List Bool.
From MetaRocqRs.OriginalSelfHost Require Import PCUICCertificateIR.

Import ListNotations.
Open Scope string_scope.

Inductive checker_assumption_kind :=
| CheckerNormalization
| CheckerGuardImplementation
| CheckerEnvironmentWellFormedness
| CheckerUniverseConsistency.

Record checker_assumption := {
  checker_assumption_kind_of : checker_assumption_kind;
  checker_assumption_name : string
}.

Definition safe_checker_assumptions : list checker_assumption :=
  [{| checker_assumption_kind_of := CheckerNormalization;
      checker_assumption_name := "NormalizationIn" |};
   {| checker_assumption_kind_of := CheckerGuardImplementation;
      checker_assumption_name := "abstract_guard_impl" |};
   {| checker_assumption_kind_of := CheckerEnvironmentWellFormedness;
      checker_assumption_name := "abstract_env_ext_rel / wf" |};
   {| checker_assumption_kind_of := CheckerUniverseConsistency;
      checker_assumption_name := "universe graph consistency" |}].

Record safe_checker_contract := {
  checker_repository : string;
  checker_revision : string;
  checker_path : string;
  checker_blob_sha1 : string;
  checker_judgement_symbol : string;
  checker_result_claim : string;
  checker_explicit_assumptions : list checker_assumption
}.

Definition pinned_safe_checker_contract : safe_checker_contract :=
  {| checker_repository := "https://github.com/MetaRocq/metarocq.git";
     checker_revision := "7197056adbb9c15288b4c8d43407bf25786f723e";
     checker_path := "safechecker/theories/PCUICSafeChecker.v";
     checker_blob_sha1 := "8691e1f5d25b8001c7d497f0e67a71c888c6b0db";
     checker_judgement_symbol := "PCUICSafeChecker.check_wf_judgement";
     checker_result_claim :=
       "successful result carries PCUIC typing of the proof term at the requested statement for every related global environment";
     checker_explicit_assumptions := safe_checker_assumptions |}.

Definition safe_checker_contract_shape_ok : bool :=
  Nat.eqb
    (List.length pinned_safe_checker_contract.(checker_explicit_assumptions))
    4.

Theorem safe_checker_contract_exposes_assumptions :
  safe_checker_contract_shape_ok = true.
Proof. reflexivity. Qed.
