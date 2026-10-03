# Comprehensive roadmap: improve the Rust ecosystem research and report

## 0. Objective

Turn the current high-recall survey into a **reproducible, evidence-backed, decision-useful research corpus** that answers five separate questions without conflating:

1. source-language → idiomatic production Rust translation;
2. whole-workspace semantic compaction;
3. Rust source → faster equivalent Rust source;
4. Rust/application → more resilient equivalent under an explicit fault model;
5. declarative/formal contract → production Rust implementation.

The current material already has strong breadth. Its largest weaknesses are **taxonomy ambiguity, evidence inconsistency, uneven project-profile depth, and the absence of a reproducible search/evaluation protocol**.

---

# Part I — Problems to fix first

## 1. Replace the overloaded `C0–C5` scalar

### Problem

The two source report families assign different meanings to `C3`, and more fundamentally the concepts do not lie on one true line. A source transformer, runtime engine, parser generator, and theorem prover kernel can all be “deep” for completely different reasons.

### Action

Replace `C0–C5` with independent columns:

| Field | Example values |
|---|---|
| **Input kind** | source code; AST/HIR/MIR; schema; IDL; grammar; SQL; formal program; profile data |
| **Output kind** | Rust source; Rust tokens; generated crate; IR; binary; runtime execution; proof/certificate |
| **Transformation scope** | expression; function; module; crate; workspace; whole program; distributed application |
| **Generated depth** | types; bindings; protocol logic; state machine; runtime integration; near-complete executable |
| **Engine role** | generator; source transformer; runtime; analyzer; verifier; optimizer kernel |
| **Semantic ownership** | syntax only; type/interface semantics; protocol semantics; domain behavior; full executable semantics |
| **Assurance** | none; compile; tests; differential; fuzz/property; model check; proof |
| **Deployment maturity** | prototype; emerging; production-capable; production; archived |
| **Maintenance status** | active; low activity; maintenance-only; archived |
| **Reuse mode** | library API; CLI; compiler plugin; proc macro; codegen backend; runtime |

Keep legacy `C0–C5` only as a compatibility field until every row is migrated.

---

## 2. Split “readiness” into separate evidence dimensions

### Problem

Current labels mix several different facts:

- whether the project is maintained;
- whether its API is stable;
- whether generated output is production-used;
- whether the project itself is research-grade;
- whether the exact feature relevant to this report is mature.

### Action

Give every project four independent maturity fields:

```text
maintenance_status
release/API_stability
production_evidence
relevant_feature_maturity
```

Example:

```text
Project: OpenAPI Generator
overall platform: production
Rust client backend: production/stable
Rust Axum server backend: beta (if still true at snapshot)
maintenance: active
```

Never inherit the maturity of a parent repository into every sub-generator.

---

## 3. Define the adjectives the reports currently use

### “Idiomatic Rust”

Score or describe at least:

- unsafe surface;
- raw pointer exposure;
- ownership/borrowing naturalness;
- standard-library vs foreign-runtime dependence;
- generated naming;
- error handling;
- trait/derive use;
- iterator/combinator use where appropriate;
- module/API shape;
- comment/doc preservation;
- rustfmt/Clippy cleanliness;
- amount of generated compatibility runtime.

### “Compact”

Measure separately:

- authoritative source characters;
- authoritative LOC;
- expanded macro/generated LOC;
- file count;
- directory count;
- item count;
- explicit impl count;
- dependency count;
- duplicated AST/subtree count;
- cyclomatic/cognitive complexity;
- unsafe-block count;
- public API surface;
- compile time;
- proof/verification cost.

Do **not** collapse these into one number until weights are explicitly stated.

### “Optimized”

Separate:

- wall-clock latency;
- throughput;
- allocations;
- peak RSS;
- instruction count;
- cache behavior;
- code size;
- startup time;
- compile time;
- energy if measured;
- source complexity.

Require benchmark workload and hardware/toolchain context.

### “Fault tolerant / resilient”

State the fault model:

- process crash;
- worker/task crash;
- network delay/drop/partition;
- duplicate/reordered messages;
- dependency timeout;
- overload/resource exhaustion;
- storage/torn-write failure;
- Byzantine faults;
- programmer logic bugs.

Then state whether the project provides:

- prevention;
- detection;
- recovery;
- durability;
- supervision;
- retry;
- idempotency;
- compensation;
- consensus/quorum;
- simulation/testing only.

