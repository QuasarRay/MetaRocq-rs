# Primary References and Proofs

This file intentionally contains the References and the empirical proof/evidence for the research claims. It is separated from the Human Readable Explanations so that a Human Engineer can independently inspect the evidence without having to trust the interpretation.

## 1. MetaRocq Primary Sources

### 1.1 MetaRocq 9.1 README

Reference:

- https://github.com/MetaRocq/metarocq/blob/9.1/README.md

Empirical facts established directly by the source:

1. MetaRocq describes itself as a project for formalizing Rocq in Rocq and for developing certified plugins, including translations, compilers, and tactics.
2. Template-Rocq provides reification of terms and environment declarations, denotation, and a `TemplateMonad` for querying and modifying the Rocq logical environment.
3. PCUIC is described separately as a cleaned-up version of Rocq's term language and type system, shown equivalent to Rocq's representation.
4. PCUIC has mechanized metatheory including weakening, substitution, confluence, context conversion/cumulativity, subject reduction with stated exclusions, principality, bidirectional typing, elimination restrictions, canonicity, consistency under strong-normalization assumptions, and weak call-by-value standardization.
5. The Safe Checker is a verified reduction machine, conversion checker, type checker, retyping procedure, and environment checker for PCUIC.
6. Erasure contains verified optimizations and a correctness development.
7. MetaRocq includes concrete metaprogramming examples: constructor-generating plugins, a `constructor` tactic, a verified tautology checker, parametricity translation, and self-erasure tests.
8. The Quotation development explicitly says that quotation of raw `Ast.term` is implemented while typed quotation involving a typing derivation remains work in progress.

Why this matters:

- The source itself separates the **metaprogramming interface** from **PCUIC**. This is direct evidence against treating PCUIC alone as the complete explanation for MetaRocq's metaprogramming capability.

### 1.2 MetaRocq Installation/Package Structure

Reference:

- https://github.com/MetaRocq/metarocq/blob/9.1/INSTALL.md

Empirical facts:

1. `rocq-metarocq-template` contains the Template Monad and quoting plugin.
2. `rocq-metarocq-pcuic` contains the PCUIC metatheory.
3. `rocq-metarocq-template-pcuic` contains verified Template-Rocq <-> PCUIC translations.
4. `rocq-metarocq-safechecker` contains the verified PCUIC checker.
5. `rocq-metarocq-erasure` contains verified erasure.
6. `rocq-metarocq-translations` contains example type-theory-to-type-theory translations.
7. `rocq-metarocq-quotation` contains quotation of terms and typing derivations, with the stronger quotation results still under development.

Why this matters:

- The package architecture is empirical evidence that MetaRocq's capability is produced by an integrated stack. PCUIC is a central layer, but it is not the same component as quotation, environment manipulation, executable checking, erasure, or example metaprograms.

### 1.3 Safe Checker

Reference:

- https://github.com/MetaRocq/metarocq/blob/9.1/safechecker/theories/README.md

Empirical facts:

- The development contains a fuel-free correct and complete type checker for PCUIC, including weak-head reduction, conversion checking, type inference/checking, retyping, and global-environment checking.

This is strong evidence for PCUIC's role as the **formal specification target** for executable certified algorithms.

### 1.4 Erasure

References:

- https://github.com/MetaRocq/metarocq/blob/9.1/erasure/theories/README.md
- https://metarocq.github.io/html/MetaRocq.Erasure.ErasureCorrectness.html

Empirical facts:

- The erasure development has a specified source and target semantics, an erasure relation, an erasure function, and correctness proofs.
- It includes verified transformations/optimizations after erasure.

This is evidence for option 2's general direction: the practical certification strength comes from verified transformations built on top of the calculus and its metatheory.

### 1.5 Template-Rocq / Certified Metaprogramming Paper

Reference:

- Abhishek Anand, Simon Boulier, Cyril Cohen, Matthieu Sozeau, Nicolas Tabareau, *Towards Certified Meta-Programming with Typed Template-Coq*, ITP 2018.
- https://link.springer.com/chapter/10.1007/978-3-319-94821-8_2

Empirical facts from the paper:

1. The paper identifies complete reification of CIC syntax as one requirement.
2. It separately identifies access to the logical environment through a monad as necessary for a practical metaprogramming framework.
3. It states that this setup allows general-purpose plugins whose correctness can be proved in the system itself.
4. It presents translations such as parametricity as concrete examples.
5. The paper's own causal description is therefore **reification + semantics/type checking + environment monad + in-system proof**, not "the calculus alone is superior".

