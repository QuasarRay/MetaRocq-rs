# Original compiler automation

This directory inherits the original-source experiment rules. Z3_TAC and
TacticToe may search for proofs; only closed HOL4 theorem objects with the
exact declared conclusions and permitted disk-loading tags are exported.
Compiler-output bounds are qualification facts, not source-to-machine
refinement or complete MetaRocq proof replay. Preserve failed attempts and
learned search data across incremental PRs.