### “Equivalent”

Specify the observation model:

- same returned values;
- same errors/panics;
- same I/O trace;
- same drop/destructor effects;
- same timing constraints;
- same persistence effects;
- same wire/ABI layout;
- same concurrency traces up to an allowed refinement;
- same behavior for all feature/target configurations.

---

# Part II — Canonical project-profile schema

Every project should eventually have one canonical profile in a central catalog. Topic reports should reference that profile and add only topic-specific analysis.

## 4. Required fields for each project

```yaml
name:
canonical_url:
snapshot_date:
snapshot_commit_or_release:
stars_at_snapshot:
license:
primary_language:
maintenance_status:
latest_release:
last_material_commit:
rust_version_or_msrv:
stable_or_nightly:
input_kind:
input_example:
output_kind:
output_example:
source_to_source: true/false
whole_workspace: true/false/partial
semantic_domain:
unsafe_policy:
runtime_dependency:
transformation_scope:
generated_depth:
assurance_method:
production_evidence:
paper:
venue_year:
artifact_url:
evaluation_scale:
performance_evidence:
known_limitations:
reuse_surface:
architecture_notes:
why_relevant_to_topic_1:
why_relevant_to_topic_2:
why_relevant_to_topic_3:
why_relevant_to_topic_4:
why_relevant_to_topic_5:
evidence_confidence:
open_questions:
```

## 5. Evidence-confidence levels

Use a separate evidence level:

| Level | Evidence obtained |
|---|---|
| **E0** | Search result/name only |
| **E1** | README/docs inspected |
| **E2** | Source architecture / manifests / examples inspected |
| **E3** | Generated output, tests, CI, issues, releases inspected |
| **E4** | Paper/artifact/benchmark or production usage independently checked |
| **E5** | Locally reproduced on a representative case |

A strong report should avoid categorical claims from E0/E1 evidence.

---

# Part III — Reproducible search protocol

## 6. Search every source class, not only GitHub repositories

For every topic, search:

1. **GitHub** repositories, topics, code search, organizations, archived repositories, forks.
2. **GitLab** and other public forges.
3. **crates.io / docs.rs** by capability keywords and reverse dependencies.
4. **Rust project/compiler documentation**: rustc dev guide, rust-lang repositories, compiler-team project groups.
5. **Academic indexes**: ACM DL, IEEE Xplore, USENIX, arXiv, DBLP, Semantic Scholar.
6. **Conference artifact pages**: PLDI, POPL, OOPSLA/SPLASH, ICSE, ASE, CAV, OSDI/NSDI/SOSP where relevant.
7. **Research group pages** for compiler, PL, verification, systems, program repair, and synthesis groups.
8. **Issue trackers/discussions** for feature maturity that README prose may overstate.
9. **Release notes/changelogs** to establish whether an advertised capability still exists.
10. **Dependency graphs** to discover hidden generators/IRs used inside larger projects.
11. **RustSec/advisories** when evaluating production/security tooling.
12. **Real downstream repositories** that commit generated code or use the runtime in production.

Record every search query and date.

---

# Part IV — Topic-specific search instructions

## 7. Topic 1: transpilers generating idiomatic production Rust

### Search query families

Use combinations of:

```text
C to Rust transpiler
C++ to safe Rust translator
automatic C Rust ownership recovery
unsafe Rust to safe Rust transformation
Rust migration tool ownership inference
Rust translation differential testing
verified equivalent Rust transpilation
LLM C to Rust compiler repair
Rust pointer analysis migration
Rust FFI to native Rust reimplementation
Rust transpiler source-to-source
Python to Rust transpiler
Go to Rust transpiler
Java to Rust transpiler
TypeScript to Rust transpiler
```

Also search paper terms:

```text
ownership reconstruction
borrow inference
pointer analysis
safe interface synthesis
translation validation
semantic equivalence
program migration
API/library replacement
macro-preserving translation
configuration-preserving translation
```

### Specific research branches to expand

1. **C/C++ migration lineage**
   - C2Rust, Corrode, Laertes, Crown, Concrat, CRustS, C2SaferRust, Cpp2Rust.
   - Follow citations backward and forward from each paper.
   - Inspect artifact repositories and forks that contain code absent from the paper landing page.

