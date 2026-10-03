From MetaRocq.Template Require Import All.
From MetaRocq.PCUIC Require Import PCUICAstUtils.
From Peregrine.Plugin Require Import Loader.
Require Import Retention.
Import MonadNotation.
Local Open Scope bs_scope.

(* mkApps_tApp is an ORIGINAL opaque Qed proof, not a replacement theorem.
   true requests opaque dependency bodies as well as transparent definitions. *)
MetaRocq Run (p <- tmQuoteRecTransp (@PCUICAstUtils.mkApps_tApp) true;;
              tmDefinition "retained_program" p).

Example opaque_root_body_is_present :
  has_retained_root_body retained_program = true.
Proof. vm_compute. reflexivity. Qed.
Print Assumptions opaque_root_body_is_present.

(* Return the entire quoted environment/root, not just its hash or a Boolean.
   The second component makes the retention observation executable in Rust. *)
Definition retained_export :=
  (retained_program, has_retained_root_body retained_program).

Peregrine Extract Typed "retained.ast" retained_export.
