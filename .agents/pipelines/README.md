# Sequential bootstrap controller

Deploy the pinned Aegis Git tree to `MetaRocq-rs/.agents`. Keep `database/` (storage
code), `data/` (event contents), `roadmaps/` (runtime DAG) and `pipelines/` (execution)
separate. Existing extraction, HOL4, Kani and artifact-inspection modules are retained.

```sh
python3 -m pip install -r .agents/database/requirements.txt
python3 -B .agents/pipelines/bootstrap.py --root . validate
# AEGIS_DATABASE_DSN is supplied privately by the supervisor for this task login.
python3 -B .agents/pipelines/bootstrap.py --root . run --task source-audit
```

The source-audit command is currently the only runnable task. The remaining formal
obligations have null commands, including independent original checker qualification,
untyped proof retention, CakeML machine refinement, the Rust-aware shared specification
and metatheory equivalence. They stay BLOCKED. No receipt flag or successful process
can mark a proof task complete. There is no bypass or manual mark-complete command.
The required independent proof-replay and provider-authenticated worker adapters are
not implemented yet; this checkpoint is not a production-ready autonomous prover.

The controller rereads the runtime DAG, validates dependencies and implementation
gating, and binds observations to the complete roadmap, declared input bytes, runtime
code and upstream task identities. Failed/interrupted unchanged attempts are not
silently retried. Process completion is called OBSERVED and never proves a theorem.
One PostgreSQL advisory lock excludes concurrent workers across hosts using this DB.
Standalone deterministic programs need no model. Future formalization/roadmap workers
must be dispatched with GPT-6 Astra and max effort, authenticated by the provider;
configuration strings alone cannot establish those facts. No such worker is dispatched
until that adapter is implemented. Implementation remains gated by metatheory replay.

Every capture exports its logical database write. Before and after running a task,
the publisher stages only data, declared outputs and generated instruction files,
commits using fixed code-generated text, pushes without force, and verifies the exact
remote branch SHA. Failed persistence or publication blocks advancement. A DB commit
and Git push cannot be one atomic transaction: recovery re-exports/retries and does
not pretend the network cannot fail. Commit source changes separately before running.
Use task-scoped `recover` to retry pending events and publication after a failure.

Maximum efficiency is not a verifiable global property. This controller avoids model
calls for logging, unchanged retries, parallel agents and speculative implementation.
It does not assert that every possible optimization has been achieved.
