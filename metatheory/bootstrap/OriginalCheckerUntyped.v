From Peregrine.Plugin Require Import Loader.
From MetaRocqRs.Bootstrap Require Import OriginalChecker.

(* This intentionally extracts the project-authored original checker wrapper as
   an open function.  It is a diagnostic input to the CakeML backend, not yet
   a closed trusted checker executable: normalization and guard implementation
   remain explicit parameters in OriginalChecker.v. *)
Peregrine Extract "generated/hol4-pcuic/cakeml/original-checker-open.ast"
  MetaRocqRs.Bootstrap.OriginalChecker.checker.