### 1.6 Touring the MetaCoq Project

Reference:

- Matthieu Sozeau, *Touring the MetaCoq Project*, 2021.
- https://arxiv.org/abs/2107.07670

Empirical facts:

The paper lists multiple distinct artifacts as the ingredients of the project:

- PCUIC as the syntax/type-theory specification.
- a monad for manipulation of raw syntax and interaction with Rocq.
- a verification of PCUIC's metatheory.
- a correct and complete type checker.
- a sound type/proof erasure procedure.

This is unusually strong evidence because the project authors themselves present MetaRocq as a composition of artifacts rather than attributing its strength to PCUIC alone.

### 1.7 Current Release Caveat for the MetaRocq-rs Pinned Line

Reference:

- https://github.com/MetaRocq/metarocq/releases/tag/v1.5.1-9.1

Empirical fact:

- MetaRocq 1.5.1 for Rocq 9.1 explicitly introduced an **unsafe/unverified** erasure remapping phase for mapping inductive types and pattern matching to arbitrary constants.

Why this matters:

- It is inaccurate to describe the entire contemporary MetaRocq transformation ecosystem as formally verified without qualification.
- The correct statement is that MetaRocq contains a substantial verified core and several verified transformations, while some optional/current phases are explicitly unverified.

### 1.8 Verified Extraction Follow-On

Reference:

- https://github.com/MetaRocq/rocq-verified-extraction

Empirical facts:

- The project distinguishes verified and unsafe/unverified optimization phases.
- Reordering of constructors can be verified, while some inlining/unboxing/beta-reduction/cofix-to-lazy paths are marked unsafe or unverified depending on the phase.

This reinforces the need to distinguish **verified transformation infrastructure** from **every available optimization being verified**.

---

## 2. HOL / HOL4 / CakeML / Candle Counterevidence

### 2.1 LCF Tactics and Validations in HOL4

References:

- https://hol-theorem-prover.org/docs/trindemossen-2/Description/tactics
- https://hol-theorem-prover.org/docs/trindemossen-2/Reference/Thm.thm

Empirical facts:

1. HOL4 represents theorems with an abstract `thm` type whose values can only be constructed through kernel inference rules.
2. A tactic decomposes a goal and returns a validation/justification that reconstructs a theorem from theorems solving its subgoals.
3. Therefore complex tactic code can be outside the kernel while final theorem construction remains constrained by the kernel interface.

Why this matters:

- Strong proof-producing metaprogramming does not require PCUIC or a dependent CIC-style calculus.
- HOL's simpler foundational logic does not prevent an architecture in which untrusted metaprograms can only produce kernel-valid theorem values.

### 2.2 CakeML Verified Proof Checking and Proof-Producing Synthesis

Reference:

- https://cakeml.org/checkers.html

Empirical facts:

- CakeML explicitly builds verified proof checkers and describes proof-producing synthesis plus a verified compiler to machine code.
- The generated machine code is related by theorem to the logical specification.

This is direct counterevidence against any general claim that PCUIC is intrinsically superior to HOL for certification.

### 2.3 Candle

References:

- https://cakeml.org/candle/
- https://cakeml.org/jarhol.pdf
- https://cakeml.org/jlamp20.pdf

Empirical facts:

1. Candle is a fully verified HOL Light-style interactive theorem prover implemented using CakeML.
2. Candle has an end-to-end correctness theorem down to its machine-code execution boundary.
3. Its kernel and proof-checker work were formalized in HOL4.

Why this matters:

- In the dimension of **verified prover implementation down to machine code**, the HOL/CakeML ecosystem already demonstrates capabilities that are at least as strong as, and in this particular dimension stronger than, what PCUIC alone provides.
- Therefore PCUIC cannot be treated as a universally superior certification calculus.

---

## 3. Lambda-Pi Calculus Modulo / Dedukti / Lambdapi Counterevidence

### 3.1 Lambdapi as a Logical Framework

Reference:

- https://lambdapi.readthedocs.io/en/latest/about.html

Empirical facts:

