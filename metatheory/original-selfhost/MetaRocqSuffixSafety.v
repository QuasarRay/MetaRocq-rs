From Stdlib Require Import String List Bool.

Import ListNotations.
Open Scope string_scope.

(* Candle's x64 theorem accepts a source suffix only through the same safety
   discipline used for the compiler's existing suffix.  This record is retained
   as executable evidence; theorem-producing construction of it remains a
   separate obligation. *)
Record cakeml_suffix_certificate := {
  suffix_artifact_name : string;
  suffix_source_digest : string;
  suffix_bound_to_generated_metaself : bool;
  suffix_every_safe_dec_proved : bool;
  suffix_prog_syntax_ok_proved : bool;
  suffix_avoids_kernel_ffi : bool;
  suffix_avoids_kernel_ctors : bool;
  suffix_no_untracked_axioms : bool
}.

Definition accept_suffix_certificate
  (c : cakeml_suffix_certificate) : bool :=
  c.(suffix_bound_to_generated_metaself)
  && c.(suffix_every_safe_dec_proved)
  && c.(suffix_prog_syntax_ok_proved)
  && c.(suffix_avoids_kernel_ffi)
  && c.(suffix_avoids_kernel_ctors)
  && c.(suffix_no_untracked_axioms).

Definition unresolved_metaself_suffix : cakeml_suffix_certificate :=
  {| suffix_artifact_name := "generated/original-selfhost/shared-image.cml";
     suffix_source_digest := "";
     suffix_bound_to_generated_metaself := false;
     suffix_every_safe_dec_proved := false;
     suffix_prog_syntax_ok_proved := false;
     suffix_avoids_kernel_ffi := false;
     suffix_avoids_kernel_ctors := false;
     suffix_no_untracked_axioms := true |}.
