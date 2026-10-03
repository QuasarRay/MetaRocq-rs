# Current status

PRs 1 and 2 are merged. Work continues in PR 4 to retain its completed opam cache.
Aegis PR 17 descends from every prior MetaRocq supervision PR through PR 16.

The actual artifact from run 37106552663 is independently consistent at source
93387eac: extraction succeeded and compilation failed. Its raw PCUIC isApp AST
and Rust, original observation, dependency export and origin are preserved here.
A syn/quote transformation repairs the two diagnosed Rust printer failures;
the recovered candidate compiles and a two-case runtime regression passes.
Three normalizer regression checks pass. No hand-written isApp implementation exists.

The new additive retention driver requests opaque proof bodies, retains original
PCUICAstUtils.mkApps_tApp and its dependency environment as Type-level AST data,
and includes a concrete body-presence assertion. Its real cloud execution is the
next qualification gate. Generic module snapshot infrastructure is additive;
whole-project closure and non-Gallina sources are not yet converted.

All original MetaRocq source files remain unchanged. Rust ownership semantics,
semantic proof transport, full PCUIC implementation, HOL4 source refinement,
macro certificates, independent self-hosting and machine-code proofs remain OPEN.
This is not production-ready. See spec/obligations.json and ADR 0004.
