# Astra architecture review packet

This file intentionally contains only the semantic delta required to review the GitLab/Aegis architecture.

## Read first

1. `AGENTS.md`
2. ADR 0009 — one pinned GitLab CE Rails runtime.
3. ADR 0010 — Rails stays Ruby; Rust only behind justified narrow boundaries.
4. ADR 0011 — GitHub integration is deep but optional; self-hosted GitLab remains authoritative.
5. ADR 0012 — prefer native Rails/GitLab metaprogramming and require expansion metadata.
6. `gitlab/runtime.lock.json`
7. `research/ruby-metaprogramming/registry.json`

Do **not** begin by rereading all overlay source.

## Architecture in one screen

```text
MetaRocq-rs machine-readable roadmap/spec
                 |
                 v
        Aegis control plane
        /       |        \
   GitLab     Dagger    proof/replay
 Rails+MCP   execution  HOL4/Rocq/Kani
    |
    +-- supervision UI generated from committed evidence
    |
    +-- optional GitHub bridge -> GitHub website/API/Actions
```

GitLab CE/FOSS is the only Rails app. GitHub may disappear without disabling local Aegis. Dagger success is process evidence. Formal acceptance remains behind independent replay and `metatheory-verified`.

## Metaprogramming rule

Prefer existing GitLab/Rails DSLs because they maximize behavior density without adding a new review language. Any new Aegis DSL must emit an expansion index so review can operate on **specification + expansion**, not hidden `define_method` behavior.

## What Astra needs to decide

- whether any of ADRs 0009–0012 conflicts with the formalization roadmap;
- whether a proposed external DSL replaces enough duplicated semantics to justify its review cost;
- whether generated expansion metadata is sufficient for independent supervision;
- whether GitHub remains removable without changing the local trust/availability chain.

Everything else is implementation detail unless tests or one of these invariants fail.
