# Human Readable Causal Analysis

## 1. Why This Question Is Easy to Misstate

There are at least four different meanings of "Certifying Metaprogram" that are often collapsed together:

1. **Proof-producing metaprogram**: the metaprogram may be untrusted, but it emits a proof/certificate that a trusted checker independently validates.
2. **Verified metaprogram**: the metaprogram implementation itself has a theorem proving that it satisfies a specification.
3. **Verified metaprogram runtime**: the infrastructure that executes the metaprogram is itself verified.
4. **End-to-end verified executable**: the metaprogram/checker/prover is connected by proof all the way to generated machine code.

MetaRocq is unusually interesting because it has important pieces in more than one of these categories.

But HOL/CakeML is also unusually strong, especially in categories 3 and 4. Lambdapi/Dedukti is unusually strong for logic-independent certificate transport. Lean is unusually strong for programmable proof-term generation. Agda is unusually strong for reflection. Twelf is unusually strong for meta-theory of encoded languages.

Therefore any claim of "superior calculus" that does not first fix the certification dimension is too vague to survive empirical comparison.

## 2. The Actual Causal Layers Inside MetaRocq

### Layer A: Template-Rocq Reflection

This layer gives MetaRocq the ability to see Rocq terms/declarations as data and to move between object-level terms and reflected syntax.

Without this layer, PCUIC could still exist as a beautiful formal calculus, but it would not by itself give a practical plugin author an interface for inspecting the live Rocq environment.

### Layer B: Template Monad / Environment Access

This layer gives metaprograms controlled operations for:

- looking up constants and inductives;
- declaring definitions;
- declaring inductives;
- invoking type-related operations;
- running quoted/unquoted computations against the current logical environment.

This is a major source of practical metaprogramming power.

### Layer C: PCUIC

PCUIC gives the project a cleaned-up and mechanized formal description of the actual dependent calculus that the transformations are supposed to respect.

This is the layer that converts "the generated thing seems to work" into a theorem that can talk about typing, reduction, conversion, evaluation, universes, inductives, etc.

### Layer D: PCUIC MetaTheory

The MetaTheory proves the structural facts needed by verified algorithms and transformations.

Examples include substitution, weakening, confluence, principality, typing preservation results, and related infrastructure.

This is what makes PCUIC usable as a serious semantic contract rather than merely an AST definition plus typing rules.

### Layer E: Verified Algorithms

SafeChecker and erasure are not consequences that appear automatically because PCUIC exists.

They are substantial algorithms plus substantial correctness proofs built on top of PCUIC and its MetaTheory.

### Layer F: Verified Bridges

The Template-Rocq <-> PCUIC translations are essential because the practical reflected syntax and the clean formal calculus are different representations.

Without a trustworthy bridge, a proof about PCUIC could fail to say anything useful about the thing the plugin actually receives from Rocq.

### Layer G: Transformations, Tactics, Extraction, and Plugins

The user-visible certified metaprogramming capability finally appears here.

This is where MetaRocq can actually produce a transformed program, generated declaration, proof, erased program, or plugin behavior.

## 3. Counterfactual Tests

A useful way to identify causality is to ask what happens if one component is held constant while another changes.

### Counterfactual 1: Keep dependent type theory, remove MetaRocq's verified stack

Lean is the clearest example.

Lean's core theory is close enough to Rocq's family that any explanation based only on "dependent type theory is powerful" should predict a similar certified-meta architecture automatically.

It does not happen automatically.

Lean has outstanding metaprogramming, but the verification story and implementation architecture are different.

Therefore the calculus family is not sufficient.

### Counterfactual 2: Use a simpler logic, add a strong verification ecosystem

HOL4 + CakeML + Candle is the clearest example.

The foundational logic is simpler than PCUIC, yet the ecosystem achieves proof-producing tools, verified proof checkers, verified compilers, and a verified interactive theorem prover down to machine code.

Therefore PCUIC's extra expressivity is not necessary for deep certification.

### Counterfactual 3: Use a more logic-independent framework

Lambda-Pi modulo can encode multiple logics and treat user-defined rewriting as part of conversion.

This gives it strengths that PCUIC does not try to have, especially proof interchange and logic-framework generality.

Therefore "superiority" depends on what we optimize for.

## 4. Where PCUIC Really Does Give MetaRocq an Advantage

The strongest defensible intrinsic advantage is **semantic alignment with Rocq's real dependent kernel language**.

Compared to encoding Rocq in HOL or in a generic Lambda-Pi framework, PCUIC gives MetaRocq a representation whose constructs, typing rules, universes, inductives, cumulativity, reduction behavior, and implementation-facing concerns are designed specifically around Rocq.

That reduces the semantic translation distance between:

```text
Rocq Program
<->
Reflected Template-Rocq Syntax
<->
PCUIC
<->
Verified Algorithm / Transformation
```

That is extremely valuable.

But it is a **domain-specific fidelity advantage**, not evidence that PCUIC is a universally more powerful certification calculus.

## 5. Why the Distinction Matters for MetaRocq-rs

If MetaRocq-rs assumes "PCUIC itself is the source of the magic", it risks reimplementing the wrong thing.

The important architecture to preserve is not only the calculus. It is the separation and verified connection between:

- reflective representation;
- semantic contract;
- metatheory;
- executable checker;
- transformation framework;
- proof/certificate boundary;
- extraction/compilation boundary;
- independent checker or second prover.

That separation is more reusable than PCUIC alone.
