# ADR 0009: GitLab CE/FOSS is the Aegis application runtime

## Status

Accepted for the MetaRocq-rs supervision runtime checkpoint.

## Decision

Aegis runs **inside one pinned GitLab CE/FOSS Rails application**. GitLab owns the web process, authentication, sessions, authorization, PostgreSQL integration, routing, views, CI/CD, and MCP transport. Aegis is a fail-closed source overlay plus Dagger entrypoints; it is not another Rails application and does not introduce a parallel web database.

The GitLab host is v19.4.1 at commit `191678a37648bc14466c2bed346ed60eee7ddec6`. Assembly verifies exact blob identities for the route table, MCP base, MCP manager, and custom-service base before modifying a checkout. This reduces upgrade ambiguity and prevents a patch from silently landing against a different GitLab layout.

## Human supervision surface

The initial Rails surface is deliberately read-only. `Aegis::RepositorySnapshot` reads MetaRocq-rs' committed roadmap, task registry, persistence manifest, deployment identity, and project status. The Rails view renders task dependencies, required theorems, recorded process evidence, and blockers. GitLab authorization (`:read_code`) gates both the HTML controller and the MCP tool.

No view or MCP field treats a successful process, content hash, artifact existence, or Dagger result as a formal proof. The `metatheory-verified` gate remains the implementation boundary and can only be opened by the existing qualified independent replay path.

## MCP

GitLab 19.4.1 already contains its official MCP server and tool registry. Aegis registers `aegis_get_supervision_state` in that registry rather than operating a second MCP transport. This reuses GitLab OAuth/scope checks, user identity, tool invocation, and namespace authorization.

## Dagger

Dagger v0.21.10 is pinned. GitLab CI invokes the same `dagger/supervision.py` entrypoint usable locally. The first gate checks overlay structure and Ruby/Python syntax hermetically. More expensive materialization or cross-language experiments are not part of the default path because recurring cost must be justified by supervision value.

## Ruby and Rust

Rails orchestration remains Ruby. Rust is preferred for isolated kernels only when profiling, safety, or formal-contract reuse justifies the FFI boundary. `rb-sys` and Magnus are viable Ruby/Rust extension mechanisms, but adding a native extension without a concrete workload would increase build and GC/FFI risk without improving supervision.

A whole-GitLab Rails-to-Rust conversion is therefore not part of this checkpoint. It is evaluated separately as an optional experiment so a speculative transpiler cannot become part of the trusted or required path.

## Consequences

- There is one web runtime and one authorization model.
- Aegis UI/MCP evolve with a small auditable overlay instead of a GitLab fork copied into this repository.
- GitLab upgrades are explicit because pinned anchors must be requalified.
- Dagger checks are reproducible but remain process evidence only.
- Rust integration remains compatible with the existing Rust/Python Aegis ecosystem without forcing Rails into a second implementation language.
