From MetaRocq.Template Require Import All.
From MetaRocq.PCUIC Require Import PCUICAstUtils.
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

MetaRocq Run (p <- share_program retained_program;;
              tmDefinition "shared_retained_program" p).

Example sharing_preserves_entire_program :
  shared_retained_program = retained_program.
Proof. vm_compute. reflexivity. Qed.
Print Assumptions sharing_preserves_entire_program.

(* Return the entire quoted environment/root, not just its hash or a Boolean.
   The second component makes the retention observation executable in Rust. *)
Definition retained_export :=
  (shared_retained_program, has_retained_root_body shared_retained_program).
