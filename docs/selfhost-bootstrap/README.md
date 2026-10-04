# Self-Reflective MetaRocq Bootstrap Manual

This collection is the laptop-executable roadmap for turning the current self-reflective MetaRocq branch into a **fail-closed E2E proof chain** in which HOL4 independently checks the complete proof/replay state and the exact final CakeML-generated machine image is related back to the exact MetaRocq source/specification.

## Execute in order

1. `01-trust-and-e2e-completion-criteria.md` — freeze the final theorem, scope, TCB, and failure policy.
2. `02-laptop-pinned-toolchain.md` — reproduce the pinned MetaRocq, Peregrine, HOL4, and CakeML toolchain on CachyOS.
3. `03-capture-complete-source-and-proof-corpus.md` — materialize the exact source snapshot, complete proof corpus, and assumption ledger.
4. `04-self-reflection-and-lambdabox-retention.md` — make source/proof replay state survive self-reflection and erasure.
5. `05-erasure-correctness-and-assumption-closure.md` — bind MetaRocq erasure to the retained executable state and close/record assumptions.
6. `06-peregrine-cakeml-backend.md` — integrate the exact Peregrine CakeML backend and prove the used LambdaBox→CakeML fragment.
7. `07-hol4-independent-replay-kernel.md` — make HOL4 the independent build-time proof authority for the complete replay.
8. `08-cakeml-in-logic-machine-compilation.md` — compile the exact CakeML program inside HOL4 and bind the theorem to exact machine bytes.
9. `09-unified-e2e-hol4-theorem.md` — compose source proof validity, extraction, Peregrine, CakeML, and machine semantics into one theorem graph.
10. `10-recursive-machine-self-replay.md` — make the final machine image replay its own retained certificate state.
11. `11-local-operation-debugging-and-recovery.md` — run, inspect, cache, bisect, and recover the pipeline locally without weakening gates.
12. `12-final-audit-and-publication-gate.md` — perform the final assumption/oracle/completeness/reproducibility audit.

## Non-negotiable rule

Rocq, MetaRocq, Peregrine, shell scripts, JSON evidence, CI results, and the standalone CakeML executable may produce inputs and evidence, but **none of them authorizes the final E2E claim merely by succeeding**.

The publication result must be an actual HOL4-kernel-checked theorem (or small explicitly composed theorem set) bound to the exact source snapshot, complete proof corpus, extraction artifact, CakeML program, target configuration, and machine image.

## Baseline

This manual was started from:

```text
repository: QuasarRay/MetaRocq-rs
branch: experiment/original-metarocq-selfhost-08-pcuic-certificate-reconciled
commit: 85e161cf735423130049905816de0980ee45256c
```

Do not discard later progress by resetting a newer branch to this commit. Treat this as the documentation baseline and reconcile forward.

## References

### MetaRocq
- https://github.com/MetaRocq/metarocq/blob/9.1/README.md
- https://github.com/MetaRocq/metarocq/blob/9.1/INSTALL.md

### CakeML
- https://github.com/CakeML/cakeml
- https://cakeml.org/jfp19.pdf

### HOL4
- https://hol-theorem-prover.org/docs/trindemossen-2/
- https://hol-theorem-prover.org/docs/trindemossen-2/Developers/
