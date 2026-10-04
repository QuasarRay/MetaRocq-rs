# Claim-Evidence Matrix

This file separates each important claim from the Human Readable Explanation and records the evidence that supports, weakens, or falsifies it.

| ID | Claim | Evidence Status | Evidence | Result |
|---|---|---|---|---|
| C1 | PCUIC is the primary reason MetaRocq can perform certified metaprogramming. | Weak / contradicted as a primary-cause claim | MetaRocq separates Template-Rocq, PCUIC, SafeChecker, Erasure, Translations, and Quotation into distinct packages. The 2018 paper explicitly requires environment access through a monad in addition to reification and semantics. | PCUIC is important but not sufficient. |
| C2 | PCUIC is an important reason MetaRocq can prove semantic correctness of Rocq-specific metaprograms. | Strongly supported | PCUIC is equivalent to Rocq's cleaned-up kernel language and is the specification used by the verified checker and verified erasure. | True. |
| C3 | MetaRocq's distinctive advantage comes from the integrated verified metaprogramming stack. | Strongly supported | Template Monad + quotation/reification + PCUIC metatheory + verified Template<->PCUIC translation + SafeChecker + verified erasure + concrete translations/tactics. | Strongest causal explanation. |
| C4 | HOL cannot reach similarly strong certification because HOL is less expressive than PCUIC. | Falsified in the general form | HOL4 uses LCF theorem abstraction and validations; CakeML builds verified proof checkers and proof-producing synthesis; Candle has an end-to-end correctness theorem down to machine code. | False as a general certification claim. |
| C5 | Lambda-Pi modulo is inherently weaker for proof-certificate/meta work. | Falsified in the general form | Dedukti/Lambdapi encode multiple logics, transport HOL proofs, support tactics and user-defined rewriting. | False as a general claim; tradeoffs differ. |
| C6 | PCUIC is better aligned than HOL or Lambda-Pi modulo for certifying transformations specifically over Rocq's real dependent kernel language. | Supported with qualification | PCUIC intentionally models Rocq's real syntax, universes, inductives, cumulativity and typing, and is connected by verified translations to Template-Rocq. | Likely true for Rocq-native fidelity/ergonomics, not universal superiority. |
| C7 | A similar dependent calculus automatically gives the same certified-metaprogramming advantages. | Contradicted | Lean has a related dependent foundational calculus and excellent metaprogramming, but not MetaRocq's exact mechanized metatheory/checker/erasure stack. | Calculus is not sufficient. |
| C8 | Rich metaprogramming requires PCUIC. | Falsified | Lean, Agda, Lambdapi and HOL-family tactics all provide strong metaprogramming through different mechanisms. | False. |
| C9 | All of current MetaRocq's transformation pipeline is formally verified. | Falsified | MetaRocq v1.5.1-9.1 explicitly includes an unsafe/unverified remapping phase; typed quotation remains work in progress; verified-extraction exposes unsafe/unverified phases. | Must be qualified. |
| C10 | Option 2 is more correct than option 1. | Strongly supported | C1-C9 collectively show that ecosystem/integration explains the eridence better than calculus superiority. | Yes, after refining option 2. |

## Corrected Version of Option 2

The strongest evidence supports the following statement:

> MetaRocq is unusually capable for certified metaprogramming because it integrates Rocq-native quotation/reification and environment manipulation with PCUIC as a semantically faithful formal specification, a mechanized PCUIC metatheory, verified bridges, verified checking and erasure algorithms, and proof-producing or proved-correct transformations. PCUIC is a major enabling substrate for this stack, but there is no empirical basis for claiming that PCUIC itself is categorically superior to HOL, Lambda-Pi modulo, or other calculi for certification in general.
