# 3 — Rust projects that take unoptimized Rust code and generate a performance-optimized equivalent

## Executive finding

For the strict interpretation—

> **arbitrary Rust source in → semantically equivalent, faster Rust source out**

—there is **no production-ready general source-to-source optimizer** in the Rust ecosystem.

Rust's production optimization stack overwhelmingly operates **below source level**:

```text
Rust source
  -> HIR
  -> MIR optimizations
  -> LLVM IR / Cranelift IR
  -> PGO / LTO / BOLT / backend optimization
  -> optimized machine code
```

This is excellent for performance, but it does not produce a more optimized `.rs` project that a human can read and continue editing.

The strongest direct exception found is the **Cpp2Rust** project's post-translation Rust optimizer. It really does transform Rust source into improved Rust source, but only for Rust generated under Cpp2Rust's own safe-pointer runtime model.

## Ecosystem map

| Project | Stars | Readiness | Orientation | Ambition | Spectrum | Exact fit | What it optimizes |
|---|---:|---|---|---:|---|---|---|
| [Cpp2Rust](https://github.com/Cpp2Rust/cpp2rust) | **309** | Emerging/research-backed | PLDI 2026 | 5/5 | C3/C5 | **Strong but specialized** | Generated safe Rust source: removes redundant RC/dynamic mutability and recovers simpler ownership. |
| `rustc` MIR optimizer | n/a | Production | Engineering + research | 5/5 | C5 | Adjacent | Mid-level IR, not source output. |
| LLVM backend | n/a | Production | Compiler research/engineering | 5/5 | C5 | Adjacent | Machine-code performance. |
| [cargo-pgo](https://github.com/Kobzol/cargo-pgo) | **793** | Production-capable | Engineering | 4/5 | C5/tooling | Adjacent | Automates PGO and LLVM BOLT workflows. |
| [cargo-wizard](https://github.com/Kobzol/cargo-wizard) | **1,084** | Production-capable | Engineering | 3/5 | tooling | Adjacent | Applies high-performance Cargo/rustc profile/configuration settings. |
| [egg](https://github.com/egraphs-good/egg) | **1,840** | Production-capable research library | POPL/research-driven | 5/5 | C5 | **Builder substrate** | Equality saturation over a user-defined IR; can build optimizers, not a Rust optimizer out of box. |
| Cranelift ISLE | part of Wasmtime/Cranelift | Production compiler substrate | Engineering/research | 5/5 | C5 | Builder substrate | Declarative rewrite rules generate efficient compiler matching code. |
| Cranelift e-graph work | compiler project | Research/emerging | Research | 5/5 | C5 | Builder substrate | Equality-saturation-like backend optimization, still IR-level. |
| [Tensat](https://github.com/uwplse/tensat) | **~142** | Research prototype | Paper-driven | 5/5 | C5 | Domain-only | E-graph tensor optimizer written in Rust; optimizes tensor graphs, not Rust programs. |

## Direct source-to-source optimization: Cpp2Rust

Repository: https://github.com/Cpp2Rust/cpp2rust

Cpp2Rust is significant for this topic independently of its role as a C++ translator.

Its translation initially represents difficult C++ pointer semantics through safe runtime abstractions. The system then performs whole-program analysis that can rewrite the resulting Rust to:

- replace reference-counted representations where unique ownership can be proven;
- replace dynamically checked mutability with statically known Rust mutability;
- simplify indirection and ownership structure;
- reduce runtime overhead introduced by the conservative translation.

That is a genuine:

```text
unoptimized/safe generated Rust
    -> analysis
    -> optimized equivalent Rust
```

pipeline.

### Why it is not the general answer

The optimizer knows facts about the **specific representation introduced by Cpp2Rust**. Arbitrary hand-written Rust has:

- arbitrary unsafe blocks;
- traits/dynamic dispatch;
- proc macros;
- complex async state machines;
- interior mutability chosen intentionally;
- FFI;
- target/feature-specific behavior;
- aliasing invariants not expressible from syntax alone.

So Cpp2Rust demonstrates a powerful architecture, not a universal optimizer.

## rustc MIR optimizer

Official compiler-development documentation describes MIR as the layer after major front-end semantic work and before code generation. MIR is where many Rust-specific optimization opportunities can be expressed without reconstructing source syntax.

Production strengths:

- exact compiler semantics;
- monomorphization context;
- control-flow/data-flow information;
- borrow-checking relationship;
- dead-code and simplification passes;
- constant propagation and related transforms.

Why it does not satisfy the request:

- optimized MIR is not intended to be pretty-printed back into idiomatic Rust source;
- transformations may exploit compiler-only representations;
- monomorphized optimizations do not map naturally to one generic source program;
- source-level comments/names/module architecture are not preserved as optimization objectives.

## Profile-guided optimization: the strongest production route to speed

### cargo-pgo

Repository: https://github.com/Kobzol/cargo-pgo

`cargo-pgo` makes LLVM PGO much easier to use and also supports workflows around LLVM BOLT.

Typical flow:

```text
instrumented build
   -> execute representative workload
   -> merge profile data
   -> optimized rebuild
   -> optional post-link BOLT optimization
```

This can produce large real runtime improvements with no source rewrite.

**Exact-fit classification:** adjacent. It optimizes *the executable generated from Rust*, not Rust source.

### cargo-wizard

Repository: https://github.com/Kobzol/cargo-wizard

Automates configuration knowledge such as:

- release-profile tuning;
- LTO choices;
- codegen-unit choices;
- optimization-level choices;
- size-vs-speed profile decisions.

It helps users stop leaving performance on the table because of configuration, but again the source code does not change.

## Compiler optimizer-construction frameworks

### egg

Repository: https://github.com/egraphs-good/egg

`egg` is one of the most important Rust libraries for building transformational optimizers.

Equality saturation changes the normal rewrite strategy:

```text
traditional:
A -> B -> C
choose each rewrite immediately

e-graph:
A == B == C == ...
record many equivalent expressions
then extract the cheapest according to a cost model
```

This is extremely attractive for the requested source optimizer because the cost model could include:

- estimated runtime;
- allocations;
- clone counts;
- branches;
- vectorization opportunities;
- source complexity.

But `egg` needs:

1. a Rust semantic IR;
2. rewrite laws known to be valid;
3. side-effect/aliasing modeling;
4. extraction back to Rust;
5. correctness validation.

It is therefore a **C5 optimizer kernel**, not a ready-made `rust-optimize-source` command.

### Cranelift ISLE

ISLE is a declarative term-rewriting DSL used in Cranelift. It generates efficient Rust code implementing rewrite/matching logic.

Important architectural lesson:

- optimization rules can themselves be declared at a high level;
- the generator compiles them into fast Rust;
- verification/testing can focus on rule semantics and generated matcher correctness.

For building a new source optimizer, ISLE is a useful model even if it works lower in the compiler stack.

## Domain-specific Rust optimizers

These are evidence that automatic optimization is feasible when the semantic domain is constrained.

### Tensat

Repository: https://github.com/uwplse/tensat

Uses equality saturation to optimize tensor computation graphs. Written in Rust, but input is a tensor graph, not arbitrary Rust source.

### Optimization Engine (OpEn)

Repository family: Optimization Engine / `optimization-engine`

OpEn goes the reverse direction relevant to report 5: a mathematical optimization problem is described at a high level and a fast Rust optimizer module is generated. It is not a Rust-source optimizer, but it demonstrates the benefit of moving the contract *above* implementation code.

### Graph/kernel autotuners and JITs

Various Rust ML/GPU projects perform:

- fusion;
- graph simplification;
- kernel selection;
- autotuning;
- constant folding.

These optimize their own computational IRs, not Rust source. They become relevant only if an application can first be lowered to that IR.

## Profilers and diagnostics: useful, but not transformers

A complete ecosystem survey should explicitly separate **finding bottlenecks** from **rewriting them**.

| Tool/category | Role |
|---|---|
| `cargo-flamegraph` / `perf` integrations | Identify hot functions/stacks. |
| `cargo-bloat` | Attribute binary size. |
| `cargo-llvm-lines` | Attribute LLVM IR/codegen volume. |
| `cargo-show-asm` | Inspect generated assembly. |
| Criterion / iai-callgrind | Benchmark and regression measurement. |
| DHAT/heap profilers | Allocation behavior. |
| Miri/sanitizers | Correctness diagnostics, not speed optimization. |

An autonomous source optimizer would consume these measurements as feedback.

## Why source-level optimization is harder than compiler optimization

Consider a trivial-looking rewrite:

```text
Vec<T> + clone
```

to borrowing/reuse.

A source tool has to know whether changing it alters:

- lifetime/API contracts;
- lock durations;
- aliasing;
- observable drop order;
- destructor side effects;
- async suspension legality;
- Send/Sync constraints;
- downstream trait selection;
- allocation reuse behavior.

The compiler can optimize many of these effects *after* type checking without needing to emit a maintainable source program.

## What a general Rust source optimizer would require

A serious architecture would likely combine:

```text
rust-analyzer / rustc front end
       │
       ▼
whole-program semantic graph
       │
       ├── MIR/Charon-like effect + alias analysis
       ├── profile data from real workloads
       ├── cost model
       └── semantic rewrite rules
       ▼
e-graph / equality-saturation search
       │
       ▼
candidate optimized source
       │
       ├── rustfmt + Clippy
       ├── compile all feature/target matrices
       ├── differential/property tests
       ├── benchmark acceptance gates
       └── proof for critical rewrites where feasible
```

### Candidate rewrite families

- allocation elimination;
- clone/copy elimination;
- iterator fusion;
- bounds-check elimination made explicit through data-layout changes;
- devirtualization or enum specialization;
- memory layout restructuring;
- `HashMap`/tree/vector representation substitutions based on workload;
- batching and buffering;
- lock scope reduction;
- async/task coalescing;
- SIMD/data-parallel transformations;
- repeated parse/serialization elimination;
- cache insertion;
- algorithm substitution.

The last several are **semantic architecture changes**, not peephole compiler optimizations. That is why no current tool safely performs them universally.

## Relation to superoptimization

The user's target is close to **source-level superoptimization**:

> search many semantically equivalent programs and select one with a lower measured/estimated cost.

Rust is a promising language for this because:

- types constrain the search space;
- ownership captures aliasing information;
- MIR is already explicit;
- unsafe boundaries can be isolated;
- property/formal tools (Kani, Verus, Aeneas) can validate high-risk rewrites.

But those advantages have not yet coalesced into one production system.

## Practical categorization

### If the requirement is “make production Rust faster automatically”

Use the mature binary pipeline:

1. representative benchmarks;
2. release-profile tuning;
3. PGO;
4. LTO;
5. BOLT where suitable;
6. allocator/data-layout tuning guided by profiling.

### If the requirement is specifically “emit faster Rust source”

Current choices are:

- **Cpp2Rust optimizer** — if the source came from Cpp2Rust;
- custom domain optimizer using **egg/ISLE/your own IR**;
- compiler-guided/agentic rewrite loop with hard benchmark + equivalence gates.

There is no general mature third choice.

## Bottom line

Rust's production ecosystem is extremely strong at:

```text
Rust -> optimized machine code
```

and increasingly strong at:

```text
domain contract/IR -> optimized Rust or machine code
```

but weak at:

```text
arbitrary Rust -> faster equivalent human-readable Rust
```

Cpp2Rust is the most concrete proof that source-to-source performance recovery works when the input representation is constrained. `egg`, MIR, and ISLE are the strongest reusable foundations for building the generalized version.

## Additional source-optimization and optimizer-kernel findings

### Clippy as a source rewrite corpus

The paired survey correctly separates **Clippy performance/style rewrites** from backend optimization. Clippy can emit machine-applicable source changes and therefore belongs in the source-to-source inventory even though most rules are local rather than whole-program. Its useful families include allocation avoidance, unnecessary clones/conversions, inefficient string/collection patterns, needless indirection, and known standard-library substitutions.

For a verified optimizer, Clippy should be mined as:

```text
pattern
+ semantic precondition
+ replacement
+ proof/validation obligation
```

rather than treated only as a post-generation lint step.

### Additional direct or adjacent source transformations

- **Crown** can eliminate or simplify unsafe pointer/ownership machinery; performance is not its primary goal, but some transformations remove runtime/representation overhead.
- **C2Rust ownership refactoring** is similarly safety/migration oriented but supplies useful source transformation infrastructure and ownership constraints.
- **Cpp2Rust** remains the strongest direct source→source performance-recovery example in the survey because its optimizer removes unnecessary reference counting, dynamic mutability, and boxes introduced by the conservative translation.

### egglog

`egglog` combines e-graphs with Datalog-style relational programming. Compared with a plain e-graph API, it is attractive for a metacompiler because semantic analyses and rewrite relations can be represented declaratively in the same search environment.

A proof-oriented architecture is:

```text
MetaRustIR
   ↓
verified/declared rewrite equalities
   ↓
egg / egglog saturation as untrusted search
   ↓
cost-based extraction
   ↓
small proof/certificate checked by the trusted verifier
```

The search engine need not be part of the trusted computing base if every selected rewrite path is checkable independently.

### Additional compiler/backend systems

| System | Level | Why it matters |
|---|---|---|
| **LTO / ThinLTO** | Whole-program LLVM IR | Production baseline for cross-crate optimization; no source output. |
| **PGO** | Profile-guided backend optimization | Supplies empirical execution weights useful to a future source optimizer. |
| **BOLT via cargo-pgo** | Post-link optimization | Demonstrates another optimization layer after linking. |
| **rustc_codegen_cranelift** | Alternative codegen backend | Useful for backend diversity and compile-speed tradeoffs; not a source optimizer. |
| **rustc_codegen_gcc** | GCC-based Rust codegen | Useful for target/backend diversity and comparing optimization assumptions. |
| **wasm-opt / Binaryen** | WebAssembly binary optimization | Domain-specific post-lowering optimizer; useful for Wasm-target validation. |

### Additional measurement input

The paired report also identifies `cargo-remark` and compiler optimization remarks. Those are especially valuable because an autonomous source optimizer needs not only wall-clock benchmarks but explanations of missed inlining/vectorization/optimization opportunities.

### Proof-constrained source optimization

The combined surveys imply a stronger formulation than “apply fast-looking rewrites”:

```text
Candidates(P) = programs reachable by admitted rewrite schemas

choose P' minimizing:
    measured_cost(P')
  + allocation_cost(P')
  + synchronization_cost(P')
  + source_complexity(P')

subject to:
    Semantics(P') ⊑ Semantics(P)
```

Candidate generation can combine MIR/rustc analyses, egg/egglog equality saturation, profile weights from PGO/perf, LLVM optimization remarks, and domain-specific IRs. The resulting `.rs` source must still pass feature/target builds, tests, benchmark acceptance gates, and—where the semantics model permits—proof or translation validation.

## Primary sources

- Cpp2Rust — https://github.com/Cpp2Rust/cpp2rust
- rustc dev guide, MIR optimizations — https://rustc-dev-guide.rust-lang.org/mir/optimizations.html
- cargo-pgo — https://github.com/Kobzol/cargo-pgo
- cargo-wizard — https://github.com/Kobzol/cargo-wizard
- egg — https://github.com/egraphs-good/egg
- Cranelift — https://github.com/bytecodealliance/wasmtime/tree/main/cranelift
- Tensat — https://github.com/uwplse/tensat

### Additional primary sources retained from the paired report

- https://arxiv.org/abs/2303.10515
- https://doc.rust-lang.org/cargo/reference/profiles.html
- https://doi.org/10.1145/3808266
- https://github.com/egraphs-good/egglog
- https://github.com/rust-lang/rustc_codegen_cranelift
- https://github.com/rust-lang/rustc_codegen_gcc
- https://rustc-dev-guide.rust-lang.org/mir/passes.html
