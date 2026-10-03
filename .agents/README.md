# MetaRocq bootstrap supervision

The sequential controller, append-only PostgreSQL event store and automatic Markdown
journal are implemented in `pipelines/` and `database/`. The runtime roadmap is
`roadmaps/metarocq-bootstrap.json`. Deploy the exact committed tree to the target
`.agents` using `scripts/deploy_metarocq.py`. See `pipelines/README.md` and
`docs/architecture/0008-automatic-persistence.md`.

**The metatheory bootstrap is not complete. Qualified semantic replay and provider-
authenticated agent dispatch remain blocked; the full architecture is not production-ready.**
Logging performs no model calls or agent-written summarization. Private internal
reasoning is not accessible. Existing extraction and verifier work is preserved below.

# Aegis for MetaRocq-rs

This branch adapts the HOL4/MCP/TacticToe stack to the attached MetaRocq-rs goals.
The application contract is the original pinned Rocq source. Candidate Rust comes
from Peregrine typed extraction; generation alone is not a correctness proof.

Read `contracts/authority.json`, `contracts/project-goals.md` and
`docs/architecture/0002-metarocq-bootstrap.md`. Earlier Candle architecture/audit
documents describe the inherited baseline, not completed MetaRocq verification.

Python 3.11+ and Git run the controller. Install proof/extraction tools only for the
selected obligation. The existing work cycle freezes a contract and reuse decision,
checks exact upstream commits/bytes and records scoped Kani/Verus observations.
`extract` runs the documented Rocq/Peregrine commands in a temporary directory and
publishes outputs only after both steps succeed. Missing tools are BLOCKED.

```sh
python bin/agentctl.py --root /work/MetaRocq-rs freeze .metarocq/plan.json --metarocq /refs/metarocq --peregrine /refs/peregrine
python bin/agentctl.py --root /work/MetaRocq-rs extract --timeout 600
python bin/agentctl.py --root /work/MetaRocq-rs verify --timeout 120
# Commit, push and create the PR through GitHub, then record its exact head:
python bin/agentctl.py --root /work/MetaRocq-rs checkpoint --pr 1
```

The extraction driver location is `extraction/Bootstrap.v`; it must emit `candidate.ast`.
The outputs are `generated/pcuic_isapp.ast` and `generated/pcuic_isapp.rs`. This first
slice is deliberately bounded; it is not a complete checker or macro implementation.
The target's bootstrap wrapper binds these paths and preserves source/tool identities.

`python scripts/selftest.py` checks the controller, not mathematical equivalence.
`python scripts/generate.py --check` checks full per-directory instruction copies.
The runtime prevents another managed cycle until the current PR is preserved, with
open/blocked obligations allowed. It is not an OS sandbox or authenticated proof service.
Tool installation provenance, Rust/HOL4 correspondence, unbounded extraction correctness,
certificate checking and binary verification remain explicit OPEN obligations.
