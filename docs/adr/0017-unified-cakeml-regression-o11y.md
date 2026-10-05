# ADR 0017 — CakeML-owned unified E2E plan with append-only regression traces

## Decision

The unified Peregrine -> MetaRocq sequence is represented by CakeML source, `cakeml/peregrine-selfhost/UnifiedE2EPipeline.cml`. The program emits an ordered 23-stage plan: operational Steps 01–22 plus the always-run Step 23 provenance/open-obligations report. Every stage is bound to the SHA-256 of the exact Markdown instruction copied from the uploaded ZIP.

Host process creation is deliberately outside the semantic proof claim. CI compiles the CakeML plan with CakeML v3479, then executes the generated plan through a worker that directly loads the pinned `CakeML/regression` `utilLib.sml` and follows `worker.sml`'s capture model: status before execution, combined stdout/stderr, `/usr/bin/time` elapsed/max-RSS/exit-code data, explicit failure, and downstream blocking.

Before the real pipeline, the workflow injects a failure independently at every one of the 23 positions in trace-only dry-run mode. This persists a regression trace proving that each failure position produces a `FAILED` stage, complete downstream `SKIPPED` records, and an always-run Step 23 report where applicable.

Each workflow run gets `.o11y/runs/<run-id>-<attempt>-<sha>/`. A final `always()` step commits that directory to the same branch using only fetch/rebase/push. It rejects a pre-existing run key and never force-pushes. Trace-only commits do not retrigger the workflow.

## Trust boundary

The CakeML planner and regression traces automate and supervise the process. Neither CI success nor a trace hash proves semantic correctness. The base implementation still lacks genuine theorems required by the unified manual; those boundaries deliberately fail closed rather than being replaced by process-success claims.

Git cannot make history literally irreversible against a repository administrator who can rewrite refs. The implemented guarantee is therefore the strongest workflow-level append-only policy available here: unique run keys, origin collision checks, no force push, prior-origin-head recording, per-run SHA-256 manifest, and ordinary Git commit/tree identity.

## Consequences

- Existing PR #30 implementation work is reused rather than rewritten.
- The exact uploaded instructions are checked into `docs/unified-peregrine-metarocq-e2e/` and hash-bound by the CakeML plan.
- Expensive producer work is reused when exact cached binaries exist; otherwise the pinned fallback is rebuilt and logged.
- Failure runs preserve completed stage evidence, explicit blocked-stage records, and the independent Step 23 provenance report.
- Concurrent runs append independent trace commits and are reconciled by normal fetch/rebase/push.
