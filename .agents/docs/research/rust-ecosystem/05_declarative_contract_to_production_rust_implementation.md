# 5 — Machine-readable declarative application contracts → production-ready Rust implementation

## Executive finding

This is by far the **richest and most production-ready** of the five categories.

However, “generate implementation” has several distinct meanings:

```text
contract
  ├─> types only
  ├─> bindings/FFI declarations
  ├─> client implementation
  ├─> server transport + handler skeleton
  ├─> database/query implementation
  ├─> UI implementation + runtime
  ├─> protocol/state-machine implementation
  └─> executable program extracted from a formal specification
```

Many tools marketed as code generators stop at **types or stubs**. They do not infer business logic.

The strongest production systems succeed because their contract language is rich enough that the missing semantics are either:

1. unnecessary (e.g. client SDK generation);
2. supplied by a runtime (UI/serialization/RPC);
3. supplied by user-written handlers;
4. present in the formal/executable specification itself.

## High-level leaderboard

| Project/family | Stars | Readiness | Contract type | Spectrum | Implementation completeness | Exact fit |
|---|---:|---|---|---|---|---|
| [Smithy-rs](https://github.com/smithy-lang/smithy-rs) | **686** | Production | Smithy model/IDL | C0→C2/C4 | **High for clients / strong server framework generation** | **Strong** |
| [Tonic / grpc-rust](https://github.com/grpc/grpc-rust) | **12,491** | Production | Protocol Buffers/gRPC | C0→C2 | Client + server transport/stubs; handlers remain application code | **Strong** |
| [Prost](https://github.com/tokio-rs/prost) | **4,779** | Production | Protocol Buffers | C0→C1 | Rust message/types generation | Strong component |
| [OpenAPI Generator](https://github.com/OpenAPITools/openapi-generator) | very large | Production overall; generators vary | OpenAPI v2/v3 | C0→C1/C2 | SDK clients + server stubs/docs/config; Rust server targets vary in maturity | **Strong** |
| [Progenitor](https://github.com/oxidecomputer/progenitor) | **1,017** | Production-capable | OpenAPI 3 | C0→C2 | Opinionated async Rust client implementation | Strong |
| [Typify](https://github.com/oxidecomputer/typify) | **907** | Production-capable | JSON Schema | C0→C1 | Idiomatic Rust data types | Strong component |
| [Cap’n Proto Rust](https://github.com/capnproto/capnproto-rust) | **2,515** | Production | Cap’n Proto schema/RPC | C0→C2 | Types/readers/builders + RPC interfaces/client/server machinery | **Strong** |
| Apache Thrift Rust | mature ecosystem | Production | Thrift IDL | C0→C2 | Rust types, clients, server plumbing | Strong |
| FlatBuffers Rust | mature ecosystem | Production | `.fbs` schema | C0→C1 | Efficient generated access/types | Strong component |
| [wit-bindgen](https://github.com/bytecodealliance/wit-bindgen) | **1,466** | Production-capable/emerging Component Model | WIT | C0→C2 | Guest/host bindings, traits, ABI/component glue | **Strong** |
| [windows-rs](https://github.com/microsoft/windows-rs) | **12,789** | Production | Windows metadata (`.winmd`) | C0→C1/C2 | Massive generated Rust API bindings | **Strong** |
| [rust-bindgen](https://github.com/rust-lang/rust-bindgen) | **5,301** | Production | C/C++ headers | C0→C1 | Raw Rust FFI bindings | Strong component |
| [Crubit](https://github.com/google/crubit) | **1,122** | Emerging/serious | C++/Rust declarations | C0→C2 | Generated cross-language glue/interfaces | Strong, domain-limited |
| [autocxx](https://github.com/google/autocxx) | **2,560** | **Archived as of 2026 snapshot** | C++ headers | C0→C2 | Safer C++↔Rust interfaces | Historical/maintenance caution |
| [Cornucopia](https://github.com/cornucopia-rs/cornucopia) | **~1.1k** | Production-capable | PostgreSQL SQL queries/schema | C0→C2 | Type-checked Rust query interfaces; close to handwritten DB performance | **Strong domain implementation** |
| [graphql-client](https://github.com/graphql-rust/graphql-client) | **1,266** | Production-capable | GraphQL schema + query documents | C0→C1/C2 | Typed request/response client code | Strong component |
| [rasn](https://github.com/librasn/rasn) | **385** | Production-capable | ASN.1 | C0→C1/C2 | Generated bindings + codec framework | Strong niche |
| [Slint](https://github.com/slint-ui/slint) | **24,050** | Production | Declarative `.slint` UI DSL | C0→C3/C4 | Compiles declarative UI into Rust/native implementation + runtime | **Very strong domain example** |
| [MetaRocq](https://github.com/MetaRocq/metarocq) + Peregrine | ~hundreds / research | Research infrastructure | Formal executable specification/proofs | C0→C3/C5 | Can extract computational content toward Rust through research toolchains | **Extreme ambition; research** |

## A more useful measure: implementation completeness

This report uses a second scale because “generated code” is too vague.

| Level | Output |
|---|---|
| **I0** | validation/docs only |
| **I1** | data types / declarations |
| **I2** | bindings, serializers, clients |
| **I3** | server/runtime plumbing + handler interfaces |
| **I4** | executable domain implementation, with user logic mainly supplied declaratively |
| **I5** | near-complete executable program extracted from an executable/formal specification |

Most mainstream API generators are **I1–I3**. Slint reaches **I4 within UI semantics**. Proof-assistant extraction can approach **I5**, but the “contract” is then effectively a formal program/specification, not a simple API schema.

# A — API and service IDLs

## Smithy-rs — one of the strongest production proofs

Repository: https://github.com/smithy-lang/smithy-rs

Smithy is much richer than OpenAPI as a modeling system. It describes:

- services;
- operations;
- input/output structures;
- traits;
- protocol behavior;
- errors;
- constraints;
- reusable model shapes.

`smithy-rs` turns those models into Rust client/server code.

### Why it matters

The strongest evidence of production readiness is not the star count: the AWS SDK for Rust is generated from Smithy models using this ecosystem.

That is a real demonstration of:

```text
machine-readable service model
    -> large Rust API surface
    -> production client implementation
```

It is still important not to overstate it. Smithy does not infer arbitrary server business decisions; handlers implement application-specific behavior.

**Spectrum:** C0→C2/C4  
**Completeness:** I2–I3, exceptionally deep for generated clients.

## OpenAPI Generator

Repository: https://github.com/OpenAPITools/openapi-generator

Given OpenAPI v2/v3 it can generate:

- client SDKs;
- server stubs;
- documentation;
- configuration/model code.

The overall platform is mature, but each Rust generator has its own maturity label. For example, the Rust Axum server generator has been documented as **beta**, so “OpenAPI Generator is mature” must not be converted into “every Rust backend is mature.”

### Strengths

- enormous multi-language ecosystem;
- template customization;
- established CI/codegen workflows;
- easiest bridge from conventional API contracts.

### Limit

OpenAPI describes transport-level behavior well but generally cannot specify:

```text
how inventory is reserved
how money is moved
which distributed invariant must hold
how authorization policy is computed
how a workflow compensates
```

So server output is fundamentally a scaffold unless custom extensions/templates encode more semantics.

## Progenitor

Repository: https://github.com/oxidecomputer/progenitor

A focused Rust OpenAPI client generator.

Particularly good when the desired output is:

- strongly typed;
- async;
- opinionated;
- integrated into an existing Rust codebase;
- less “generic multi-language template system” than OpenAPI Generator.

**Completeness:** I2.

## Tonic + Prost

Repositories:

- https://github.com/grpc/grpc-rust
- https://github.com/tokio-rs/prost

This is among the strongest Rust contract→implementation pipelines:

```text
.proto
  │
  ├─ prost-build -> Rust message types / codec metadata
  └─ tonic-build -> client + server service interfaces / transport glue
```

Generated code covers substantial protocol implementation:

- serialization/deserialization;
- HTTP/2 gRPC integration;
- service traits;
- client calls;
- streaming surfaces;
- status/error transport.

Application handlers still supply domain semantics.

**Completeness:** I2–I3.

## Apache Thrift

Thrift IDL can generate Rust:

- data structures;
- protocol/serialization handling;
- service clients;
- service processors/server integration.

It is an important inclusion because it demonstrates the same contract-driven model outside the Protobuf/OpenAPI ecosystem.

## Cap’n Proto Rust

Repository: https://github.com/capnproto/capnproto-rust

Schema generation includes highly specialized zero-copy-oriented readers/builders and RPC interface support.

This is not merely “Rust structs from schema.” Much of the wire-access implementation is generated from the schema contract.

**Completeness:** I2–I3.

## FlatBuffers

FlatBuffers schemas (`.fbs`) generate Rust access code for a memory-layout/wire-format contract.

Strong for:

- data-plane schemas;
- zero-copy/read-efficient access;
- cross-language contracts.

Not a business application generator.

**Completeness:** I1–I2.

# B — JSON Schema and data-model contracts

## Typify

Repository: https://github.com/oxidecomputer/typify

Typify turns JSON Schema into idiomatic Rust types.

This is exactly the right tool when the contract is:

```text
valid data shape
constraints
enums
objects
references/composition
```

It deliberately does **not** invent application behavior.

**Completeness:** I1.

## schemars — reverse direction, not the requested direction

`shemars`/`schemars`-style tooling derives JSON Schema from Rust types.

Useful, but it is:

```text
Rust -> contract
```

not:

```text
contract -> Rust implementation
```

It belongs in the ecosystem map only to prevent direction confusion.

# C — WebAssembly Component Model / interface contracts

## WIT + wit-bindgen

Repository: https://github.com/bytecodealliance/wit-bindgen

WIT describes typed component interfaces independent of implementation language.

`wit-bindgen` generates Rust bindings/traits that implement the canonical ABI boundary.

This is especially important architecturally because the contract is not just HTTP:

```text
typed component world/interface
    -> imports/exports
    -> generated ABI lowering/lifting
    -> Rust traits/types
```

`cargo-component` then integrates project creation/build/component packaging.

This is one of the strongest modern examples of **language-neutral contract → executable integration layer**.

**Completeness:** I2–I3.

# D — system metadata and foreign interfaces

## windows-rs / windows-bindgen

Repository: https://github.com/microsoft/windows-rs

Windows API metadata is a giant machine-readable contract. `windows-rs`/binding-generation infrastructure turns it into a vast Rust API surface.

This is a production-scale proof that declarative metadata can generate maintainable Rust interfaces across an enormous platform API.

**Completeness:** I1–I2.

## rust-bindgen

Repository: https://github.com/rust-lang/rust-bindgen

Input:

```text
C/C++ headers
```

Output:

```text
Rust FFI declarations/layouts/constants
```

Extremely useful, production mature, but output is bindings—not a Rust reimplementation of the foreign library.

## Crubit

Repository: https://github.com/google/crubit

Crubit targets bidirectional C++↔Rust interoperability and generated glue. Compared with raw bindgen, it attempts richer language mapping and generated shims.

Important deployment caveat: integration outside the build environments it targets should be evaluated carefully.

## autocxx

Repository: https://github.com/google/autocxx

Historically an important higher-level C++→Rust interop generator. The repository was **archived in the 2026 snapshot**, so it should now be treated as prior art / existing-user tooling rather than the default new foundation.

# E — database and query contracts

## Cornucopia

Repository: https://github.com/cornucopia-rs/cornucopia

Cornucopia is one of the best examples that goes beyond “schema → struct.”

Workflow:

```text
PostgreSQL query
     │
     ├─ prepare/validate against real database
     ▼
known parameter/result types
     │
     ▼
generated Rust crate / query interfaces
```

Current 1.x documentation emphasizes:

- type-checked SQL;
- generated Rust interfaces;
- sync/async support;
- custom PostgreSQL types;
- performance close to hand-written `rust-postgres`.

This is **declarative query contract → production data-access implementation**.

**Completeness:** I2/I4 within the data-access domain.

## SeaORM / SeaSchema family

Database schema introspection can generate Rust entity models. This is useful for broad CRUD/data modeling but still leaves application rules to the service layer.

## SQLx macros — compile-time checking, not generation of whole implementations

SQLx validates queries/types at compile time but is usually *embedded Rust with checked SQL*, not an external declarative contract transformed into a separate generated service.

# F — GraphQL

## graphql-client

Repository: https://github.com/graphql-rust/graphql-client

Input:

- GraphQL schema;
- GraphQL query document.

Output:

- typed Rust query variables;
- typed response structures;
- client integration.

This is stronger than generating all types from the schema because it specializes output to the **actual query contract**.

**Completeness:** I1–I2.

Server-side GraphQL frameworks often go in the opposite direction: Rust resolver/type definitions produce a schema. Those do not meet the direction requested here unless paired with a schema-first generator.

# G — ASN.1 and telecom/protocol schemas

## rasn

Repository: https://github.com/librasn/rasn

ASN.1 is a much older and in some domains much richer declarative contract than JSON Schema.

The rasn ecosystem provides:

- codecs;
- ASN.1 type support;
- compiler/generator facilities for Rust bindings.

Important for:

- telecom;
- security protocols;
- standards-heavy binary protocols.

This is exactly why an ecosystem survey should go beyond OpenAPI/YAML.

# H — declarative UI as executable application contract

## Slint

Repository: https://github.com/slint-ui/slint

Stars: **24,050** snapshot.

Slint is one of the strongest counterexamples to the idea that declarative generators only make “types.”

A `.slint` file declares:

- component hierarchy;
- properties;
- bindings;
- states;
- layout;
- event/data-flow relationships;
- UI expressions.

The compiler performs:

```text
lexing
-> parsing
-> optimization
-> target-language code generation
```

Its Rust backend **generates Rust code**, and the runtime implements the declarative property/component semantics.

Slint's own architecture explicitly separates:

```text
declarative UI contract
          +
business logic in Rust/C++/JS/Python
```

So it reaches **I4 for the UI domain**, while intentionally not generating unrelated business logic.

This is an excellent architecture pattern for a broader application generator:

> make the declarative contract rich enough to fully own one semantic domain, then provide explicit interfaces where human code begins.

# I — Wayland, D-Bus, and other interface description formats

## Wayland protocol XML

The `wayland-rs` ecosystem includes scanner/codegen machinery that consumes Wayland protocol XML and generates Rust protocol interfaces.

This is a mature example of:

```text
XML protocol contract -> Rust client/server protocol code
```

## D-Bus introspection XML

The `zbus` ecosystem has code-generation/introspection tools that can turn D-Bus interface metadata into Rust proxy/interface code.

Again, this is contract-driven implementation beyond HTTP schemas.

# J — state machines and session/protocol types

This area is less standardized than Protobuf/OpenAPI, but conceptually more powerful.

## State-machine proc-macro/DSL crates

Rust has multiple crates that let users declare states and transitions and then generate:

- state enums/types;
- typestate transitions;
- event dispatch;
- compile-time invalid-transition prevention.

These are real **contract → implementation** systems, but the contract is usually embedded in Rust macros rather than external JSON/YAML.

## Rumpsteak / MPST ecosystems

Multiparty session-type projects encode communication protocols into type-level/contracts and generate or constrain communicating endpoints.

Their key contribution is not “write less code”; it is:

```text
global protocol
-> endpoint/session constraints
-> deadlock/protocol mismatch prevention
```

Most remain research-oriented compared with gRPC.

## SCXML

Rust SCXML implementations typically interpret/execute W3C statecharts rather than necessarily emit standalone Rust source. They still fit C0→C4: declarative state-machine contract interpreted by an application engine.

# K — AsyncAPI and event-driven service contracts

The ecosystem is materially weaker than OpenAPI/gRPC.

A research/student project such as **Crustagen** has explored:

```text
AsyncAPI -> buildable Rust microservice structure
```

but official AsyncAPI generator/template inventories have historically had much weaker first-class Rust support than Java/TypeScript ecosystems.

This is a real gap and a promising target because AsyncAPI can describe:

- channels;
- messages;
- producers/consumers;
- broker bindings;
- event schemas.

A production Rust generator could combine AsyncAPI with Tower/axum/tonic/NATS/Kafka abstractions and resilience contracts.

# L — formal specifications and proof-assistant extraction

This is the most ambitious end of the spectrum.

## MetaRocq

Repository: https://github.com/MetaRocq/metarocq

MetaRocq formalizes substantial parts of Rocq's term language, typing/metatheory, quotation, erasure, and certified transformations.

It changes the meaning of “contract”:

- the contract can be a formal program and proof;
- computational content can be erased/extracted;
- correctness evidence can travel with the transformation chain.

## Peregrine

Repository family:
https://github.com/peregrine-project

Peregrine aims at a verified compiler/extraction middle-end across proof assistants and output languages including Rust.

The attraction is extreme:

```text
formal source program/specification
       │
       ├─ verified transformations
       ├─ typed erasure/lowering
       ▼
generated Rust
```

This can approach **I5** because the source is not merely an API schema—it contains executable semantics.

### Crucial limitation

Formal extraction does **not** mean every final backend/printer/toolchain step is automatically verified end to end. Verification boundaries differ by project/version. Generated Rust still passes through Rust compilation, and a complete machine-code theorem requires a much larger trusted/verified chain.

Nevertheless, this is the strongest conceptual route to:

> “the declarative/formal contract is the application, and implementation is generated.”

# M — mathematical optimization contracts

## Optimization Engine (OpEn)

Optimization Engine is a domain-specific but instructive example:

```text
mathematical optimization problem
     -> generated high-performance Rust optimizer module
```

This is an I4-style generator inside numerical optimization.

It shows why **domain-specific contracts beat general code synthesis**: once objective, constraints, variables, and solver structure are machine-readable, implementation generation can be both aggressive and reliable.

# N — code generation from the Rust type system itself

The following do not use an external schema, but they belong in the broader contract-generation architecture:

- `serde` derives — type declarations become serialization implementations;
- `thiserror` — enum contract becomes `Error`/Display/source boilerplate;
- `strum` — enum contract becomes iteration/parsing/display functionality;
- `derive_builder` / `bon` — type/function signatures generate builders;
- ORM derives — data model generates persistence glue;
- `cbindgen` — Rust declarations generate C/C++ headers (**reverse direction**).

These demonstrate that Rust macros are already a powerful **internal contract language**.

# What actually generates “business logic”?

This is the decisive question.

## Usually not generated

OpenAPI/Protobuf/Thrift/GraphQL can tell the generator:

```text
POST /orders
Request = CreateOrder
Response = Order
Errors = ...
```

They generally cannot tell it:

```text
reserve inventory iff stock remains
charge exactly once
commit inventory and payment atomically
compensate reservation after payment timeout
enforce customer credit policy
```

Therefore the generated server cannot know the correct implementation.

## Contracts that can generate deeper behavior

To generate business logic, a machine-readable contract must express more semantics, for example:

- state machines;
- preconditions/postconditions;
- invariants;
- authorization policy;
- transactional effects;
- idempotency rules;
- retry/timeout semantics;
- temporal constraints;
- dataflow;
- optimization objective;
- executable functional definitions;
- proofs.

That points toward a **stacked-contract architecture**.

# The most powerful architecture found across the ecosystem

Instead of one giant schema, combine contract layers:

```text
API contract
  Smithy / Protobuf / OpenAPI / WIT
        │
data contract
  JSON Schema / SQL / ASN.1
        │
behavior contract
  state machine / session protocol / rules
        │
resilience contract
  retries / idempotency / durability / compensation
        │
security contract
  authn/authz/capability policies
        │
formal invariants
  pre/postconditions / temporal properties / proof terms
        │
deployment contract
  resources / topology / configuration
        │
        ▼
metagenerator
        │
        ├─ Rust types
        ├─ clients
        ├─ server transport
        ├─ state-machine implementation
        ├─ persistence code
        ├─ resilience wrappers
        ├─ tests/model checks
        └─ proof obligations/evidence
```

This is substantially closer to “contract → production implementation” than asking OpenAPI alone to invent semantics it never contained.

# Production-readiness by contract family

| Contract family | Rust maturity | Generated depth | Best examples |
|---|---|---|---|
| Protobuf/gRPC | **Very high** | I2–I3 | Prost + Tonic |
| Smithy | **Very high** | I2–I3 | smithy-rs / AWS SDK Rust |
| OpenAPI | **High overall; backend-specific** | I1–I3 | OpenAPI Generator, Progenitor |
| JSON Schema | High | I1 | Typify |
| Cap’n Proto | High | I2–I3 | capnproto-rust |
| Thrift | High | I2–I3 | Apache Thrift Rust |
| FlatBuffers | High | I1–I2 | FlatBuffers Rust |
| WIT/Component Model | Rapidly maturing | I2–I3 | wit-bindgen, cargo-component |
| Windows metadata | **Very high** | I1–I2 | windows-rs |
| C/C++ headers | **Very high for raw FFI** | I1–I2 | bindgen, Crubit |
| SQL/Postgres queries | High | I2/I4-domain | Cornucopia |
| GraphQL schema/query | High | I1–I2 | graphql-client |
| ASN.1 | Niche but serious | I1–I2 | rasn |
| Declarative UI | **High** | **I4-domain** | Slint |
| State/session protocols | Mixed/research | I2–I4 | typestate/MPST/SCXML families |
| AsyncAPI→Rust app | Low/emerging | I2–I3 experiments | Crustagen-like work |
| Formal proof→Rust | Research / rapidly advancing | **I4–I5 potential** | MetaRocq/Peregrine extraction |
| Math optimization DSL→Rust | Domain mature | I4-domain | OpEn |

# Best projects by exact interpretation

## “My contract is an HTTP API; generate Rust client/server infrastructure”

- **OpenAPI Generator**
- **Progenitor** for Rust clients
- Smithy if you control the model and can choose a richer IDL

## “My contract is RPC/messages”

- **Tonic + Prost**
- **Cap’n Proto**
- **Thrift**
- FlatBuffers for data-plane schemas

## “My contract is a language-neutral component ABI”

- **WIT + wit-bindgen**

## “My contract is database queries”

- **Cornucopia**

## “My contract is a full declarative UI”

- **Slint**

## “My contract is a formally specified executable program”

- **MetaRocq/Peregrine-style extraction** is the highest-ambition direction, but research-grade compared with Smithy/Tonic.

# Relation to the other four reports

This category is the most promising way to *solve* the gaps in reports 2–4.

Instead of:

```text
arbitrary Rust -> infer what the author meant -> rewrite safely
```

use:

```text
explicit contract -> generate the Rust implementation
```

Then optimization, compactness, and resilience can be encoded as **generator properties**:

- generate terse code by construction;
- generate fault-tolerance wrappers by contract;
- generate efficient layouts/algorithms for known domains;
- regenerate consistently after contract changes;
- verify the generator once rather than manually maintain thousands of boilerplate sites.

That is exactly why IDLs, UI DSLs, query generators, and proof extraction are architecturally important beyond their immediate domains.

# Bottom line

The Rust ecosystem is already strong at **contract-driven implementation**, but the strongest production systems deliberately operate within bounded semantic domains.

The frontier is to compose those domains:

```text
interface + data + behavior + resilience + invariants
```

and make the combination the real application source of truth.

If the goal is to minimize handwritten Rust while increasing correctness, **this direction is more mature and fundamentally safer than trying to reverse-engineer arbitrary existing Rust into a better implementation after the fact.**

## Additional contract families and code-generation systems

The paired report broadens the contract survey beyond the API/UI/formal-extraction families already covered above.

### FIDL, UniFFI, CXX, web-sys, and OS/component interfaces

- **FIDL** turns Fuchsia protocol definitions into Rust crates, message types, proxies, and server-side protocol interfaces. It is valuable because an OS protocol contract defines interaction boundaries, not just record layouts.
- **UniFFI** generates Rust scaffolding and foreign-language bindings from UDL or a Rust-declared object model; its production use in Mozilla makes it a strong boundary-generation case.
- **CXX** generates checked Rust/C++ bridge code from a small interface declaration and is especially useful for studying where unsafe glue should live.
- **web-sys / wasm-bindgen** mechanically generate a very large Rust browser API surface from WebIDL. The target is deliberately platform-faithful rather than maximally idiomatic, which is a useful counterexample when defining “good generated Rust.”
- **zbus_xmlgen** and the **Wayland scanner** turn D-Bus/Wayland interface metadata into Rust proxy/protocol code.

### Additional data/schema generators

| Project | Input | Output / significance |
|---|---|---|
| **quicktype** | JSON / JSON Schema / GraphQL / TypeScript etc. | Broad model generation and schema inference across languages including Rust. |
| **json_typegen** | Sample JSON | Rust structs/enums for data ingestion. |
| **rsgen-avro** | Avro schema | Serde-compatible Rust types; specialized but useful for schema-family completeness. |
| **Cynic** | GraphQL schema + Rust declarations | Typed GraphQL query/schema mapping with generated schema support. |

### Additional database/codegen systems

- **Diesel `print-schema`**: live database schema → Rust `table!` declarations.
- **SQLx macros**: SQL plus database metadata → compile-time checked query code. This is not usually a persistent external-source generator, but it is an important contract-checked implementation mechanism.
- **SeaORM CLI/codegen**: database schema → entity modules; newer dense/compact generation modes are relevant to source-concision research.

### Kubernetes/cloud schemas

- **kopium**: Kubernetes CRD/OpenAPI schemas → Rust structs / `CustomResource`-style definitions.
- **k8s-openapi**: generated Rust API bindings from Kubernetes OpenAPI descriptions.

These are useful for studying versioned schema maintenance, generated API churn, compatibility policy, and very large contract surfaces.

### Hardware/register contracts

- **svd2rust**: CMSIS-SVD → type-safe peripheral access APIs.
- **Embassy chiptool**: SVD plus transformation metadata/YAML register descriptions → PAC source used by Embassy device families.

`chiptool` is especially relevant because it inserts an explicit **transformation stage** instead of treating vendor input as immutable truth.

### Parser/language contracts

| Project | Contract | Generated engine |
|---|---|---|
| **LALRPOP** | LR grammar DSL | Rust parser implementation |
| **pest** | PEG grammar | Parser structures/logic |
| **grmtools** | Lexer + grammar specs | Lexer/parser with error recovery |
| **Logos** | Token enum annotations | High-performance lexer implementation |

These systems are important because they synthesize executable engines from declarative language contracts rather than only types or stubs.

### State-machine behavior generation

- **smlang**: compact state-machine DSL → state/event machine implementation.
- **statig**: annotated state handlers → generated state/superstate hierarchy machinery.

These are narrow, but they cross the line from schema generation into behavioral implementation.

### Contract completeness and ranking caveat

The paired report used a tier ranking; the longer report used an `I0–I5` implementation-completeness scale. The canonical collection retains the **I0–I5 scale** because it is more explicit:

- `I0`: validation/docs only
- `I1`: data types/declarations
- `I2`: bindings/serializers/clients
- `I3`: server/runtime plumbing + handler interfaces
- `I4`: executable domain implementation with most logic supplied declaratively
- `I5`: near-complete program extracted from an executable/formal specification

When the report says a generator is “deep,” it should name the `I` level and the semantic domain instead of relying on an unexplained S/A/B tier.

## Primary sources

- Smithy-rs — https://github.com/smithy-lang/smithy-rs
- AWS SDK for Rust — https://github.com/awslabs/aws-sdk-rust
- OpenAPI Generator — https://github.com/OpenAPITools/openapi-generator
- Progenitor — https://github.com/oxidecomputer/progenitor
- Typify — https://github.com/oxidecomputer/typify
- Tonic / grpc-rust — https://github.com/grpc/grpc-rust
- Prost — https://github.com/tokio-rs/prost
- Cap’n Proto Rust — https://github.com/capnproto/capnproto-rust
- Apache Thrift — https://github.com/apache/thrift
- FlatBuffers — https://github.com/google/flatbuffers
- wit-bindgen — https://github.com/bytecodealliance/wit-bindgen
- windows-rs — https://github.com/microsoft/windows-rs
- rust-bindgen — https://github.com/rust-lang/rust-bindgen
- Crubit — https://github.com/google/crubit
- autocxx — https://github.com/google/autocxx
- Cornucopia — https://github.com/cornucopia-rs/cornucopia
- graphql-client — https://github.com/graphql-rust/graphql-client
- rasn — https://github.com/librasn/rasn
- Slint — https://github.com/slint-ui/slint
- MetaRocq — https://github.com/MetaRocq/metarocq
- Peregrine organization — https://github.com/peregrine-project

### Additional primary sources retained from the paired report

- https://diesel.rs/guides/schema-in-depth.html
- https://docs.rs/cynic/
- https://docs.rs/svd2rust/
- https://fuchsia.googlesource.com/fuchsia/+/refs/heads/main/docs/reference/fidl/bindings/rust-bindings.md
- https://github.com/OpenAPITools/openapi-generator/blob/master/docs/generators/rust-server.md
- https://github.com/SeaQL/sea-orm
- https://github.com/dbus2/zbus
- https://github.com/embassy-rs/chiptool
- https://github.com/korken89/smlang-rs
- https://github.com/lalrpop/lalrpop
- https://github.com/mdeloof/statig
- https://github.com/mozilla/uniffi-rs
- https://github.com/pest-parser/pest
- https://github.com/softdevteam/grmtools
- https://wasm-bindgen.github.io/wasm-bindgen/contributing/web-sys/
