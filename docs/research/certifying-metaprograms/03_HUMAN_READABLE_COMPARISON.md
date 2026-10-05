# Human Readable Comparison

## 1. MetaRocq / PCUIC

### Where It Is Strongest

MetaRocq is strongest when the object being manipulated is actual Rocq syntax and the desired result is a theorem about Rocq typing/evaluation/transformation behavior.

The combination of Template-Rocq and PCUIC provides both sides:

- practical access to terms and declarations;
- a cleaned-up semantic model suitable for proof.

Then the project adds a verified checker, retyping, erasure, verified translations between representations, and examples of certified plugins.

### What PCUIC Contributes Specifically

PCUIC contributes:

- a realistic dependent calculus;
- universes and cumulativity;
- inductives/coinductives and pattern matching machinery;
- fix/cofix-related semantics;
- a formal typing/reduction relation;
- the metatheoretical lemmas needed to justify algorithms.

This is a very good fit for Rocq-native metaprogram correctness.

### What PCUIC Does Not Contribute By Itself

PCUIC alone does not automatically provide:

- a live Rocq environment API;
- quotation/unquotation execution;
- a tactic language;
- plugin execution;
- extraction to executable languages;
- a verified machine-code compiler;
- a library of transformation correctness theorems.

Those come from additional projects/components.

---

## 2. HOL4 / CakeML / Candle

### Where It Is Strongest

This ecosystem is exceptionally strong when the goal is to minimize trust in executable proof tooling.

The LCF architecture means tactic code can be complex while the theorem values remain restricted by the kernel inference interface.

CakeML then adds verified compilation and proof-producing program synthesis.

Candle demonstrates a complete verified theorem prover with a machine-code-level correctness theorem.

### What This Says About PCUIC

It demonstrates that a comparatively simple logic can support extremely strong certification if the meta-level architecture and verified implementation ecosystem are sufficiently strong.

Therefore foundational expressivity and certification depth are not the same axis.

### Where MetaRocq Is More Natural

If the target of the metaprogram is the full syntax and semantics of Rocq's dependent type theory, PCUIC avoids a large encoding gap.

In HOL, the corresponding dependent syntax and semantics must be represented explicitly as an object theory.

That can be done, but it is less native.

---

## 3. Lambda-Pi Calculus Modulo / Lambdapi / Dedukti

### Where It Is Strongest

The Lambda-Pi calculus modulo rewriting is a logical framework with programmable conversion through rewrite rules.

This makes it especially suitable for:

- encoding many logics;
- proof interoperability;
- transport between proof systems;
- reducing proof bureaucracy by putting equations into conversion.

Lmbdapi additionally has proof tactics and term-defined tactic evaluation.

### Where MetaRocq Is Stronger for the Specific Niche

MetaRocq has a more integrated, Rocq-specific story for:

- reflecting the actual host environment;
- connecting reflection to a formally equivalent kernel calculus;
- executing a verified checker over that calculus;
- running verified erasure and other transformations.

### Where Lambda-Pi Modulo May Be Better

For heterogeneous proof transport or a common interchange language across HOL, CIC-like systems, and other logics, Lambda-Pi modulo is arguably the more natural architecture.

That is precisely why "PCUIC is superior" is the wrong level of abstraction.

---

## 4. Lean 4

Lean is one of the strongest pieces of evidence against a PCUIC-only explanation.

Lean has:

- dependent type theory closely related to Rocq's foundations;
- macros and elaborators;
- a rich tactic framework;
- proof terms checked by a small kernel;
- metaprograms that can inspect and construct expressions.

But Lean's architecture does not thereby become MetaRocq's architecture.

The difference is in what has been formalized and verified around the core, not merely in the existence of dependent products, inductives, and universes.

---

## 5. Agda

Agda provides quotation, reflection, macros, and a type-checker monad.

This shows that the practical shape of Template-style metaprogramming is not unique to PCUIC/Rocq.

Again, the major differentiator is the degree to which the reflected syntax, semantic model, checker, and transformations have been formally connected and verified.

---

## 6. Twelf / LF

Twelf is directly designed for representing deductive systems and proving metatheorems about them.

This is another useful counterexample because it demonstrates that a logical framework can be intentionally optimized for meta-theory without looking like PCUIC.

Its strength is different: higher-order abstract syntax, logic programming, and totality/meta-theorem checking over encoded systems.

---

## 7. The Resulting Taxonomy

The relevant spectrum is not:

```text
Weak Calculus ---------------- Strong Calculus
```

A more useful multi-axis model is:

```text
Native Object-Language Fidelity
Reflection / Quotation Power
Environment Manipulation
Proof-Term / Certificate Discipline
Mechanized MetaTheory
Verified Transformation Library
Verified Runtime / Checker
Verified Compilation to Machine Code
Cross-Logic Interoperability
```

MetaRocq is unusually strong because it scores highly across many of these axes at the same time around Rocq.

That is an ecosystem/architecture result with PCUIC at its semantic center.