2. **Agentic/LLM translation**
   - SACToR, VERT, FLOURINE, Rustine, SafeTrans, ACTOR-like evaluation frameworks.
   - Record model dependence, benchmark construction, compile rate, test/equivalence method, and whether output is actually idiomatic.

3. **Interface synthesis**
   - &inator-like work, Crubit/CXX/autocxx, bindgen, UniFFI.
   - Distinguish “translate implementation” from “generate safe interoperability boundary.”

4. **Non-C source languages**
   - Search by each source language separately.
   - Do not infer maturity from “supports Rust target”; inspect examples and test matrices.

5. **Target-side code quality**
   - Inspect Prost, Typify, Progenitor, Smithy-rs, WIT/FIDL/windows-bindgen.
   - Extract concrete rules for naming, derives, error types, ownership, module structure, doc comments, dependency emission, deterministic formatting.

### Empirical evaluation to add

Create a small common corpus:

- pointer-heavy C;
- C++ RAII and aliasing;
- callback/function-pointer code;
- macro-heavy code;
- conditional compilation;
- file/network I/O;
- concurrency/locks;
- generic/template code where supported.

For each translator record:

```text
translation succeeds?
stable Rust compiles?
unsafe LOC?
Clippy warnings?
runtime dependency size?
source LOC/chars?
tests pass?
differential behavior?
performance delta?
manual edits required?
```

---

## 8. Topic 2: whole-project Rust semantic compaction

### Search query families

```text
Rust automatic refactoring tool
Rust semantic codemod
Rust structural search replace
Rust source reducer
Rust program minimizer
Rust duplicate code detector
Rust code clone refactoring
Rust dead code remover
Rust unused item remover
Rust workspace pruning
Rust automatic derive migration
Rust boilerplate reduction tool
Rust macro synthesis refactoring
Rust verified refactoring
Rust semantics preserving refactoring
Rust program transformation rustc MIR
```

### Research branches

1. rust-analyzer assists and SSR.
2. Clippy + rustfix/cargo fix.
3. Dylint/custom compiler lints.
4. ast-grep, Comby, Rerast and semantic patch systems.
5. cargo-shear, cargo-minify, cargo-udeps, cargo-machete.
6. REM/REM2.0 and verified-refactoring work.
7. C2Rust post-processing, Crown, Concrat, Rust-lancet, Cpp2Rust source optimizer.
8. Clone detection, anti-unification, abstraction synthesis, macro/derive synthesis.
9. Workspace graph simplification: crate merging, module inlining, re-export elimination, feature cleanup.
10. Source reducers such as test-case minimizers—useful algorithmic prior art even when their goal is bug reproduction rather than maintainability.

### Required new distinctions

For every compaction result report all of:

```text
authoritative source reduction
expanded source change
binary-size change
dependency change
compile-time change
runtime-performance change
API-surface change
cognitive-complexity change
proof/validation cost
```

### Hard cases to investigate

- proc macros;
- build.rs-generated code;
- `include!`;
- feature/cfg matrices;
- unsafe invariants;
- FFI;
- doctests/examples/benches;
- downstream public API consumers;
- serialization/wire compatibility;
- generated registries/reflection-like patterns.

---

## 9. Topic 3: automatic Rust source performance optimization

### Search query families

```text
Rust source to source optimizer
Rust superoptimizer
Rust program synthesis optimization
Rust equality saturation optimizer
Rust e-graph compiler
Rust MIR optimization source rewrite
Rust profile guided source optimization
Rust automatic clone elimination
Rust allocation elimination source transformation
Rust autotuning compiler
Rust rewrite system optimizer
Rust partial evaluation source
Rust devirtualization source transformation
Rust SIMD auto transformation
```

### Research branches

1. **Direct source transforms**
   - Cpp2Rust optimizer, Clippy perf rewrites, ownership/pointer simplifiers.
2. **Optimizer kernels**
   - egg, egglog, ISLE, e-graph work in Cranelift/Wasmtime.
3. **Compiler passes**
   - rustc MIR optimizer, LLVM, Cranelift, GCC backend.
4. **Profile feedback**
   - cargo-pgo, BOLT, perf, Samply, Criterion, iai-callgrind, optimization remarks.
5. **Domain optimizers**
   - tensor/graph systems, GPU kernel fusion, database query optimizers, Wasm optimizers, DSL compilers.
6. **Program synthesis/superoptimization literature**
   - Search beyond Rust implementations; identify algorithms that could be instantiated over a Rust semantic IR.

