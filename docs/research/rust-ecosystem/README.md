# Rust ecosystem transformation/code-generation research — consolidated edition

**Research snapshot:** 2026-10-03

This directory consolidates the ten topic files supplied in two overlapping report families into **five canonical reports**. Repeated classification boilerplate and duplicate project explanations were removed; distinct projects, architectural observations, negative results, and evaluation ideas from both versions were retained.

## Collection

1. [Transpilers generating idiomatic production Rust](01_transpilers_generating_idiomatic_production_rust.md)
2. [Massive Rust project semantic compaction/refactoring](02_massive_rust_project_semantic_compaction_refactoring.md)
3. [Automatic performance optimization of Rust](03_rust_automatic_performance_optimization.md)
4. [Automatic fault tolerance/resilience for Rust](04_rust_automatic_fault_tolerance_resilience.md)
5. [Declarative contracts to production Rust implementation](05_declarative_contract_to_production_rust_implementation.md)
6. [Research/report improvement roadmap](06_RESEARCH_AND_REPORT_IMPROVEMENT_ROADMAP.md)
7. [Merge notes](MERGE_NOTES.md)

## Cross-cutting result

- **Topic 5 is the most mature**: production Rust has many serious schema/IDL/DSL → implementation pipelines.
- **Topic 1 is strongest for C/C++**, with C2Rust as a mature mechanical substrate and Cpp2Rust as a high-ambition safe-translation/source-optimization architecture.
- **Topics 2–4 have a gap at the exact arbitrary-source → improved-source level.** Their strongest ecosystems are compositional: semantic refactoring + validation; compiler/runtime optimization; durable/resilience runtimes + deterministic fault testing.
- Across all five topics, constrained semantic domains are dramatically easier to automate than arbitrary Rust repositories.

## Canonical terminology used by the current reports

The source reports used two incompatible variants of the same `C0–C5` scale. For this consolidated edition, interpret the older labels conservatively and use the following canonical meanings when adding new rows.

### Readiness

| Label | Meaning |
|---|---|
| **Production** | Deployed/used in its documented domain and suitable for ordinary production use there. |
| **Production-capable foundation** | Mature infrastructure, but not itself the requested end-to-end transformer. |
| **Emerging** | Substantial implementation, but young, narrow, or with material deployment limits. |
| **Research prototype** | Primarily a research artifact validating a paper/idea. |
| **Experimental** | Incomplete, pre-alpha, hobby, or explicitly experimental. |
| **Archived / historical** | Useful prior art but not a current default base. |

### Artifact/engine role

| Code | Role | Meaning |
|---|---|---|
| **C0** | Contract/specification | Schema, model, IDL, grammar, policy, or formal specification. |
| **C1** | Binding/type generator | Generates declarations, types, bindings, or data accessors. |
| **C2** | Contract implementer | Generates clients, servers, wrappers, protocol glue, or substantial scaffolding. |
| **C3** | Transformation engine | Rewrites/refactors/translates source programs. |
| **C4** | Application/runtime engine | Executes a higher-level application/workflow/component model. |
| **C5** | Compiler/verifier kernel substrate | Compiler IR, optimizer, analyzer, model checker, verifier, or transformation kernel. |

This is **not truly a single linear spectrum**. The roadmap recommends replacing it with orthogonal columns in the next revision.

### Exact-fit strength

- **Strong** — directly performs a large part of the requested transformation.
- **Partial** — useful and substantive but domain-limited or needs orchestration.
- **Adjacent** — analyzer, validator, runtime, optimizer kernel, or other building block rather than the requested transformer.
- **Not a direct fit** — included to prevent a common category mistake.

### Implementation completeness for contract-driven generation

| Level | Output |
|---|---|
| **I0** | Validation/docs only |
| **I1** | Data types/declarations |
| **I2** | Bindings, serializers, clients |
| **I3** | Server/runtime plumbing + handler interfaces |
| **I4** | Executable domain implementation, with most domain logic supplied declaratively |
| **I5** | Near-complete executable program extracted from an executable/formal specification |

## Important interpretation rules

1. **Stars are an adoption/discovery signal, not a quality score.** Record the observation date.
2. **“Production” is domain-scoped.** A production parser generator is not automatically a production whole-application generator.
3. **Runtime adoption is not source transformation.** Restate/Temporal can provide durability after code adopts their programming model; that is different from transparently rewriting arbitrary Rust.
4. **Compiler optimization is not source optimization.** MIR/LLVM/PGO can make a binary faster without producing improved `.rs` files.
5. **Bindings are not reimplementation.** bindgen/CXX/Crubit can make foreign code callable without translating the foreign implementation into Rust.
6. **Compilation is not equivalence.** A generated project that compiles may still be behaviorally wrong.
7. **“Idiomatic,” “compact,” “fault tolerant,” and “optimized” need explicit metrics/contracts.** The roadmap turns these adjectives into measurable fields.

## Exhaustiveness note

No search can prove that every public/private Rust project has been found. Treat the collection as a **high-recall ecosystem survey**, not a mathematical claim of literal exhaustiveness. The next research pass should make the search protocol reproducible and record negative-search evidence.