1. Lambdapi is based on the Lambda-Pi calculus modulo rewriting.
2. It supports dependent types and user-defined rewrite rules at the level of conversion.
3. It is a logical framework rather than a single fixed object logic.
4. It has encodings of logics including HOL, Coq/Rocq-style systems, and Agda-like systems.
5. It can be used for interoperability and proof transport.

Why this matters:

- Lambda-Pi modulo has a different strength profile from PCUIC. It is especially strong as a logic-independent interoperability framework.
- Calling PCUIC categorically "superior" ignores a dimension where Lambda-Pi modulo is deliberately more general.

### 3.2 Lambdapi Tactics and Tactic Evaluation

References:

- https://lambdapi.readthedocs.io/en/latest/proof.html
- https://lambdapi.readthedocs.io/en/latest/tacticals.html
- https://lambdapi.readthedocs.io/en/latest/tactics.html

Empirical facts:

- Lambdapi has proof tactics, tactic combinators, proof terms, and an `eval` mechanism that normalizes a term and interprets it as a tactic expression.
- This allows tactics themselves to be defined using rewriting.

Why this matters:

- Metaprogramming capability is not unique to PCUIC-based systems.

### 3.3 Rewrite-System Qualification Boundary

Reference:

- https://lambdapi.readthedocs.io/en/stable/commands.html

Empirical fact:

- User-defined rewrite rules are expected to satisfy termination and confluence conditions, with checking delegated to the user/external tools in relevant workflows; some unification-rule features are explicitly experimental.

Why this matters:

- The Lambda-Pi-modulo ecosystem has a different assurance boundary. This can make MetaRocq's integrated mechanized metatheory more attractive for Rocq-specific certified transformations, but it is an ecosystem/integration difference rather than evidence of universal calculus superiority.

### 3.4 Dedukti Interoperability

References:

- https://arxiv.org/abs/2311.07185
- https://arxiv.org/abs/1507.08720

Empirical facts:

- Dedukti can express and check proofs from multiple logical systems.
- Automated translations of HOL-family proofs to Dedukti have been implemented and used on the OpenTheory standard library.

This is evidence that Lambda-Pi modulo can act as a powerful proof-certificate interchange layer even when it is not the source system's native calculus.

---

## 4. Lean, Agda, and Twelf Counterexamples to a Calculus-Only Explanation

### 4.1 Lean 4

References:

- https://lean-lang.org/doc/reference/latest/Tactic-Proofs/
- https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/
- https://lean-lang.org/faq/

Empirical facts:

1. Lean tactics construct proof terms which are then checked by the kernel.
2. Lean has a highly extensible metaprogramming framework implemented largely in Lean itself.
3. Lean's foundational theory is also in the dependent Calculus-of-Constructions family, with differences from Rocq.
4. Lean does not obtain MetaRocq's exact verified-meta-theory stack merely from having a similar foundational calculus.

Why this matters:

- Similar calculus family, different meta-verification architecture: therefore calculus identity is not sufficient to explain the capability difference.

### 4.2 Agda Reflection

Reference:

- https://agda.readthedocs.io/en/latest/language/reflection.html

Empirical facts:

- Agda supports quotation/reflection, a `TC` monad, macros, and generation of top-level definitions.

Why this matters:

- Rich reflective metaprogramming can be provided by a different dependent type theory implementation without PCUIC.

### 4.3 Twelf / LF

References:

- https://twelf.org/wiki/about-the-twelf-project/
- https://twelf.org/wiki/proving-metatheorems-with-twelf/

Empirical facts:

- Twelf is explicitly designed as a meta-language for specifying deductive systems, proving properties about them, and executing logic-program-like specifications.

Why this matters:

- There are other calculi/frameworks whose primary design goal is metatheory. PCUIC is not uniquely capable of hosting metatheoretical reasoning.

---

## 5. Negative Evidence: What Was Not Found

1. I did not find a primary MetaRocq source, paper, or empirical benchmark that establishes the theorem-like claim:

   > PCUIC is intrinsically superior to HOL, Lambda-Pi modulo, or other calculi for certifying metaprograms.

2. The MetaRocq papers instead repeatedly describe a **stack of mutually supporting components**.
3. The existence of strong counterexamples in HOL/CakeML, Lean, Agda, Lambdapi, Dedukti, and Twelf makes a calculus-only explanation empirically implausible.

This is not a proof that PCUIC has no intrinsic advantages. It is evidence that the stronger causal statement in option 1 is unsupported and contradicted by existing systems that obtain strong certification through different foundations.
