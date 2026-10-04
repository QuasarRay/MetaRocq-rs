# Append-only E2E trace store

Each explicit unified E2E run owns exactly one immutable directory:

```
.o11y/<run-id>/
```

The workflow synchronizes the branch with `origin` before creating the run,
captures preflight/build/controller/stage logs, resource usage and failure
markers, computes per-file SHA-256 digests, then creates a dedicated Git commit
that adds only that run directory.

## Immutability model

The scripts enforce the strongest append-only behavior available to an ordinary
Git branch from inside the repository:

- a run ID may not already exist locally or on `origin`;
- only `A` (added) paths under the new run directory may be committed;
- pushes are non-force;
- old `.o11y` paths are never edited or deleted by the synchronization code;
- each run records the origin commit observed before execution;
- every trace file is covered by `SHA256SUMS`.

A repository administrator can still rewrite or delete Git history.  Absolute
irreversibility therefore requires external repository policy (for example
rulesets that prohibit force-push/deletion, immutable archival storage, or
signed transparency-log replication).  The pipeline does not falsely claim
that mutable Git hosting alone can provide that property.
