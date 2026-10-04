# Dagger integration specialization

- Dagger is the hermetic execution/orchestration layer for repeatable build and supervision checks; it is not a proof checker and cannot satisfy a mathematical proof gate by itself.
- Pin the Dagger CLI/SDK revision in `gitlab/runtime.lock.json`. Avoid floating container/tool versions in evidence-producing pipelines.
- Reuse the same Dagger entrypoints from GitLab CI and local development so CI logic is not duplicated across runners.
- Keep default checks cheap and deterministic. Large source-materialization or transpiler experiments must be explicit/manual unless their recurring benefit exceeds their compute and maintenance cost.
- Preserve the single-agent/sequential Aegis execution policy; Dagger may parallelize independent build mechanics only when that does not create parallel agent reasoning or conflicting writes.
