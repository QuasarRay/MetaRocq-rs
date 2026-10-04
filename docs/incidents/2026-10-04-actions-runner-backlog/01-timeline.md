# Incident timeline

All timestamps are UTC on 2026-10-04.

- **03:50** — HOL4/OpenTheory PCUIC PR workflows entered the hosted-runner queue.
- **04:21–04:28** — HOL4→PCUIC generation produced repeated queued/pending generations as the branch advanced.
- **05:05** — Selfhost-1 OpenTheory/Candle workflows queued.
- **05:09–05:17** — Selfhost-2 snapshot/OpenTheory workflows queued; newer generations became pending behind older branch-concurrency occupants.
- **05:20–05:36** — Selfhost-3 CakeML workflow accumulated multiple superseded runs; the oldest queued run retained the branch concurrency slot.
- **05:34–06:01** — retained-runtime workflows showed the same queued-oldest / pending-newest pattern.
- **05:42** — single-image contract jobs queued.
- **05:48** — MetaRocq-owned CI bootstrap queued.
- **06:03** — PCUIC/HOL deep-embedding bridge queued.
- **06:11** — Candle-prefix shared-image workflow queued.
- **06:18** — validated CakeML candidate workflow queued.
- **06:26** — checked CakeML-fragment workflow queued.
- **06:35** — reconciled PCUIC-certificate Selfhost-8 workflow queued.
- **Recovery attempt** — Selfhost-7 was moved from `ubuntu-24.04` to `ubuntu-22.04` and given latest-commit-wins concurrency. The new run also queued immediately.
- **Latest recovery target** — the same queue-safety policy was applied to Selfhost-8. Its replacement run also queued immediately.

This ruled out an Ubuntu-24.04-image-specific shortage and strengthened the diagnosis of an account/repository-level hosted-runner backlog.
