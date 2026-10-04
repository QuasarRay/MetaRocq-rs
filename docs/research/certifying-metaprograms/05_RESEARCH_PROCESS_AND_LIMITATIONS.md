# Research Process and Limitations

## 1. Research Scope

The question investigated was causal, not merely descriptive:

> Is MetaRocq unusually capable at Certifying Metaprograms mainly because PCUIC is a superior calculus for this niche, or mainly because MetaRocq has built a rich reflective and verified metaprogramming ecosystem around PCUIC?

The research therefore compared both:

1. the intrinsic properties of the underlying calculi; and
2. the surrounding implementation, reflection, tactic, transformation, checker, and compilation ecosystems.

## 2. Priority of Evidence

The evidence was prioritized in this order:

1. Current/pinned MetaRocq source documentation for Rocq 9.1.
2. MetaRocq peer-reviewed papers.
3. Official HOL4/CakeML/Candle documentation and papers.
4. Official Lambdapi/Dedukti documentation and papers.
5. Official Lean and Agda documentation.
6. Twelf project documentation for logical-framework counterexamples.

The report intentionally avoids relying on forum opinions or popularity metrics because neither answers the causal question.

## 3. Version Boundary

MetaRocq-rs currently targets the MetaRocq/Rocq 9.1 line, so the report gives special weight to MetaRocq 9.1 and release `v1.5.1-9.1`.

Later/parallel documentation was only used when it did not alter the core architectural conclusion.

## 4. What "Empirical Evidence" Means Here

There is no standardized benchmark called "Certified Metaprogramming Capability".

Therefore the report uses observable artifacts as evidence:

- actual reflected syntax APIs;
- actual environment monads;
- actual theorem-kernel interfaces;
- actual verified checkers;
- actual transformation correctness proofs;
- actual machine-code correctness theorems;
- actual proof-transport tools;
- actual documented unverified gaps.

This is stronger than reasoning from the expressive power of calculi alone.

## 5. Important Limitation

The report does **not** claim to prove mathematically that option 2 is universally true under every possible definition of "more capable".

It concludes that option 2 is the better explanation of the current empirical evidence.

A different metric can change the ranking:

- Rocq-native semantic fidelity favors PCUIC.
- End-to-end verified theorem-prover implementation strongly favors HOL/CakeML/Candle.
- Cross-logic proof interoperability strongly favors Lambda-Pi modulo/Dedukti-style systems.
- General interactive metaprogramming ergonomics can strongly favor Lean.

Therefore the phrase "superior calculus" should only be used after the metric is explicitly named.

## 6. Confidence

Confidence in the main conclusion is high because the evidence includes both:

1. direct statements from MetaRocq's own papers describing the project as a composition of separate artifacts; and
2. concrete counterexamples showing strong certification in systems built on other calculi.

The part that should remain deliberately qualified is the statement that MetaRocq is "more capable than other languages" in an absolute sense. The evidence supports saying MetaRocq is **unusually integrated and unusually strong for Rocq-native certified metaprogramming**, not that it dominates every competitor on every certification dimension.
