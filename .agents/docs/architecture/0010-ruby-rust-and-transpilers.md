# ADR 0010: Ruby/Rust boundary and Rails transpiler evaluation

## Status

Accepted as a cost-control decision for the GitLab/Aegis runtime.

## Evidence inspected

The evaluation is pinned in `gitlab/runtime.lock.json`.

- **Magnus 0.10.0** explicitly supports Ruby extension gems implemented in Rust and calling Ruby from Rust. It provides typed conversions, wrapped Rust objects and CRuby integration through `rb-sys`.
- **rb-sys 0.9.130** provides Rust bindings to CRuby's C API and stable-API fallback machinery.
- **Roundhouse 2026.9.18** is a Rust program that analyzes Rails applications and can emit a standalone Rust/axum project. Its own documentation says the Rust target is validated on the project's blog fixture and only a subset of framework-runtime tests; its deeper Campfire validation is for the Ruby/Spinel lanes. Its documented Rails coverage also contains unsupported or deliberately divergent features.
- **Spinel** is a Ruby AOT compiler that emits optimized C, not idiomatic Rust. Its documented limitations include unsupported dynamic/metaprogramming behavior that is material to a large application such as GitLab.

## Decision

GitLab Rails remains Ruby. Aegis will not transpile GitLab wholesale to Rust as part of the required runtime.

Rust integration is allowed only behind narrow, explicit contracts when one of these conditions is met:

1. profiling shows a material bottleneck;
2. an existing Aegis/MetaRocq Rust component already implements the required semantics and reusing it reduces duplicated logic;
3. a safety- or verification-critical kernel benefits from a Rust implementation that can be independently checked.

For those boundaries, prefer Magnus over handwritten Ruby C-API glue and use rb-sys underneath it. The Ruby/Rust extension must remain optional to booting GitLab unless it has its own fallback and compatibility qualification.

Roundhouse and Spinel remain **optional experimental lanes**. They may be run through Dagger against the assembled GitLab/Aegis tree, but a successful compilation or fixture comparison is not permission to replace the production Rails runtime. Promotion requires all of:

- the exact pinned GitLab/Aegis tree is accepted by the tool;
- relevant GitLab Rails features are covered rather than silently omitted;
- GitLab's own test suites and Aegis supervision tests pass;
- differential HTTP/UI/API behavior is compared against the Ruby Rails runtime;
- MCP, authorization, Sidekiq/background work, repository operations and PostgreSQL semantics are included;
- the resulting maintenance/token cost is lower than retaining Ruby.

## Why this minimizes agent cost

A whole-GitLab transpilation would create a second semantics surface and force agents to debug differences across Rails, the transpiler and generated Rust. The current project goal is supervision of MetaRocq-rs, not a GitLab language migration. Keeping Rails authoritative preserves the mature GitLab behavior while allowing Rust to replace isolated hotspots only when there is measurable benefit.

## Dagger policy

Transpiler experiments are manual/optional Dagger targets. They must never be dependencies of formalization or proof replay. Their artifacts are observations only and cannot satisfy `metatheory-verified`.
