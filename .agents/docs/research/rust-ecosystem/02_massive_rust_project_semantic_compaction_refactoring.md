# 2 — Whole-project Rust refactoring for materially terser, smaller, equivalent production code

## Executive finding

For the exact requirement—

> take a **massive, production-grade Rust repository as a whole** and automatically emit an **equivalent but meaningfully smaller** repository in lines, characters, files, folders, and boilerplate—

**no mature general-purpose system was found.**

This is a real capability gap.

Rust has excellent production refactoring infrastructure, dead-code/dependency elimination tools, compiler-assisted fixes, and increasingly interesting verified-refactoring research. What it does **not** have is a “semantic compressor” that automatically optimizes the *source representation itself* across an arbitrary workspace.

The ecosystem is best understood as five layers:

1. semantic refactoring engines;
2. automatic compiler/lint fixes;
3. dead-code and dependency pruning;
4. programmable codemods;
5. verification/equivalence substrates.

A system satisfying the user's exact target would need to combine all five.

## Closest projects

| Project | Stars | Readiness | Orientation | Ambition | Spectrum | Exact fit | Contribution |
|---|---:|---|---|---:|---|---|---|
| [rust-analyzer](https://github.com/rust-lang/rust-analyzer) | **16,892** | Production | Engineering | 5/5 | C3/C5 | **Strong substrate** | Semantic model + IDE refactors + Structural Search/Replace across Rust code. Not an autonomous compactor. |
| [Clippy](https://github.com/rust-lang/rust-clippy) | **13,551** | Production | Engineering | 4/5 | C3/C5 | Partial | Thousands of lint analyses; machine-applicable suggestions can simplify code. Local/idiom-oriented rather than global semantic compression. |
| [ast-grep](https://github.com/ast-grep/ast-grep) | **16,108** | Production-capable | Engineering | 4/5 | C3 | Partial | Very fast structural AST search/rewrite at repository scale; programmable rules, not whole-program equivalence. |
| [Comby](https://github.com/comby-tools/comby) | **2,681** | Production-capable | Engineering | 3/5 | C3 | Partial | Structural code matching/rewriting across languages; syntax-aware but less Rust-semantic than rust-analyzer. |
| [cargo-minify](https://github.com/tweedegolf/cargo-minify) | **37** | Emerging | Engineering | 3/5 | C3 | **Direct but narrow** | Removes unused Rust items, mainly useful on generated/overgrown code. One of the few tools whose literal goal is smaller Rust source. |
| [cargo-shear](https://github.com/Boshen/cargo-shear) | **569** | Production-capable | Engineering | 3/5 | C3 | Direct but narrow | Removes unused/misplaced dependencies and detects unlinked files. Shrinks repository/dependency surface, not expression-level code. |
| [cargo-udeps](https://github.com/est31/cargo-udeps) | **2,142** | Production-capable | Engineering | 2/5 | C5/analyzer | Adjacent | Accurate unused dependency detection using compiler information; traditionally requires nightly for execution. |
| [cargo-machete](https://github.com/bnjbvr/cargo-machete) | **~1.3k** | Production-capable | Engineering | 2/5 | analyzer | Adjacent | Fast but intentionally imprecise unused-dependency scanner. |
| [Rerast](https://github.com/google/rerast) | **718** | **Archived** | Engineering/research | 4/5 | C3 | Historical | Typed AST rewriting for Rust. Important ancestor; rust-analyzer SSR is the current direction. |
| **REM 2.0** | research artifact | Research prototype | Paper-driven | 5/5 | C3/C5 | **Research-level strong** | Automated Rust refactoring plus repair and optional formal equivalence reasoning through verification infrastructure. |
| [Charon](https://github.com/AeneasVerif/charon) | **~390** | Research infrastructure | Paper-driven | 5/5 | C5 | Adjacent | Extracts Rust/MIR-like semantics into LLBC for analysis/verification. |
| [Aeneas](https://github.com/AeneasVerif/aeneas) | **~996** | Research infrastructure | Paper-driven | 5/5 | C5 | Adjacent | Translates Rust semantics into proof-oriented functional representations for Coq/F*/Lean/HOL4. |

## What “smaller but equivalent” actually requires

A true source compressor needs to prove or at least strongly validate all of the following:

```text
public API behavior
side effects
error behavior
panic behavior
async/concurrency ordering constraints
unsafe invariants
feature combinations
cfg/target-specific behavior
procedural/build macro semantics
serialization/wire layouts
FFI/ABI contracts
performance-sensitive behavior where part of the contract
```

At workspace scale it also needs to understand:

- Cargo feature graphs;
- build scripts;
- proc macros;
- generated code;
- workspace dependency inheritance;
- examples/tests/benches/binaries;
- hidden API use by downstream crates;
- doctests;
- dynamic registration patterns;
- reflection-like macro inventories;
- `include_*` and generated artifacts.

That is why pure AST minification is insufficient.

## Layer 1 — rust-analyzer as the strongest production refactoring substrate

Repository: https://github.com/rust-lang/rust-analyzer

Rust-analyzer is not an autonomous reducer, but it already solves much of the hard semantic machinery:

- name resolution;
- type inference;
- references/definitions;
- macro-aware syntax views;
- workspace/crate graph understanding;
- structural search and replace;
- rename/move/extract-style refactors;
- syntax-tree editing.

Its **Structural Search Replace (SSR)** is especially relevant. A compactor could encode semantic-preserving patterns such as:

```text
verbose iterator construction -> compact iterator combinator
match boilerplate -> combinator
manual map/unwrap patterns -> standard method
duplicated conversion wrappers -> shared abstraction
```

The missing piece is the **policy/search system that decides which transformations reduce complexity globally** and an equivalence gate that rejects harmful rewrites.

## Layer 2 — Clippy + cargo fix

Repositories/documentation:

- https://github.com/rust-lang/rust-clippy
- https://doc.rust-lang.org/cargo/commands/cargo-fix.html

This is Rust's most mature automatic simplification loop:

```text
compiler / Clippy diagnostic
        │
        ▼
machine-applicable suggestion
        │
        ▼
cargo fix / cargo clippy --fix
```

Useful classes include:

- redundant conversions;
- needless borrows;
- manual standard-library patterns;
- verbose matches;
- needless lifetimes;
- unnecessary allocations/clones in some cases;
- style and idiom simplifications.

But this is intentionally conservative. It does not search for global architectural compression.

## Layer 3 — literal source/dependency deletion

### cargo-minify

Repository: https://github.com/tweedegolf/cargo-minify

This is one of the closest matches to the literal “make the Rust source smaller” requirement.

It attempts to identify and remove unused items. Its strongest use case is generated code or code where normal compiler dead-code warnings cannot conveniently be turned into source deletion.

Limitations:

- public items are difficult because they may be consumed externally;
- macros/dynamic patterns complicate reachability;
- “unused under this build” is not necessarily “unused under every supported feature/target.”

### cargo-shear

Repository: https://github.com/Boshen/cargo-shear

Targets Cargo/workspace bloat:

- unused dependencies;
- misplaced dependencies;
- unlinked source files;
- repository hygiene.

It has demonstrated substantial cleanup on large real workspaces, but it does not rewrite Rust expressions or merge abstractions.

### cargo-udeps / cargo-machete

- https://github.com/est31/cargo-udeps
- https://github.com/bnjbvr/cargo-machete

These are detector foundations. `cargo-machete` explicitly prefers speed over full precision; `cargo-udeps` integrates more deeply with compilation. Neither is an equivalence-proved repository reducer.

## Layer 4 — programmable large-scale codemods

### ast-grep

Repository: https://github.com/ast-grep/ast-grep

Excellent for:

- parallel repository scans;
- tree-structural matching;
- declarative rewrite rules;
- language-aware rather than regex-only matching;
- automated migrations.

For a compaction system, ast-grep is useful as an **execution engine for already-known safe patterns**, not as the reasoning engine that discovers them.

### Comby

Repository: https://github.com/comby-tools/comby

Comby operates on structural syntax templates and is valuable when:

- a migration spans many crates;
- full type information is unnecessary;
- the transformation is syntax-local but formatting-aware.

Again, transformation correctness is the caller's responsibility.

### Rerast

Repository: https://github.com/google/rerast

Rerast is important historical prior art: typed Rust AST rewriting driven by pattern code. The repository is now archived, and rust-analyzer SSR is the better contemporary base.

## Layer 5 — verified refactoring research

### REM 2.0

REM 2.0 is the most relevant research direction found because it explicitly combines:

- automated refactoring;
- repair of resulting borrow/type issues;
- semantic reasoning;
- verification infrastructure based on Charon/Aeneas-style extraction.

Its published evaluation uses features from high-star Rust projects and demonstrates that formal equivalence checking can accompany selected refactors.

However, its central operation is **not “compress an entire repository.”** Extract-function and architecture-preserving refactors may even increase source size. Its importance is that it demonstrates a reusable recipe:

```text
candidate refactor
   -> compiler-guided repair
   -> semantic extraction
   -> equivalence proof/check
```

That recipe is exactly what a future compactor needs.

## Important non-solutions

These are useful Rust tools, but they should not be mistaken for source compaction.

| Tool/category | Why it is not the requested capability |
|---|---|
| `rustfmt` | Changes formatting; usually optimizes consistency, not characters/LOC. |
| `cargo-expand` | Expands macros, making source representations dramatically larger. |
| `cargo-bloat` | Analyzes compiled binary size, not repository source size. |
| `cargo-llvm-lines` | Attributes LLVM IR/codegen size, not source rewriting. |
| Link-time dead-code elimination | Shrinks binary output while source remains unchanged. |
| `cargo-unused-features`-style tooling | Dependency/config pruning only. |
| LLM “refactor this repo” agents | Can perform the task heuristically, but no general equivalence guarantee or canonical Rust compaction objective exists. |

## What is missing from the ecosystem

The absent project would need a global objective something like:

```text
minimize:
    weighted(
      source_chars,
      source_lines,
      number_of_items,
      number_of_modules,
      number_of_files,
      duplicated_semantic_patterns,
      dependency_count,
      public_surface_complexity
    )

subject to:
    compile(all supported feature/target matrices)
    && same externally observable behavior
    && same ABI/wire contracts where required
    && tests/properties preserved
    && unsafe invariants preserved
```

This is **program superoptimization at source architecture scale**, not ordinary refactoring.

## Best existing architecture for building it

A high-confidence composition would be:

```text
Cargo metadata + rust-analyzer crate graph
               │
               ▼
       semantic inventory
               │
       ┌───────┴────────┐
       ▼                ▼
   Charon/MIR       syntax/HIR
 reachability       structures
       │                │
       └───────┬────────┘
               ▼
     candidate reductions
       │        │        │
       │        │        ├─ cargo-shear / udeps: dependencies/files
       │        ├────────── cargo-minify: unreachable items
       └────────────────── rust-analyzer SSR / ast-grep: rewrites
               │
               ▼
       compile + lint + test
               │
               ▼
    differential/property tests
               │
               ▼
 optional Aeneas/REM-style proof
```

### Candidate optimization families

A serious compactor should search for:

- dead private modules/items;
- duplicate generic helpers;
- wrappers that are identity functions after monomorphization;
- duplicated enums/error plumbing that can share a representation;
- repeated trait forwarding;
- hand-written boilerplate replaceable by derives/macros;
- repeated match ladders replaceable by data-driven maps/tables;
- duplicated conversions;
- redundant type aliases/newtypes when they do not encode invariants;
- feature-gated branches that are provably obsolete;
- dependencies used only for trivial functionality that standard library already provides;
- generated files replaceable by declarative generation **only if source-of-truth size** is the objective;
- module/file merges where file boundaries add no isolation value.

## Macro compression is a special case

Macros can reduce handwritten LOC dramatically but can also **increase semantic opacity** and expanded code size.

A source-compaction system therefore needs separate metrics:

```text
authoritative source size
expanded source size
compiled code size
human comprehension cost
proof/verification cost
```

A procedural macro that turns 2,000 handwritten lines into 80 declarative lines is a success for *source-of-truth compaction*, but not necessarily for compiled-code size.

## Strength ranking for the exact task

### Strongest foundations

1. **rust-analyzer** — best production semantic edit substrate.
2. **Clippy + cargo fix** — safest existing automatic idiomatization/simplification pass.
3. **Charon + Aeneas / REM 2.0 architecture** — strongest route to semantic-equivalence validation.
4. **ast-grep** — excellent large-scale rewrite executor once rules are known.
5. **cargo-minify + cargo-shear + cargo-udeps/machete** — actual deletion/pruning layer.

### What none of them supplies

None autonomously discovers the globally smallest maintainable equivalent architecture of an arbitrary Rust workspace.

## Bottom line

Rust has nearly all the **components** needed to build a conservative source compactor, but not the final integrated system.

The closest realistic interpretation today is:

```text
automatic prune
+ compiler-approved local simplification
+ semantic codemods
+ equivalence validation
```

not:

```text
cargo compact-my-entire-production-codebase
```

The research opportunity is unusually strong because Rust exposes richer type/ownership information than most languages and already has excellent compiler tooling. The missing innovation is the **global optimization objective + transformation search + equivalence gate**.

## Additional whole-workspace compaction findings

The paired survey adds several tools and compaction targets that are not redundant with the layer model above.

### Additional refactoring and transformation infrastructure

| Project | Role | Why it belongs in a compactor |
|---|---|---|
| **Dylint** | Custom rustc-integrated lints/suggestions | Lets a project encode organization-specific semantic simplifications using compiler internals. |
| **C2Rust refactor/postprocess** | Large-scale Rust rewriting after C translation | Useful prior art for ownership-directed and mechanically generated-code cleanup. |
| **CRustS** | Large rule corpus for Rust transformation | Demonstrates breadth of reusable transformation schemas. |
| **Rust-lancet** | Compiler-error-guided repair | Shows that generated refactors can be repaired automatically when ownership/type constraints are violated. |
| **Crown** | Ownership/mutability analysis and safer-pointer rewriting | Relevant to collapsing pointer-management boilerplate. |
| **Concrat** | Lock/concurrency restructuring | Example of replacing verbose low-level synchronization structure with stronger Rust abstractions. |
| **Cpp2Rust optimizer** | Rust→Rust simplification of conservative ownership machinery | Direct evidence that source-level representation recovery can improve readability and runtime cost together. |
| **SplitRS** | Structural module splitting | It is mostly an anti-goal for compaction, but useful as a boundary case: structural refactoring may intentionally increase files while improving organization. |

`cargo-shear` also has reported trophy cases where large amounts of dead project structure were deleted; the paired report cites a case of **1,588 LOC removed**. This should be treated as evidence for pruning potential, not as evidence of general semantic compression.

### High-level abstraction targets for automatic compression

A semantic compactor should be able to recognize verbose handwritten patterns and synthesize a smaller declarative representation when the equivalence conditions are met.

| Compact target | Verbose implementation family it may replace |
|---|---|
| built-in `#[derive]` | Handwritten `Clone`, `Debug`, `Eq`, `Ord`, `Hash`, `Default`, etc. |
| `derive_more` / `Educe` | Repetitive conversions, formatting, arithmetic, customized builtin trait impls |
| `thiserror` / `displaydoc` | Error `Display`, `Error`, `source`, `From`, formatting boilerplate |
| Serde derives | Manual serialization/deserialization |
| `auto_impl` | Repeated proxy impls for `&`, `Box`, `Rc`, `Arc` |
| `Ambassador` / `delegate` | Forwarding/delegation implementations |
| `Strum` | Enum parsing/display/iteration/property boilerplate |
| `enum_dispatch` | Repeated match-based enum dispatch |
| `getset` / `gset` | Getter/setter families |
| `bon` / `typed-builder` / `derive_builder` | Builder-state boilerplate |
| `pin-project` | Unsafe pin-projection boilerplate |
| `impl-trait-for-tuples` | Repeated tuple trait implementations |
| `num_enum` / `enum-as-inner` | Enum conversions and accessors |
| bitfield macros | Masks/shifts/accessor boilerplate |
| `paste`, `seq-macro`, `duplicate` | Repeated declaration families |

This is qualitatively different from whitespace minification: it replaces a large explicit implementation with a smaller **source of truth** plus a generator.

### Source-compaction objective

The paired report proposed an explicit search objective that should be retained:

```text
cost(P) =
    chars(P)
  + α·LOC(P)
  + β·files(P)
  + γ·directories(P)
  + δ·explicit_impl_blocks(P)
  + ε·duplicated_AST_nodes(P)
  + ζ·unsafe_blocks(P)
  + η·cyclomatic_complexity(P)
```

with a hard semantic constraint such as:

```text
Semantics(P_before) ≡ Semantics(P_after)
```

In practice this objective should later be split into independent metrics for authoritative source size, expanded/generated size, binary size, dependency surface, comprehension cost, and proof cost; the roadmap explains why.

## Primary sources

- rust-analyzer — https://github.com/rust-lang/rust-analyzer
- Clippy — https://github.com/rust-lang/rust-clippy
- ast-grep — https://github.com/ast-grep/ast-grep
- Comby — https://github.com/comby-tools/comby
- cargo-minify — https://github.com/tweedegolf/cargo-minify
- cargo-shear — https://github.com/Boshen/cargo-shear
- cargo-udeps — https://github.com/est31/cargo-udeps
- cargo-machete — https://github.com/bnjbvr/cargo-machete
- Rerast — https://github.com/google/rerast
- Charon — https://github.com/AeneasVerif/charon
- Aeneas — https://github.com/AeneasVerif/aeneas
- Cargo fix — https://doc.rust-lang.org/cargo/commands/cargo-fix.html

### Additional primary sources retained from the paired report

- https://arxiv.org/abs/2303.10515
- https://arxiv.org/abs/2601.19207
- https://doi.org/10.1145/3597503.3639103
- https://github.com/immunant/c2rust
- https://github.com/trailofbits/dylint
- https://rust-analyzer.github.io/book/assists.html
- https://rust-analyzer.github.io/book/features.html