### Evaluation protocol

A source rewrite is accepted only if:

```text
all supported configs compile
tests/properties pass
semantic checker/proof passes where available
benchmark confidence interval shows improvement
no protected secondary metric regresses beyond policy
source remains within maintainability budget
```

Never call a rewrite “optimized” without naming the workload and metric.

---

## 10. Topic 4: automatic fault tolerance and resilience

### Search query families

```text
Rust durable execution
Rust workflow replay runtime
Rust fault tolerant actor supervision
Rust circuit breaker retry bulkhead
Rust chaos testing deterministic simulator
Rust distributed systems simulation
Rust failpoint
Rust crash consistency testing
Rust idempotency middleware
Rust transactional outbox
Rust self healing runtime
Rust model checking distributed system
Rust concurrency model checker
Rust automatic repair resilience
```

### Research branches

1. **Durable execution**
   - Restate, Temporal Rust SDK, AWS durable execution, smaller durable-workflow experiments.
2. **Actor/task supervision**
   - Actix, Ractor, Bastion, Coerce and newer actor systems.
3. **Resilience middleware**
   - Tower, tower-resilience, BackON, Nine Lives, rate-limit/bulkhead/circuit-breaker crates.
4. **Deterministic testing**
   - Loom, Shuttle, MadSim, Turmoil, fail-rs.
5. **Verification**
   - Kani, Verus, Creusot, Prusti, MIRAI, model-checking/state-machine tools.
6. **Crash consistency**
   - storage/database test frameworks, write-ahead logging/checkpoint libraries, transactional primitives.
7. **Effect systems / typestate / session types**
   - search for type-level guarantees about idempotency, protocol state, cancellation safety, or resource lifetimes.
8. **Distributed protocols**
   - consensus/BFT libraries belong in a separate subcategory. Do not imply retries/supervision provide Byzantine tolerance.

### Required fault-contract fields

For every candidate transform/runtime record:

```text
faults handled
safety guarantee
liveness guarantee
durability model
delivery semantics
idempotency requirement
replay determinism requirement
compensation model
state-store assumptions
network assumptions
failure detector assumptions
exactly-once claim and definition, if any
```

### Critical semantic rule

Never evaluate “automatic retry insertion” without an effect contract. A retry can make a program less correct if the operation is non-idempotent or externally irreversible.

---

## 11. Topic 5: declarative contract → production Rust

### Search query families

```text
Rust code generator IDL
Rust schema compiler
Rust OpenAPI generator
Rust AsyncAPI generator
Rust protobuf codegen
Rust Thrift generator
Rust Capn Proto codegen
Rust FlatBuffers generator
Rust WIT bindgen
Rust FIDL generator
Rust WebIDL generator
Rust ASN.1 compiler
Rust SQL query codegen
Rust GraphQL codegen
Rust CRD codegen
Rust SVD codegen
Rust register generator
Rust parser generator
Rust lexer generator
Rust state machine DSL codegen
Rust workflow DSL compiler
Rust UI DSL compiler
Rust policy DSL compiler
Rust formal extraction compiler
```

### Expand contract families systematically

Create one subsection per family:

- service/API IDLs;
- binary/wire schemas;
- component ABIs;
- OS/interface metadata;
- FFI/bindings;
- database/query languages;
- GraphQL;
- Kubernetes/cloud schemas;
- hardware/register schemas;
- parser/lexer grammars;
- state machines/statecharts;
- session types/protocol types;
- event/AsyncAPI contracts;
- declarative UI;
- infrastructure/deployment contracts;
- policy/security languages;
- numerical/optimization DSLs;
- proof-assistant extraction;
- Rust proc-macro/derive internal contracts.

### For every generator answer four questions

1. **What semantics are present in the contract?**
2. **What semantics are supplied by the runtime?**
3. **What logic must a human still write?**
4. **What properties of generated output are tested or verified?**

This prevents “generated server” from being mistaken for “generated business application.”

---

# Part V — Deep inspection of each project

## 12. Do not stop at README claims

For high-priority projects, inspect:

1. repository layout;
2. generator/compiler crates;
3. parser/front-end;
4. intermediate representations;
5. analysis passes;
6. output emitter/templates;
7. runtime support crates;
8. test fixtures/golden outputs;
9. CI matrices;
10. fuzz targets;
11. benchmarks;
12. issue tracker for known correctness/maturity limitations;
13. changelog/releases;
14. downstream users.

