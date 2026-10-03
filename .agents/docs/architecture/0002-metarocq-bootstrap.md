# ADR 0002: extract candidates while retaining the original MetaRocq contract

Status: accepted for bootstrap; source and binary equivalence remain OPEN.
Stakeholders: the solo supervising engineer and untrusted implementing agents.
Concerns: exact specification identity, reproducibility, proof scope and credit cost.

Decision: specialize Aegis from e01523fbf936ebfa2b9f81aa1ee64e421c88a7cb,
the head of the HOL4/MCP/TacticToe PR stack (#9, #10). Reuse its atomic filesystem,
locks, bounded process capture, Kani/Verus evidence and exact PR-head attestation.
The alternative codex/aegis-candle-audit branch (471f6f60f57a54d0fbcafffe37883fa1c7bcbc72,
PR #6) has a different runtime and packet format. Do not merge those incompatible
state machines blindly. Its inventory/anti-vacuity and checkpoint hardening remain
reuse candidates, not claims about this branch. No prior PR is merged by this work.

Inspected Kontroli 966cfc3069aab378d10ae567da4ff41c2da95c65, including
scripts/aeneas_hol4_manifest.py, sliced extraction and the workspace HOL4/MCP workflow.
It pins the same Aegis e01523f baseline. Reuse its deterministic HOL4 interface
manifest as an external pinned tool and its exact-head workspace execution pattern.
Do not substitute its lambda-Pi metatheory for MetaRocq PCUIC. Kontroli's GPL-3.0
license is retained on that external checkout; the target's existing RPL is unchanged.

Use original .v files at MetaRocq v1.5.1-9.1, matching Peregrine's inspected dependency
constraints. Preserve files and license notices. A selected-definition index is not
the complete dependency closure. Generate a small PCUIC isApp slice first using the
documented typed frontend; run each larger extraction only after preserving its PR.

Rejected alternatives: manually translating the checker, treating generated Rust as
already verified, silently replacing Gallina with handwritten HOL specifications,
and interpreting Z3 UNSAT or Holmake exit status as full equivalence evidence.
Peregrine's Rust backend and printer are explicitly unverified in doc/backends.md.

HOL4 cannot directly read these .v contracts. A semantics-preserving interpretation
and a Rust-semantics refinement relation are obligations, not string-conversion tasks.
Use HolSmtLib.Z3_TAC for supported reconstructed SMT proofs; never Z3_ORACLE_TAC.
Retain MCP/TacticToe as proof search aids outside the acceptance boundary. Existing
HOL4 adapter qualification is not a proof of MetaRocq, nor an oracle-free theorem audit.

The safechecker-plugin extraction script declares fake_abstract_guard_impl_properties.
Do not reuse that axiom as established guard correctness. Track universe consistency,
normalization assumptions, primitive behavior, termination/guard checking, resource
failure, AST representation, macro certificate binding and compiler semantics.

Consequences: initial progress is reviewable infrastructure and candidate generation.
Rust-native certified macros, a self-hosted checker and verified machine code require
additional work. Kani is bounded regression evidence. Process logs and content hashes
are change-detection aids; independent trusted replay remains necessary. An agent using
the same OS account can bypass the controller, so the managed preflight is not a sandbox.

Validation: retain adversarial controller tests, add extraction failure cases, pin
sources, record missing tools honestly and attest published GitHub heads. No optional
performance, style or speculative refactoring campaign is required.
