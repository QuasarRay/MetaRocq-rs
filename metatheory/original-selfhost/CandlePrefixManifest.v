From Stdlib Require Import String List Bool.

Import ListNotations.
Open Scope string_scope.

Record candle_theorem_binding := {
  candle_file : string;
  candle_blob_sha : string;
  candle_theorem : string;
  candle_role : string
}.

Definition candle_prefix_bindings : list candle_theorem_binding :=
  [ {| candle_file :=
         "candle/prover/candle_prover_semanticsScript.sml";
       candle_blob_sha := "5b3a22644c604619aeb5039684ac8c5789c9622c";
       candle_theorem := "semantics_thm";
       candle_role :=
         "soundness of candle_code ++ safe appended program" |};
    {| candle_file :=
         "compiler/bootstrap/compilation/x64/64/proofs/x64BootstrapProofScript.sml";
       candle_blob_sha := "71255c97591eef9717739e310b20c65dc509a671";
       candle_theorem := "compiler64_prog_eq_candle_code_append";
       candle_role :=
         "decomposes compiler64_prog into candle_code ++ safe_dec suffix" |};
    {| candle_file :=
         "compiler/bootstrap/compilation/x64/64/proofs/x64BootstrapProofScript.sml";
       candle_blob_sha := "71255c97591eef9717739e310b20c65dc509a671";
       candle_theorem := "candle_top_level_soundness";
       candle_role :=
         "transports Candle theorem-event soundness to x64 machine semantics" |};
    {| candle_file :=
         "compiler/bootstrap/compilation/x64/64/proofs/x64BootstrapProofScript.sml";
       candle_blob_sha := "71255c97591eef9717739e310b20c65dc509a671";
       candle_theorem := "cake_compiled_thm";
       candle_role :=
         "verified CakeML compiler machine-code compilation theorem" |}
  ].

Definition candle_prefix_binding_count_ok : bool :=
  Nat.eqb (List.length candle_prefix_bindings) 4.
