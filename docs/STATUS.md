# Current status

PRs 1 and 2 are merged. Work continues in PR 4 to retain its completed opam cache.
Aegis PR 17 descends from every prior MetaRocq supervision PR through PR 16.

The actual artifact from run 37106552663 is independently consistent at source
93387eac: extraction succeeded and compilation failed. Its raw PCUIC isApp AST
and Rust, original observation, dependency export and origin are preserved here.
A syn/quote transformation repairs the two diagnosed Rust printer failures;
the recovered candidate compiles and a two-case runtime regression passes.
Three normalizer regression checks pass. No hand-written isApp implementation exists.

Real Kani 0.67.0 did not verify this slice. An unbounded attempt hit the 120-second
budget while unwinding bumpalo cleanup. With explicit unwind 4, Kani reported four
failed checks out of 644, including allocator pointer validity and the result
assertion. Both diagnostics are preserved losslessly as compressed logs in
`.metarocq/evidence/`. This gate remains FAILED; runtime success does not override it.

The reproducible source inventory contains all 755 tracked upstream files: 596
Rocq files, 33 OCaml/plugin files, and 126 build/documentation/assets. One Rocq demo
has no upstream logical-path mapping. Generated module drivers use upstream build
mappings and MetaRocq's own declaration enumeration. This is file coverage only.

The new additive retention driver requests opaque proof bodies, retains original
PCUICAstUtils.mkApps_tApp and its dependency environment as Type-level AST data,
and includes a concrete body-presence assertion. Its real cloud execution is the
next qualification gate. Generic module snapshot infrastructure is additive;
whole-project closure and non-Gallina sources are not yet converted.

All original MetaRocq source files remain unchanged. Rust ownership semantics,
semantic proof transport, full PCUIC implementation, HOL4 source refinement,
macro certificates, independent self-hosting and machine-code proofs remain OPEN.
This is not production-ready. See spec/obligations.json and ADR 0004.