### Code-generation-specific questions

- Is output AST/token based or template/string based?
- Is generation deterministic?
- Is formatting separate from semantics?
- Are generated files committed or generated at build time?
- Does the generator emit only used dependencies?
- How are names escaped/sanitized?
- How are recursive types handled?
- How are version/schema migrations handled?
- Are comments/docs preserved?
- Is there a stable IR between parsing and emission?

### Source-transformation-specific questions

- What semantic representation is used?
- Is macro expansion observed or preserved?
- Is analysis intra-procedural, inter-procedural, crate-wide, workspace-wide?
- What alias/effect model exists?
- How are unsafe and FFI handled?
- Are transformations reversible?
- Is there translation validation or only compilation/tests?

---

# Part VI — Add concrete examples to reduce ambiguity

## 13. Every important project needs an input→output example

A project explanation should include a minimal concrete example whenever possible.

### Good profile shape

```text
Project: Typify

Input:
JSON Schema with object/enum/constraint definitions.

Output:
Rust structs/enums plus derives and validation-oriented representation choices.

It owns:
representation selection for schema constraints.

It does not own:
HTTP transport, persistence, business rules, distributed failure semantics.

Why relevant:
demonstrates semantic type mapping rather than syntax transliteration.
```

### For a runtime

```text
Project: Restate

Input:
Rust handlers written against the Restate SDK/runtime model.

Output/effect:
durably recorded execution, retries/timers/state/reliable invocation.

It does not:
take an arbitrary Tokio crate and infer safe idempotency/compensation boundaries.
```

### For an optimizer

```text
Project: cargo-pgo

Input:
compiled/instrumented program + representative runtime profile.

Output:
better optimized executable.

It does not:
emit rewritten `.rs` source.
```

This four-part structure should be mandatory: **input, output, owns, does-not-own**.

---

# Part VII — Verify “production” and “research” claims

## 14. Production evidence checklist

A production label should cite at least two of:

- official production-user statement;
- major downstream dependency/use;
- stable release cadence;
- documented compatibility policy;
- CI on supported Rust versions/targets;
- substantial issue/maintenance activity;
- committed generated output used by a production platform;
- vendor/project documentation explicitly recommending production use.

Do not use GitHub stars as production evidence.

## 15. Research evidence checklist

For paper-backed systems record:

- paper title;
- authors;
- venue/year;
- DOI/arXiv;
- artifact URL;
- artifact badge if any;
- evaluated corpus size;
- LOC/program count;
- success rate;
- baseline comparisons;
- performance overhead/improvement;
- limitations/threats to validity;
- whether the artifact still builds.

Follow both **references** and **papers that cite it** to discover successors.

---

# Part VIII — Build a central project catalog

## 16. Eliminate cross-report duplication without losing context

Create:

```text
00_PROJECT_CATALOG.md
```

with one canonical factual profile per project.

Then each topic report should contain only:

- why the project matters for that topic;
- exact-fit classification for that topic;
- topic-specific limitations;
- comparative conclusions.

For example, `Cpp2Rust` can appear in Topics 1, 2, and 3, but its basic architecture/paper/repository facts should live once in the catalog.

This will materially reduce drift where one file calls a project “MATURE” and another calls it “RESEARCH.”

---

# Part IX — Add a comparison dataset, not just prose

## 17. Machine-readable inventory

Add `projects.csv` or `projects.yaml` with the canonical profile fields. Generate Markdown tables from it rather than editing tables by hand.

Benefits:

- one star count per snapshot;
- one URL;
- one readiness record;
- consistent terminology;
- easy sorting/filtering;
- automated detection of missing fields;
- reproducible report generation.

## 18. Validation script

Add a small report-maintenance script that checks:

- duplicate project aliases;
- dead URLs;
- missing snapshot dates;
- missing evidence links;
- conflicting readiness labels;
- duplicate source sections;
- unknown taxonomy values;
- stale star counts older than the chosen refresh interval.

---

# Part X — Prioritized research execution plan

## Phase P0 — normalization

1. Create `00_PROJECT_CATALOG.md` + machine-readable inventory.
2. Replace scalar `C0–C5` in new work with orthogonal fields.
3. Normalize project names and repository URLs.
4. Separate readiness from maintenance and exact-fit.
5. Add `input / output / owns / does-not-own` to every major project.
6. Mark every current factual claim with evidence level E0–E5.

