(* Runtime representation of a portable HOL4 attestation.
   HOL4, not CakeML, is the final proof authority.  The final HOL4 theorem must
   prove that the exact compiled program contains this exact payload and that
   the payload corresponds to the theorem/proof object it checked. *)

datatype hol4_attestation =
  Hol4Attestation of
    string * (* pinned source identity *)
    string * (* retained LambdaBox identity *)
    string * (* exact CakeML program identity *)
    string * (* theorem statement identity *)
    string   (* portable proof/certificate payload identity *)

fun nonempty s = String.size s > 0

fun attestation_complete
      (Hol4Attestation (source, lambdabox, cakeml, theorem, proof)) =
  nonempty source andalso
  nonempty lambdabox andalso
  nonempty cakeml andalso
  nonempty theorem andalso
  nonempty proof

fun expose_attestation a = a
