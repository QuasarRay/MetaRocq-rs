# 1 — Transpilers generating idiomatic, production-ready, reliable, human-readable and concise Rust

## Executive finding

There is **no general-purpose transpiler** that can take arbitrary source code in a major language and reliably emit Rust that simultaneously satisfies all of these properties without validation:

1. semantics preserved;
2. compiles on current stable Rust;
3. safe Rust where safety is possible;
4. idiomatic ownership and borrowing;
5. readable and concise structure;
6. production performance;
7. production maintainability.

The most developed ecosystem is **C/C++ → Rust**. It contains a mature mechanical baseline (`C2Rust`), a new safe-C++ translation line (`Cpp2Rust`), and a large research layer that tries to repair the exact weaknesses of mechanical translation: unsafe pointers, ownership recovery, FFI/library replacement, macro preservation, semantic validation, and idiomaticity.

The critical distinction is:

- **mechanical semantic transport** is increasingly good;
- **automatic idiomatization** is still an open research problem;
- **proof or differential-validation of equivalence** is becoming practical for constrained programs, but is not universal.

## Highest-value projects

| Project | Stars | Readiness | Research orientation | Ambition | Spectrum | Exact fit | What it really gives you |
|---|---:|---|---|---:|---|---|---|
| [C2Rust](https://github.com/immunant/c2rust) | **4,811** | Production-capable foundation | Mixed | 5/5 | C3/C5 | **Strong baseline** | Industrial-scale C→Rust transpilation plus refactoring/post-processing infrastructure. Output is intentionally mechanical and can remain unsafe/unidiomatic. |
| [Cpp2Rust](https://github.com/Cpp2Rust/cpp2rust) | **309** | Emerging / research-backed | Paper-driven (PLDI 2026) | 5/5 | C3/C5 | **Strong, specialized** | C++ subset→fully safe Rust using a runtime pointer model, then a Rust→Rust optimization pass that recovers simpler ownership/mutability where provable. |
| [SACToR](https://github.com/qsdrqs/sactor) | **23** | Research prototype | Paper-driven | 5/5 | C3/C5 | Partial | Static-analysis-guided/agentic C→Rust translation with validation; aimed directly at better semantic and safety results than naïve LLM translation. |
| [CRustS](https://github.com/yijunyu/crusts) | **13** | Research prototype | ICSE-paper driven | 4/5 | C3 | Partial | C2Rust followed by rule-based transformations toward safer/more idiomatic Rust. |
| [Crown](https://github.com/KomaEc/crown) | **34** | Research prototype / WIP | Paper-driven | 4/5 | C3/C5 | Partial | Ownership analysis to convert portions of C2Rust-style unsafe pointer code toward safe Rust. |
| [Concrat](https://github.com/kaist-plrg/concrat) | **15** | Research prototype | Paper-driven | 5/5 | C3/C5 | Partial | Automatic translation of concurrent C idioms into Rust ownership/concurrency structures. |
| **Hayroll** | research artifact | Research prototype | PLDI 2026 | 4/5 | C3 | Partial | C→Rust translation designed to preserve difficult macro/configuration structure more readably than raw flattening. |
| **Forcrat** | research artifact | Research prototype | ASE 2025 | 4/5 | C3 | Partial | Post-processes C2Rust output to replace libc-style I/O with Rust standard-library equivalents using static analyses. |
| **Rustine** | artifact/source publication constrained | Research prototype | Paper-driven | 5/5 | C3/C5 | Partial | Agentic translation designed for complete programs and semantic validation, including programs in the ~10k-LOC range. |
| **VERT** | research artifact | Research prototype | ASE 2025 | 5/5 | C3/C5 | Partial | Multi-language→Rust translation with an executable equivalence oracle based on WebAssembly. |
| **FLOURINE** | research artifact | Research prototype | Paper-driven | 4/5 | C3 | Partial | LLM C→Rust translation coupled to differential fuzzing/repair. |
| **C2SaferRust** | research artifact | Research prototype | Paper-driven | 4/5 | C3 | Partial | Targets unsafe Rust produced by C2Rust and rewrites slices toward safer Rust. |
| **Laertes** | research artifact | Research prototype | OOPSLA prior art | 4/5 | C3/C5 | Partial | Earlier automatic reduction of unsafety in translated C→Rust code. |
| [CRUST](https://github.com/NishanthSpShetty/crust) | ~hundreds | Experimental | Engineering | 3/5 | C3 | Partial | C/C++ syntax translation for smaller/medium programs; narrower semantic coverage than C2Rust. |

### Interpretation

**C2Rust** remains the most important engineering substrate because it already handles the ugly work of parsing/build integration and emits a Rust representation over which later tools can operate. Its output should be treated as a **migration IR expressed in Rust syntax**, not as the desired final idiomatic code.

**Cpp2Rust** is the most interesting new end-to-end architecture found in this search. Its PLDI 2026 design deliberately prioritizes *safe translation first*: C++ pointer semantics are represented through a safe Rust runtime abstraction. A subsequent source-to-source optimizer then removes unnecessary reference counting and dynamic mutability when analysis can prove simpler ownership. That is much closer to the requested “generated Rust that is safe and then made readable/efficient” architecture than classic syntax-directed translation. Its limitation is equally important: the optimization is specialized to code translated under its model; it is not a universal arbitrary-Rust optimizer.

## C2Rust: why it is still the practical baseline

Repository: https://github.com/immunant/c2rust

C2Rust is valuable because it attacks the **whole build**, not only toy functions:

- Clang-based C parsing;
- translation driven from real compilation information;
- Rust generation;
- a refactoring subsystem;
- newer post-processing/agent-oriented workflows;
- a large corpus of real-world usage and prior research.

### Strengths

- Handles real C syntax and build information much better than small research translators.
- Produces code that can be compiled and progressively migrated.
- Mature enough to serve as the front end of a larger migration pipeline.
- Its mechanical nature is useful for differential testing because the initial transformation changes less architecture than an “idiomatic rewrite.”

### Weaknesses relative to this report

- Raw output can contain extensive `unsafe`, raw pointers, C-like control/data organization, FFI calls, and generated verbosity.
- “Compiles” is much weaker than “idiomatic.”
- Refactoring and post-processing cannot infer arbitrary application invariants.
- A human or stronger verifier remains necessary for production confidence.

## Cpp2Rust: strongest recent safe-translation architecture

Repository: https://github.com/Cpp2Rust/cpp2rust

Paper: **Cpp2Rust: Translating C++ to Safe Rust** (PLDI 2026; linked from the repository/paper pages).

The system's notable architecture is:

```text
C++ / compile database
        │
        ▼
Clang AST
        │
        ▼
safe Rust using libcc2rs semantic runtime
        │
        ▼
whole-program Rust analysis
        │
        ├── remove unnecessary reference counting
        ├── recover single ownership where possible
        └── replace dynamic mutability with static Rust mutability where provable
        ▼
simpler safe Rust
```

This matters because it solves translation in two stages:

1. **preserve behavior under a deliberately permissive safe Rust model**;
2. **optimize the safe model toward ordinary Rust**.

That is architecturally more scalable than demanding perfect ownership inference during the first syntax translation.

The published evaluation included WOFF2 and Brunsli-scale code (roughly 13k lines in the reported corpus). The reported performance results also show why this is not a free abstraction: one translated workload was close to native while another incurred a substantial runtime penalty. That makes its source optimizer important rather than cosmetic.

## Research projects that attack one missing dimension

### Ownership and pointer recovery

- **Crown** — https://github.com/KomaEc/crown  
  Reconstructs ownership information from C-like pointer behavior. Strong research value; not a drop-in industrial converter.

- **Laertes** — search by paper title *Translating C to Safer Rust*  
  Important prior art showing that static analysis can automatically reduce the unsafe surface after C2Rust.

- **C2SaferRust** — paper/artifact line focused on LLM-assisted safe rewrites of C2Rust output.  
  Useful as evidence that “mechanical translation → targeted safe rewrite” is viable, but current evaluation does not justify trusting it unattended.

- **SafeTrans** — research line combining translation and iterative validation/repair.  
  High ambition; model-dependent and research-grade.

### Concurrency recovery

- **Concrat** — https://github.com/kaist-plrg/concrat  
  Especially important because pointer ownership is only one part of idiomatic Rust. Translating lock/thread behavior into Rust concurrency types requires cross-function reasoning.

### Macro and build-configuration fidelity

- **Hayroll** — PLDI 2026 artifact.  
  C macros and conditional compilation are a major reason C translators either fail or emit unreadable expansion artifacts. Hayroll is useful because it specifically targets that gap.

### C-library → Rust-library replacement

- **Forcrat** — ASE 2025 research artifact.  
  Reported evaluation covers hundreds of thousands of lines and focuses on transforming C-style I/O calls in translated Rust into standard Rust facilities. This is a good example of a **narrow transformation that can scale much further than a general “make it idiomatic” pass**.

### Equivalence-checked / agentic translation

- **VERT** — *Verified Equivalent Rust Transpilation* research line.  
  Uses an executable oracle to reject translations whose behavior differs. This is conceptually stronger than evaluating generated code on compilation alone.

- **FLOURINE** — couples LLM translation with differential fuzzing.  
  Its reported success rates show both the value and the current ceiling of LLM-only idiomatization.

- **SACToR** — https://github.com/qsdrqs/sactor  
  Combines static reasoning with agentic translation/validation instead of treating an LLM as the sole compiler.

- **Rustine** — paper artifact.  
  Especially relevant because it explores complete programs at larger scales rather than only isolated algorithms.

- **ACTOR** — https://github.com/UW-HARVEST/ACTOR  
  More useful as an evaluation/agentic-translation framework than as one definitive translator. It helps compare migration systems against real corpora.

## Formal / semantics-first translation

The strongest long-term route to *reliable* Rust generation is not necessarily “translate text to text.” It is:

```text
source language
  -> semantic IR
  -> proved/validated transformation
  -> ownership-aware Rust IR
  -> Rust source
```

Relevant ideas/projects:

- **Scylla** (`AeneasVerif/scylla`) — highly constrained/formal C→Rust research.
- **Aeneas/Charon** — extract Rust semantics into verification-oriented forms; useful for proving transformed Rust rather than generating it directly.
- **“Compiling C to Safe Rust, Formalized”** — demonstrates that strong guarantees are possible for a carefully delimited C subset.
- **MetaRocq/Peregrine** (covered in report 5) — an alternative direction: start from a formal executable specification and extract Rust instead of translating an unsafe implementation.

## Non-C/C++ → Rust transpilers found

These are worth cataloguing, but they are not peers of C2Rust in maturity.

| Project | Input | State | Why it is not yet the requested solution |
|---|---|---|---|
| [smelt](https://github.com/Bombatomica64/smelt) | typed TypeScript/Python-like subset | Pre-alpha / experimental | Subset language, not arbitrary production TS/Python. |
| [typescript-to-rust](https://github.com/HoodieCollin/typescript-to-rust) | TypeScript dialect | Experimental | Narrow supported language subset and ecosystem semantics. |
| **Rustly** | Clojure-like language | Alpha/experimental | New-language compiler rather than large legacy migration. |
| **Veltrano** | Kotlin-like DSL/language | Experimental | Source language is designed for compilation to Rust; not an arbitrary Kotlin migrator. |
| **hybrid-transpiler** | C++ | Experimental | Interesting hybrid approach but lacks the validation/evidence depth of C2Rust/Cpp2Rust. |

## Historical prior art

Several older C→Rust projects are useful for design archaeology even when they are no longer sensible foundations:

- **Corrode** — an early semantics-oriented C→Rust compiler.
- older C2Rust forks/one-off translators;
- bindgen-style FFI generators, which generate declarations rather than implementations.

They demonstrate an important distinction: **FFI generation is not transpilation**. `bindgen`, `cxx`, `autocxx`, and Crubit can make C++ callable from Rust, but they do not by themselves replace the C++ implementation with Rust.

## Negative evidence: why “LLM generated and compiles” is not enough

Recent studies of C→Rust translation repeatedly find that:

- many outputs fail to compile;
- some preserve source vulnerabilities;
- some introduce new bugs;
- code quality can regress even when tests pass;
- ownership-safe output can pay runtime costs;
- benchmark suites can reward narrow algorithmic translation while missing build-system/FFI/macros/concurrency complexity.

A 2026 study often referred to as **“The C-to-Rust Fallacy”** evaluated several current transformation systems on Juliet-derived programs and reported large numbers of compile failures and bug-preserving/new-bug cases. This should not be generalized to every translator, but it is strong evidence that generated code requires independent validation.

## What a production-grade pipeline would actually look like

No single current project spans the whole target. The most defensible architecture is compositional:

```text
real build capture
    │
    ├─ C2Rust or Cpp2Rust front end
    ▼
compiling semantic baseline
    │
    ├─ ownership/pointer recovery (Crown / Cpp2Rust optimizer / research passes)
    ├─ API replacement (Forcrat-like passes)
    ├─ macro/configuration preservation (Hayroll-like machinery)
    ├─ concurrency recovery (Concrat-like analyses)
    ▼
idiomatization passes
    │
    ├─ rust-analyzer semantic refactors
    ├─ Clippy/rustfix
    └─ domain-specific transforms
    ▼
validation
    ├─ original-vs-Rust differential tests
    ├─ fuzzing
    ├─ sanitizers/Miri where applicable
    ├─ Kani/Verus/Aeneas for critical kernels
    └─ production workload/performance tests
```

### Best fit by goal

| Goal | Best current base |
|---|---|
| Maximum real-world C coverage | **C2Rust** |
| Safe C++ translation architecture | **Cpp2Rust** |
| Research into fully automatic idiomatization | **SACToR / Rustine / VERT / C2SaferRust / Crown** |
| Preserve difficult macros/configurations | **Hayroll** |
| Replace translated libc I/O idiomatically | **Forcrat** |
| Concurrent-C ownership restructuring | **Concrat** |
| Verification-oriented architecture | **Scylla + Charon/Aeneas-style semantics** |

## Bottom line

The ecosystem has moved beyond “C syntax → ugly Rust syntax.” It now contains credible components for **safe translation, ownership recovery, macro preservation, library replacement, and equivalence checking**. But those capabilities are fragmented.

The most important architectural lesson is to treat generated Rust as a sequence of progressively strengthened representations:

```text
semantics-preserving Rust
    -> safe Rust
    -> ownership-recovered Rust
    -> idiomatic Rust
    -> performance-tuned Rust
    -> independently validated Rust
```

There is still no universal one-button project that reaches the final line for arbitrary production software.

## Additional transpilation and target-side generation findings

The paired survey contained several distinct findings that were not present in the longer baseline. They are retained here without repeating the C2Rust/Cpp2Rust/Crown/Concrat material already covered above.

### &inator — global safe-interface synthesis

**&inator** (PLDI 2026) is relevant because it treats safe Rust interface translation as a global constraint problem rather than a collection of local pointer substitutions. Its design searches for Rust-facing types and borrowing choices that satisfy semantic-equivalence and Rust-correctness constraints while preferring simpler representations. This is a particularly strong donor for a Rustification backend that must synthesize complete public interfaces, not merely replace raw pointers with `Box` or references.

### Additional non-C/C++ transpilers

| Project/family | Input | State in the survey | Relevance |
|---|---|---|---|
| **py2many** | Python → Rust and other targets | Active | Broad multi-target transpilation; useful as a frontend/code-emission reference, but not a proof-grade Rust semantic oracle. |
| **go2rust** | Go → Rust | Early/small | Evidence for Go→Rust mapping experiments; not a mature production migrator. |
| **Kalai** | Clojure → Rust/C++/Java | Early/research | Useful for studying a single semantic frontend with several code-generation backends. |
| **typescript-to-rust / ttr** | TypeScript dialect → Rust | Experimental | Ownership-aware design ideas, but constrained language coverage. |
| **java2rust families** | Java → Rust | Fragmented/early/historical | Mostly mechanical translators; final code commonly needs substantial repair. |

These projects should not be ranked beside C2Rust on production migration maturity. Their value is architectural diversity: they expose different frontend IR, type-mapping, and target-emission choices.

### Industrial output-quality exemplars

A general transpiler should also study projects whose *input is constrained* but whose generated Rust is unusually clean. They are evidence for the target-side design problem even when they are not source-language transpilers.

| Project | Contract/input → Rust | Why it matters for target-side quality |
|---|---|---|
| **Prost** | Protobuf → Rust data types | Terse derive-heavy output and intentionally simple Rust types. |
| **Typify** | JSON Schema → Rust types | Chooses Rust representations from constraints rather than transliterating syntax. |
| **Progenitor** | OpenAPI → async Rust client/CLI/mock code | Strong ergonomic API synthesis and standalone crate generation. |
| **Smithy-rs** | Smithy → AWS SDK/generic clients/servers | Industrial-scale generated source with compilation/test/Clippy validation. |
| **wit-bindgen** | WIT → Component Model bindings | Language-neutral interface IR and generated ABI lowering/lifting. |
| **FIDL** | Fuchsia FIDL → Rust types/proxies/stubs | OS-scale protocol code generation. |
| **windows-rs/windows-bindgen** | Windows metadata → Rust API surface | Very large metadata-driven generation and naming/shaping rules. |
| **UniFFI** | UDL/Rust object model → scaffolding/bindings | Production cross-language boundary design used by Mozilla. |
| **Cap’n Proto Rust** | schema/RPC → Rust | Zero-copy data access plus client/server RPC traits. |
| **FlatBuffers** | `.fbs` → Rust | Mature deterministic schema code generation. |
| **svd2rust** | CMSIS-SVD → Rust peripheral APIs | Low-level hardware contracts mapped into type-safe systems APIs. |
| **CXX / Crubit / autocxx** | C++ boundary → Rust/C++ glue | Strong examples of exposing a Rust-shaped safe boundary rather than raw ABI declarations. |

### Canonical target architecture implied by both surveys

The combined evidence favors a staged target-side pipeline:

```text
source semantics
    ↓
SemanticRustIR
    ↓
representation alternatives
    ↓
ownership + borrow + escape + mutability analysis
    ↓
source-quality / API-quality cost model
    ↓
RustGenIR
    ↓
quote/proc_macro2 or equivalent structured emitter
    ↓
syn validation + prettyplease/rustfmt
    ↓
Rust source + independent equivalence evidence
```

The important separation is between **semantic transport** and **idiomatization**. A safe, conservative intermediate Rust representation can be made progressively more idiomatic only after the semantics are stable enough to validate each rewrite.

## Primary sources

- C2Rust — https://github.com/immunant/c2rust
- Cpp2Rust — https://github.com/Cpp2Rust/cpp2rust
- SACToR — https://github.com/qsdrqs/sactor
- CRustS — https://github.com/yijunyu/crusts
- Crown — https://github.com/KomaEc/crown
- Concrat — https://github.com/kaist-plrg/concrat
- CRUST — https://github.com/NishanthSpShetty/crust
- ACTOR — https://github.com/UW-HARVEST/ACTOR
- Aeneas — https://github.com/AeneasVerif/aeneas
- Charon — https://github.com/AeneasVerif/charon
- Scylla — https://github.com/AeneasVerif/scylla

### Additional primary sources retained from the paired report

- https://arxiv.org/abs/2301.10943
- https://arxiv.org/abs/2303.10515
- https://c2rust.com/manual/
- https://docs.rs/crate/crusts/latest
- https://doi.org/10.1145/3808266
- https://doi.org/10.1145/3808270
- https://github.com/bytecodealliance/wit-bindgen
- https://github.com/google/autocxx
- https://github.com/google/crubit
- https://github.com/mozilla/uniffi-rs
- https://github.com/oxidecomputer/progenitor
- https://github.com/oxidecomputer/typify
- https://github.com/py2many/py2many
- https://github.com/rust-lang/rust-bindgen
- https://github.com/smithy-lang/smithy-rs
- https://github.com/tokio-rs/prost