**Exit criterion:** no project has conflicting basic metadata across topic files.

## Phase P1 — evidence hardening

1. Revisit every “Production,” “archived,” “GA,” “best/strongest,” and paper-venue claim.
2. Capture exact release/commit and snapshot date.
3. Inspect CI/tests/examples for top projects.
4. Add official docs/paper citations next to claims.
5. Replace unsupported superlatives with rubric-specific statements.

**Exit criterion:** every high-impact claim has a primary source and evidence level ≥ E2; production/research claims ≥ E3 where feasible.

## Phase P2 — breadth expansion

Run the query families in Parts IV and collect all plausible candidates before ranking.

For each search:
- record query;
- search engine/database;
- date;
- candidate count;
- included projects;
- excluded projects and reason.

**Exit criterion:** negative claims such as “no general production tool exists” are backed by a documented search log rather than intuition.

## Phase P3 — deep project inspection

For the top 10–20 projects per topic:
- inspect source architecture;
- identify reusable crates/modules;
- inspect generated output;
- inspect tests/benchmarks;
- inspect open issues/maintenance;
- follow papers and successors.

**Exit criterion:** every top-tier project has a detailed architecture profile and explicit limitations.

## Phase P4 — empirical reproduction

Build a small benchmark/evaluation corpus for each topic.

### Topic 1
Translate representative C/C++/other-language cases.

### Topic 2
Run pruning/refactoring on generated and handwritten multi-crate workspaces.

### Topic 3
Benchmark source rewrites and backend optimizers separately.

### Topic 4
Inject crash/network/concurrency failures into small services and workflows.

### Topic 5
Generate real crates from representative contracts and inspect output quality.

**Exit criterion:** high-ranking claims are supported by at least one reproducible local example when licensing/buildability permits.

## Phase P5 — MetaRocq/reuse mapping

For every top project identify:

```text
reuse as dependency?
reuse as algorithm donor?
reuse as IR design donor?
reuse as test oracle?
reuse as untrusted search engine?
reuse as runtime target?
reuse blocked by license/toolchain/architecture?
```

Then map candidates to:

```text
SemanticRustIR
RustGenIR
rewrite-rule library
effect/failure contract
cost model
proof-certificate checker
generated-source emitter
benchmark/test oracle
```

**Exit criterion:** the report explains not merely “this project is interesting,” but exactly what subsystem could be reused and at what trust boundary.

## Phase P6 — maintenance

At each research refresh:

1. update snapshot date;
2. update stars only as secondary metadata;
3. verify archival/maintenance state;
4. check new releases/papers;
5. run URL/metadata validation;
6. re-run saved search queries;
7. inspect newly citing papers;
8. regenerate tables from the machine-readable inventory;
9. document changes in `CHANGELOG.md`.

---

# Part XI — Report structure for the next revision

## 19. Standard structure for every topic file

Use exactly this order:

```text
1. Question being answered
2. Strict inclusion/exclusion criteria
3. Executive answer
4. Definitions and metrics specific to this topic
5. Summary comparison table
6. Project profiles
7. Research frontier
8. Production systems that are adjacent but not exact fits
9. Important non-solutions/category mistakes
10. What is still missing
11. Reusable architecture/components
12. MetaRocq integration map
13. Empirical evidence / reproduced experiments
14. Uncertainties and open questions
15. Search log summary
16. Primary sources
```

This prevents each file from inventing its own taxonomy and narrative shape.

## 20. Standard comparison-table columns

Use:

| Project | Input | Output | Scope | Source output? | Semantic ownership | Assurance | Production evidence | Maintenance | Research evidence | Exact fit | Reuse value |

Topic-specific columns can be appended, but these core columns should remain stable.

---

# Part XII — Specific clarity fixes for the current reports

## 21. Replace unexplained superlatives

Current phrases like:

- “strongest”
- “best”
- “most mature”
- “5/5”
- “Tier S”

should either be removed or qualified:

```text
strongest by X criterion because Y evidence
```

Examples:

- “largest production-generated Rust API surface among the systems inspected”
- “closest literal source→source optimizer found”
- “highest generated implementation depth in the UI domain”
- “strongest deterministic distributed-fault simulation fit among surveyed Rust-native tools”

Do not use an overall score that combines unrelated criteria.

