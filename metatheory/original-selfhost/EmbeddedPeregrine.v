From Stdlib Require Import List.
From MetaRocq.Utils Require Import ResultMonad bytestring.
From Peregrine Require Import
  Pipeline ConfigUtils PAst NameSanitize.

Import MonadNotation.
Local Open Scope bs_scope.

(* The self image uses Peregrine's real Rocq implementation for parsing,
   validation, name sanitization and lambda-box transforms.  It deliberately
   stops before [run_backend]: the pinned CakeML backend contains both an
   admitted Program obligation and [trust_coq_kernel]. *)

Definition embedded_cakeml_config : ConfigUtils.config' :=
  ConfigUtils.empty_config'
    (ConfigUtils.CakeML' ConfigUtils.empty_cakeml_config').

Definition prepare_cakeml
  (attrs : list string) (source : string) : result' PAst :=
  p <- Pipeline.parse_ast source ;;
  c <- Pipeline.get_config (inr embedded_cakeml_config) attrs ;;
  Pipeline.check_wf p ;;
  Pipeline.validate_ast_type c p ;;
  p <- NameSanitize.sanitize_PAst (NameSanitize.get_sanitizer c) p ;;
  c <- NameSanitize.sanitize_config (NameSanitize.get_sanitizer c) c ;;
  Pipeline.apply_transforms c p (Pipeline.needs_typed c).

Inductive cakeml_backend_gate :=
| CakeMLBackendBlocked (reason : string)
| CakeMLBackendProofReconstructed.

Definition pinned_peregrine_backend_gate : cakeml_backend_gate :=
  CakeMLBackendBlocked
    "pinned Peregrine CakeML backend has an Admitted pipeline obligation and trust_coq_kernel".

Definition embedded_peregrine_backend_publishable : bool :=
  match pinned_peregrine_backend_gate with
  | CakeMLBackendBlocked _ => false
  | CakeMLBackendProofReconstructed => true
  end.
