# Bootstrap observation — 2026-10-03

The target initially contained only AGENTS.MD and LICENSE.MD. This checkpoint adds
supervision and an executable extraction recipe; it does not contain a Rust checker.

| Check | Observed result |
| --- | --- |
| Aegis controller regressions | 44 passed, 2 platform-specific skips |
| Aegis PR #12 controller and verifier CI | Success at 2793d301011d10945479d5b334ebd88a6dbcc4a6 |
| Original MetaRocq/Peregrine commits and selected specification bytes | Match |
| Per-directory canonical instruction copies | Match |
| Actual Aegis freeze | BOUND |
| Actual Aegis extraction command | BLOCKED: rocq unavailable |
| Rust/Kani, HOL4 and Z3 locally | Unavailable; no proof run claimed |
| Generated Rust source | None |
| Full MetaRocq, certified macros, binary equivalence | OPEN |

The content-addressed extraction observation is committed under .metarocq/evidence/.
It records the source inventory, exact plan/framework digests and missing-tool reason.
This is an agent-authored observation to independently reproduce, not authenticated
proof evidence. The GitHub extraction workflow will attempt dependency installation,
real generation and compilation. Its result is separate from these local observations.

Future work must inspect the actual generated API before adding a meaningful Kani
harness. The HOL4 smoke source is an unexecuted adapter check, not a PCUIC theorem.
