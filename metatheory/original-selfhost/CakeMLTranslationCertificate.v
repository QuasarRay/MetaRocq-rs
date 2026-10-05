From Stdlib Require Import String List Bool.

Import ListNotations.
Open Scope string_scope.

Record cakeml_translation_certificate := {
  translation_lambdabox_digest : string;
  translation_prepared_past_digest : string;
  translation_east_digest : string;
  translation_cakeml_ast_digest : string;
  translation_recomputed_from_candidate : bool;
  translation_supported_fragment_proved : bool;
  translation_east_semantics_preserved : bool;
  translation_candle_safe_dec_proved : bool;
  translation_no_forbidden_backend_assumption : bool;
  translation_certificate_checked_by_pcuic : bool;
  translation_certificate_checked_by_candle : bool
}.

Definition digest_present (s : string) : bool :=
  negb (String.eqb s EmptyString).

Definition accept_cakeml_translation
  (c : cakeml_translation_certificate) : bool :=
  digest_present c.(translation_lambdabox_digest)
  && digest_present c.(translation_prepared_past_digest)
  && digest_present c.(translation_east_digest)
  && digest_present c.(translation_cakeml_ast_digest)
  && c.(translation_recomputed_from_candidate)
  && c.(translation_supported_fragment_proved)
  && c.(translation_east_semantics_preserved)
  && c.(translation_candle_safe_dec_proved)
  && c.(translation_no_forbidden_backend_assumption)
  && c.(translation_certificate_checked_by_pcuic)
  && c.(translation_certificate_checked_by_candle).

Definition unresolved_cakeml_translation : cakeml_translation_certificate :=
  {| translation_lambdabox_digest := "";
     translation_prepared_past_digest := "";
     translation_east_digest := "";
     translation_cakeml_ast_digest := "";
     translation_recomputed_from_candidate := false;
     translation_supported_fragment_proved := false;
     translation_east_semantics_preserved := false;
     translation_candle_safe_dec_proved := false;
     translation_no_forbidden_backend_assumption := true;
     translation_certificate_checked_by_pcuic := false;
     translation_certificate_checked_by_candle := false |}.
