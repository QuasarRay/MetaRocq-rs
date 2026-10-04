# Incident timeline

All timestamps are UTC on 2026-10-04.

- 03:50 — HOL4/OpenTheory PCUIC PR workflows entered the hosted-runner queue.
- 04:21–04:28 — HOL4→PCUIC generation accumulated queued/pending generations.
- 05:05 — Selfhost-1 OpenTheory/Candle workflows queued.
- 05:09–05:17 — Selfhost-2 snapshot/OpenTheory workflows queued.
- 05:20–05:36 — Selfhost-3 CakeML accumulated superseded generations while an older run retained the branch concurrency slot.
- 05:34–06:01 — retained-runtime workflow showed the same queued-oldest / pending-newest pattern.
- 05:42 — single-image contract jobs queued.
- 05:48 — MetaRocq-owned CI bootstrap queued.
- 06:03 — PCUIC/HOL certificate bridge queued.
- 06:11 — Candle-prefix shared-image workflow queued.
- 06:18 — validated CakeML candidate queued.
- 06:26 — checked CakeML-fragment workflow queued.
- 06:35 — reconciled PCUIC-certificate Selfhost-8 workflow queued.
- Recovery attempt — Selfhost-7 moved to ubuntu-22.04 and latest-commit-wins concurrency; replacement still queued.
- Latest recovery target — Selfhost-8 received the same recovery policy; replacement still queued.

The alternate image result rules out an Ubuntu-24.04-only shortage.
