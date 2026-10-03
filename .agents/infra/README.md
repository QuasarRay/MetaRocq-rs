# Control plane

The Python standard-library runtime binds original-source contracts and captures verifier
observations. `contracts.py` validates the plan and original files; `metarocq.py` owns the
small lifecycle; `verifiers.py` constructs Kani/Verus invocations; `checkpoints.py` checks
GitHub PR and commit identity. Every command returns compact JSON.

Aegis's existing atomic, process, security, governance, lock and transaction primitives
are reused. The general policy compiler, TDD lifecycle, performance/idiomaticness packs,
role fan-out, generated historical-law claims, installer and stale distribution mirror
were retired. Git preserves their original source.

Runtime state uses `.aegis/`; durable plan/evidence use `.metarocq/`. Evidence captures the
whole tracked/nonignored source snapshot, framework digest, exact declared obligation
set, verifier executable hashes, version output, command, process result and proof limits.
The runtime serializes its own writes; it does not impose concurrency work on MetaRocq-rs.