## 22. Separate “project capability” from “proposed MetaRocq architecture”

Each file should have a clear boundary:

```text
Evidence from existing projects
-------------------------------
...

Proposed synthesis / inference
------------------------------
...
```

This prevents a reader from mistaking a proposed pipeline for a capability already implemented by the cited projects.

## 23. Mark negative results explicitly

Use one of:

- **No exact production system found**
- **No exact research system found**
- **Exact capability exists only in a constrained domain**
- **Capability exists below source level, not as `.rs` output**

Then list the search/evidence basis.

## 24. Add “common category mistakes”

Examples:

### Topic 1
FFI/bindings ≠ implementation transpilation.

### Topic 2
binary stripping ≠ source compaction.

### Topic 3
LLVM/PGO ≠ source-to-source optimization.

### Topic 4
retry/supervision ≠ correct transactional recovery.

### Topic 5
types/stubs ≠ generated business logic.

These short sections greatly reduce ambiguity.

---

# Part XIII — Missing information to research for every major project

## 25. Operational metadata

Add:

- license;
- supported platforms;
- stable vs nightly;
- MSRV;
- build system;
- proc-macro/compiler-internal dependence;
- no_std status where relevant;
- incremental/deterministic generation behavior;
- generated code ownership policy;
- compatibility guarantees.

## 26. Reuse cost

For MetaRocq-style reuse, record:

- crate/module boundaries;
- whether internal APIs are public;
- dependency count;
- unsafe code volume;
- size/complexity of runtime dependency;
- possibility of embedding as a library rather than shelling out;
- license compatibility;
- ease of extracting only the relevant analysis or emitter;
- amount of untrusted code that can remain outside the trusted base.

## 27. Output-quality evidence

For generators/transpilers, inspect real generated code and record:

- LOC/chars;
- rustfmt stability;
- Clippy warnings;
- unsafe blocks;
- generated comments/docs;
- trait derivation;
- module count;
- dependency count;
- naming quality;
- error handling;
- API ergonomics;
- runtime overhead.

This converts “human-readable/concise” from a subjective description into inspectable evidence.

---

# Part XIV — Highest-priority unanswered research questions

1. Is there any Rust-native system beyond Cpp2Rust that emits **performance-improved Rust source** rather than IR/binary output?
2. Are there active successors/forks to archived typed rewrite systems such as Rerast that expose rustc-level semantics at workspace scale?
3. Which current projects combine **rust-analyzer/rustc semantics with automatic multi-file fixes**, rather than interactive assists?
4. Which Rust systems synthesize macros/derives/traits from repeated handwritten implementations?
5. Are there research systems for **whole-workspace clone abstraction** or anti-unification in Rust?
6. Which durable-execution systems have a production Rust SDK today, and what exact replay/effect restrictions do they impose?
7. Are there Rust effect systems or type systems that make idempotency/compensation/retry safety machine-readable?
8. Which Rust parser/state-machine/session-type generators reach I4-like domain implementation depth?
9. Which code generators have published metrics for generated source quality, not only runtime correctness?
10. Which formal extraction pipelines produce Rust today, and exactly where does end-to-end verification stop?
11. Can egglog/egg be paired with a stable Rust semantic IR and proof-certificate extraction without placing the search engine in the trusted base?
12. Which projects provide deterministic generation plus semantic golden tests suitable as exemplars for a proof-producing generator?
13. Are there industrial Rust generators comparable to Smithy-rs hidden inside large monorepos/organizations rather than published as standalone crates?
14. Which generated-code ecosystems have explicit policies for schema evolution and backwards compatibility?
15. Which compaction transformations reduce source-of-truth size while preserving debuggability and source maps?

---

# Part XV — Definition of “done” for a substantially improved report

The next major revision is ready when:

- every project has one canonical metadata/profile record;
- all topic tables are generated from that record;
- ambiguous scalar rankings are removed;
- exact-fit, maturity, evidence, and reuse value are separate;
- all major projects have `input / output / owns / does-not-own`;
- top projects have source-architecture inspection;
- negative results have a documented search log;
- representative outputs have been inspected or reproduced;
- important claims cite primary docs/papers;
- proposed MetaRocq architecture is clearly separated from observed ecosystem capability;
- cross-topic duplication is reduced to topic-specific analysis rather than repeated factual biographies;
- every “strongest/best” statement names its criterion or is deleted.
