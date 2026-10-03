# Current bootstrap checkpoint

The project has source locks, a real Aegis work cycle, an original-definition
Peregrine driver, transactional candidate publication and verification/checkpoint
integrity gates. It does not yet contain generated Rust or a verified MetaRocq checker.

The first target PR and its exact live checkpoint are preserved. The second target
checkpoint pins Aegis PR #13, retains blocked observations and fixes the cloud clang
prerequisite exposed by the first real dependency-installation attempt.

Local Rocq, Peregrine, Rust/Kani, HOL4 and Z3 are unavailable. Extraction remains
BLOCKED locally. Cloud extraction is a separate qualification attempt whose current
result is shown by GitHub Actions, not inferred from the existence of this workflow.
All formal implementation obligations in spec/obligations.json remain OPEN.

For the historical first-cycle observations see BOOTSTRAP_STATUS.md. For the current
controller binding see ADR 0002 and spec/toolchain.lock.json. Kani adapter qualification
in Aegis is not evidence that a MetaRocq-specific Kani harness exists or passed.
