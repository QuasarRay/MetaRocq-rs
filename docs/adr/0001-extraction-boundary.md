# ADR 0001: original MetaRocq contracts and supervised extraction

Status: accepted bootstrap design; no implementation-equivalence theorem is complete.
Stakeholders: the supervising engineer and untrusted implementing agents.
Concerns: source identity, proof meaning, reuse, durability and bounded credit cost.

Decision: use the specialized Aegis PR #12 as an immutable dependency. Its upstream
specification lock is copied exactly and rechecked, not translated into a replacement
contract. Reuse MetaRocq 1.5.1 for Rocq 9.1 because the inspected Peregrine opam file
requires that release family. The initial extraction selects PCUICAst.isApp and its
dependency closure. This is a pipeline probe, not an implementation of MetaRocq.

Rejected alternatives: hand-written AST/checker code; assuming compilation proves
semantic preservation; taking Kontroli's lambda-Pi calculus as PCUIC; silently using
HOL4 oracle tactics. The original .v files retain their syntax/semantics; HOL4 needs
a separately verified interpretation before its theorems can establish this contract.

Reuse: Aegis's bounded subprocess capture, transactions, Kani/Verus adapters, HOL4/MCP,
TacticToe and exact PR-head attestation. Kontroli's Aeneas/HOL4 interface manifest is
invoked from a pinned external GPL checkout. The target's RPL LICENSE.MD is unchanged.
Verus/Kani are already reused through Aegis; Aeneas/Charon's sliced extraction recipe
is an identified next bridge. Lambars, Candle-rs and VerusBelt are reuse candidates
for later specific obligations; they are not represented as imported/proved here.

Proof boundary: Peregrine explicitly marks the Rust backend and printer unverified.
The original safechecker-plugin extraction contains fake_abstract_guard_impl_properties;
do not promote this axiom to a proved guard checker. Track primitive models, universe
consistency, normalization, termination, proof erasure, allocator behavior, certificate
binding and compiler/ISA semantics in spec/obligations.json. Macro expansion carrying
a certificate is useful only if an independent checker checks the correct proposition
against the exact expansion. A Rust host language does not confer Rust-semantics knowledge.

Consequences: candidate generation precedes API-specific Kani harnesses. Successful
controller checks establish record consistency, not PCUIC metatheory or Rust correctness.
The Z3/HOL4 smoke theorem only qualifies the adapter. Missing tools remain BLOCKED;
full extraction, certified macros, self-hosting and machine-code proofs remain OPEN.
No implementation placeholder is substituted for missing generated Rust.

Validation: exact upstream source/byte checks and canonical directory instructions;
adversarial Aegis regressions; real extraction/tool probes; immutable GitHub checkpoints.
The controller can prevent invalid managed cycles, but it cannot prevent arbitrary
same-account writes or predict all mistakes before implementation.
