# Generated HOL4 → PCUIC artifacts

This directory is populated by the branch-only proof-generation workflow.

- `qualification/` contains the OpenTheory/Dedukti/Rocq provenance plus the
  kernel-checked MetaRocq PCUIC quotation.
- `cakeml/` contains diagnostic untyped/CakeML outputs and a fail-closed
  replay status.

Only the PCUIC quotation is the canonical migrated proof representation.
The qualification theorem currently exercises the migration backbone; it is
not the full MetaRocq-rs Rust-native metatheory.
