# Merge notes

## Inputs consolidated

The collection merged these duplicate/overlapping pairs:

| Canonical output | Long-form input | Alternate input |
|---|---|---|
| `01_transpilers_generating_idiomatic_production_rust.md` | `01_transpilers_generating_idiomatic_production_rust.md` | `01_transpilers_generating_idiomatic_rust.md` |
| `02_massive_rust_project_semantic_compaction_refactoring.md` | `02_massive_rust_project_semantic_compaction_refactoring.md` | `02_whole_project_rust_refactoring_and_compression.md` |
| `03_rust_automatic_performance_optimization.md` | `03_rust_automatic_performance_optimization.md` | `03_rust_performance_optimization_transformers.md` |
| `04_rust_automatic_fault_tolerance_resilience.md` | `04_rust_automatic_fault_tolerance_resilience.md` | `04_rust_fault_tolerance_and_resilience_transformers.md` |
| `05_declarative_contract_to_production_rust_implementation.md` | `05_declarative_contract_to_production_rust_implementation.md` | `05_declarative_contract_to_production_rust_generators.md` |

`README(1).md` was replaced by the expanded canonical `README.md`.

## Deduplication policy

- Repeated snapshot/scope/star-count/classification boilerplate was moved to `README.md`.
- The long-form report was used as the structural backbone for each topic.
- Alternate-report content was retained only where it added a project, mechanism, taxonomy, architectural pattern, metric, or materially distinct explanation.
- Repeated descriptions of the same project were not copied verbatim a second time.
- Cross-topic repetition was **not** removed when the same project serves a genuinely different role. For example, Cpp2Rust belongs in both transpilation and performance optimization; the discussion in each file is topic-specific.

## Material preserved from the alternate reports

### Topic 1
Added: `&inator`; py2many/go2rust/Kalai/java2rust coverage; industrial target-side code-generation exemplars; staged `SemanticRustIR → RustGenIR` architecture.

### Topic 2
Added: Dylint, C2Rust refactoring, CRustS, Rust-lancet, Crown, Concrat, Cpp2Rust optimizer, SplitRS boundary case, macro/derive compaction targets, explicit source-cost function.

### Topic 3
Added: Clippy as rewrite corpus, Crown/C2Rust transformation context, egglog, additional codegen backends and wasm-opt, compiler optimization remarks, proof-constrained source-optimization formulation.

### Topic 4
Added: Nine Lives, fail-rs, Loom, Kani/Verus/Creusot/Prusti/MIRAI/Miri, fuzz/property tools, adjacent repair systems, eight-class failure taxonomy, combined proof/simulation hardening pipeline.

### Topic 5
Added: FIDL/UniFFI/CXX/web-sys details, quicktype/json_typegen/rsgen-avro/Cynic, Diesel/SQLx details, Kubernetes generators, svd2rust/chiptool, parser generators, state-machine generators, and the explicit I0–I5 completeness interpretation.

## Known unresolved issue intentionally documented rather than hidden

The original report families used incompatible meanings for `C0–C5`. The consolidated README chooses one canonical interpretation for backward compatibility, but the roadmap recommends replacing the scalar with orthogonal fields. Existing table values should therefore be re-audited in the next revision rather than mechanically trusted.

## Output manifest

| File | Lines |
|---|---:|
| `01_transpilers_generating_idiomatic_production_rust.md` | 369 |
| `02_massive_rust_project_semantic_compaction_refactoring.md` | 462 |
| `03_rust_automatic_performance_optimization.md` | 457 |
| `04_rust_automatic_fault_tolerance_resilience.md` | 543 |
| `05_declarative_contract_to_production_rust_implementation.md` | 898 |
| `06_RESEARCH_AND_REPORT_IMPROVEMENT_ROADMAP.md` | 1137 |
| `MERGE_NOTES.md` | 58 |
| `README.md` | 83 |
