# Empirical Capability Matrix

This matrix is intentionally about observed system capabilities rather than philosophical judgments about which foundational logic is "better".

| System | Native Reflection / AST Access | Environment Manipulation | Kernel-Checked Proof-Producing Tactics | Mechanized Metatheory of Native Core | Verified Transformations / Checkers | End-to-End Machine-Code Verification | Cross-Logic Interoperability | Main Strength for This Research Question |
|---|---|---|---|---|---|---|---|---|
| MetaRocq / Rocq / PCUIC | Very strong | Very strong through Template Monad | Strong | Very strong for PCUIC | Very strong in major components; not universal | Partial through surrounding verified extraction/compiler ecosystems, not the whole Rocq system by PCUIC alone | Moderate | Best integrated Rocq-native reflective + verified transformation stack. |
| HOL4 + CakeML + Candle | Strong tactic/meta infrastructure; different style from quoted dependent ASTs | Strong through ML/HOL tooling | Very strong LCF discipline | Strong HOL formal semantics and verified kernels | Very strong | Very strong; Candle and CakeML are direct evidence | OpenTheory and related tooling are strong | Strongest counterexample to the claim that a richer dependent calculus is required for deep certification. |
| Lambdapi / Dedukti / Lambda-Pi modulo | Strong term-level logical-framework manipulation | Moderate to strong depending on encoding | Strong proof-mode/tactic support | Framework-level theory plus per-encoding obligations | Strong proof checking; verification depth varies by encoding/translation | Not the primary strength | Very strong | Logic-independent framework and proof interchange; often more general than PCUIC. |
| Lean 4 | Very strong | Very strong | Very strong | Native core theory is precisely specified, but not the same self-formalized stack as MetaRocq | Strong proof-producing metaprogramming; implementation verification differs | Standard toolchain is not Candle-like end-to-end verified | Moderate | Shows that a closely related dependent calculus does not by itself imply MetaRocq's verification architecture. |
| Agda | Strong reflection and TC monad | Strong | Strong through generated checked terms | Different assurance architecture | Strong metaprogramming, less integrated verified compiler/checker story for this niche | Not the main strength | Moderate | Shows quote/unquote + monadic metaprogramming is not unique to PCUIC. |
| Twelf / LF | Strong object-language encodings | Logic-program/meta-language style | Proof/derivation generation through LF | Very strong for encoded metatheory workflows | Strong for totality/meta-theorem checking | Not the main strength | Strong as logical framework | Shows that metatheory-oriented capability can arise from a very different logical framework. |

## Interpretation Rules

1. Do not read "Very strong" as a benchmark score. It is a qualitative summary backed by the primary references in `90_PRIMARY_REFERENCES_AND_PROOFS.md`.
2. The matrix deliberately separates **reflection**, **proof production**, **verification of the metaprogram itself**, and **verification of the prover/compiler implementation**. These are different properties and should never be collapsed into one word such as "certified".
3. MetaRocq's distinctive strength is the unusually tight integration of these layers around the real Rocq calculus.
4. HOL/CakeML's distinctive strength is the depth of verified implementation and compilation.
5. Lambda-Pi modulo's distinctive strength is logic-independent rewriting and interoperability.
