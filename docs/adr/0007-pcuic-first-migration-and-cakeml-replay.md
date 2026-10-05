# ADR 0007: PCUIC-first proof migration and CakeML replay

Status: **experimental; primary representation decision for this branch**.

## Decision

The canonical target of HOL4 proof migration is **PCUIC**, represented as
`MetaRocq.PCUIC.PCUICProgram.pcuic_program` (`global_env_ext_map * term`).

The required migration order is:

```text
HOL4 theorem
  -> OpenTheory
  -> Holide
  -> independently checked Dedukti/Lambdapi
  -> Rocq kernel
  -> MetaRocq tmQuoteRecTransp
  -> PCUICProgram.pcuic_program
```

OpenTheory, Dedukti and generated Rocq source are provenance and replay
representations. They are not competing authoritative metatheories.

The Rust-native MetaRocq-rs metatheory should likewise be stated directly in
PCUIC-compatible syntax and semantics. HOL4 is not a second implementation
goal; previous HOL4 work may be mechanically harvested into PCUIC, and HOL4
may later perform independent post-implementation replay.

## Current qualification seed

The checked-in HOL4 theorem
`MetaRocqMigrationSmoke.integer_interval` reuses the already-qualified Aegis
HOL4/Z3 reconstruction pattern. It exists solely to execute the full migration
backbone. It is **not** the final MetaRocq-rs metatheory.

## CakeML ordering

CakeML replay happens only after a PCUIC artifact has passed the intermediate
and Rocq-kernel gates.

The project currently has no closed trusted Original-MetaRocq CakeML checker.
`OriginalChecker.v` intentionally leaves normalization and guard
implementation explicit, while the upstream plugin's convenient extracted
checker uses an unproved fake guard property. Therefore:

1. `OriginalCheckerUntyped.v` attempts untyped Peregrine extraction only as a
   diagnostic/backend-qualification artifact.
2. The diagnostic stage lowers the open function with pinned Peregrine and then attempts to compile it with the official CakeML v3213 x64-64 release, whose asset SHA-256 is pinned. A resulting executable is still not called a trusted checker executable.
3. Proof execution is permitted only when
   `metatheory/artifacts/original-checker.bin` and an independently specified
   checker I/O contract exist.
4. Until then the CakeML replay gate records **BLOCKED**, rather than silently
   substituting the Rocq kernel or the fake-guard plugin.

This keeps the user-requested order—PCUIC formalization first, implementation
next, independent verification later—while retaining CakeML as the eventual
independent executable root.
