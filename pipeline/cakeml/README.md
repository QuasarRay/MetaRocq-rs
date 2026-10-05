# Unified E2E CakeML control plane

`UnifiedE2E.cml` is the authoritative ordered state machine for the uploaded
23-step Peregrine -> MetaRocq E2E manual. It does **not** weaken any proof gate.
Each emitted command delegates only the host-process primitive to a shell
adapter; the ordering, phase split and mandatory step set are encoded in
CakeML.

The host split is intentional. The ordinary verified CakeML basis used for this
pipeline does not expose a generic POSIX process-spawn API. Treating shell
execution as a small explicit boundary is preferable to pretending that
external Rocq, HOL4, Git and Peregrine processes are pure CakeML operations.
Every proof-producing stage remains fail-closed, and the final formal claims are
still authorized only by the required Rocq/HOL4 theorem objects.

Compile the source with a bootstrapped CakeML compiler, then provide the resulting
executable as `UNIFIED_E2E_CAKEML_BIN`. The final README documents the CachyOS
installation path. The orchestration entry point is:

```sh
UNIFIED_E2E_CAKEML_BIN=/path/to/unified-e2e \
  ./tools/unified-cakeml-e2e.sh prove
```

`plan`, `peregrine`, `metarocq`, and `step NN` are also supported by the CakeML
program. `prove` always emits all 23 instructions in exact numeric order.

## Formal status

The control plane is implemented. It does not fabricate missing formal work.
If `PeregrineCakeMLPipelineCorrect`, complete HOL4 proof replay, capsule
correspondence, the final Peregrine E2E theorem, or the final MetaRocq E2E theorem
is absent, the corresponding host stage exits non-zero and publication remains
`BLOCKED`.
