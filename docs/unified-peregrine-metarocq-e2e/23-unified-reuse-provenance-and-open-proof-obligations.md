# 23 — Unified Reuse, Provenance, and Remaining Formal Obligations

## Objective

Record exactly how the TWO existing instruction manuals were merged into ONE sequential manual WITHOUT discarding, silently rewriting, or duplicating their substantive work.

The unified collection is an organizational/compositional layer.

It does NOT mean that the missing formal theorems have already been implemented.

```text
UNIFIED_INSTRUCTION_SEQUENCE = COMPLETE
FORMAL_IMPLEMENTATION        = STILL FAIL-CLOSED UNTIL THEOREMS EXIST
```

## 1. Source manuals preserved unchanged

### Peregrine source manual

```text
branch:
  docs/peregrine-selfhost-03-independent-replay

directory:
  docs/peregrine-selfhost-certificate/

operational source milestones reused:
  00 through 09

reuse/report source:
  10-reuse-versus-new-work-report.md
```

### MetaRocq source manual

```text
branch:
  docs/selfhost-bootstrap-04-runtime-audit

directory:
  docs/selfhost-bootstrap/

operational source milestones reused:
  01 through 12
```

Neither source directory is deleted or replaced.

## 2. Unified sequence mapping

| Unified step | Unified file | Original source |
|---:|---|---|
| 01 | `01-peregrine-freeze-reuse-map-and-e2e-target.md` | Peregrine `00-reuse-map-and-target.md` |
| 02 | `02-peregrine-clone-pin-and-audit.md` | Peregrine `01-clone-pin-and-audit-peregrine.md` |
| 03 | `03-peregrine-build-selfhost-lambdabox-and-proof-replay-corpus.md` | Peregrine `02-build-peregrine-selfhost-lambdabox.md` |
| 04 | `04-peregrine-bootstrap-with-prebuilt-metarocq-seed.md` | Peregrine `03-bootstrap-with-prebuilt-metarocq-seed.md` |
| 05 | `05-peregrine-use-prebuilt-peregrine-to-produce-cakeml.md` | Peregrine `04-prebuilt-peregrine-to-cakeml.md` |
| 06 | `06-peregrine-close-lambdabox-to-cakeml-proof-gap.md` | Peregrine `05-close-peregrine-cakeml-proof-gap.md` |
| 07 | `07-peregrine-prove-exact-cakeml-machine-code-in-hol4.md` | Peregrine `06-cakeml-hol4-exact-machine-attestation.md` |
| 08 | `08-peregrine-embed-non-circular-proof-capsule.md` | Peregrine `07-embed-non-circular-proof-capsule.md` |
| 09 | `09-peregrine-revalidate-with-fresh-independent-hol4.md` | Peregrine `08-future-hol4-independent-revalidation.md` |
| 10 | `10-peregrine-run-e2e-and-pass-publication-gate.md` | Peregrine `09-one-command-e2e-runbook-and-publication-gate.md` |
| 11 | `11-metarocq-freeze-trust-and-e2e-completion-criteria.md` | MetaRocq `01-trust-and-e2e-completion-criteria.md` |
| 12 | `12-metarocq-reproduce-pinned-toolchain.md` | MetaRocq `02-laptop-pinned-toolchain.md` |
| 13 | `13-metarocq-capture-complete-source-specification-and-proof-corpus.md` | MetaRocq `03-capture-complete-source-and-proof-corpus.md` |
| 14 | `14-metarocq-self-reflection-and-lambdabox-retention.md` | MetaRocq `04-self-reflection-and-lambdabox-retention.md` |
| 15 | `15-metarocq-prove-erasure-correctness-and-assumption-closure.md` | MetaRocq `05-erasure-correctness-and-assumption-closure.md` |
| 16 | `16-metarocq-reuse-verified-peregrine-to-cakeml-bridge.md` | MetaRocq `06-peregrine-cakeml-backend.md` |
| 17 | `17-metarocq-replay-complete-proof-corpus-in-hol4.md` | MetaRocq `07-hol4-independent-replay-kernel.md` |
| 18 | `18-metarocq-compile-exact-cakeml-program-inside-hol4.md` | MetaRocq `08-cakeml-in-logic-machine-compilation.md` |
| 19 | `19-metarocq-compose-unified-source-to-machine-hol4-theorem.md` | MetaRocq `09-unified-e2e-hol4-theorem.md` |
| 20 | `20-metarocq-prove-recursive-machine-self-replay.md` | MetaRocq `10-recursive-machine-self-replay.md` |
| 21 | `21-metarocq-local-operation-debugging-and-recovery.md` | MetaRocq `11-local-operation-debugging-and-recovery.md` |
| 22 | `22-metarocq-final-audit-and-publication-gate.md` | MetaRocq `12-final-audit-and-publication-gate.md` |

## 3. What was actually NEW in the merge

The merge adds ONLY the cross-manual dependency semantics that were previously implicit:

1. Peregrine verification is now ALWAYS first.
2. MetaRocq Step 16 MUST consume the exact theorem-bound Peregrine bridge from Part I.
3. MetaRocq Step 18 MUST compile the SAME CakeML AST proved by Step 16.
4. MetaRocq Step 19 MUST compose the complete source/specification/proof chain through the verified Peregrine bridge and exact CakeML machine theorem.
5. MetaRocq Step 22 MUST re-audit the Part-I Peregrine theorem identity, rather than assuming it remains valid.
6. The final publication claim is ONE connected theorem graph, not two unrelated proof certificates.

## 4. The complete intended theorem chain

```text
PINNED PEREGRINE SOURCE
  + every retained Peregrine proof/replay object
        |
        v
PEREGRINE SELFHOST LAMBDABOX
        |
        v
PROVED PEREGRINE LAMBDABOX -> CAKEML TRANSFORMATION
        |
        v
EXACT PEREGRINE CAKEML PROGRAM
        |
        v
CAKEML THEOREM-PRODUCING COMPILATION IN HOL4
        |
        v
EXACT PEREGRINE MACHINE THEOREM
        |
        +---------------- VERIFIED TRUST FOUNDATION ----------------+
                                                                     |
                                                                     v
PINNED METAROCQ SOURCE + COMPLETE SPECIFICATION/PROOF CORPUS
        |
        v
PCUIC REPLAY + VERIFIED ERASURE + RETAINED LAMBDABOX STATE
        |
        v
THE SAME VERIFIED PEREGRINE LAMBDABOX -> CAKEML BRIDGE
        |
        v
EXACT METAROCQ CAKEML PROGRAM
        |
        v
CAKEML THEOREM-PRODUCING COMPILATION IN HOL4
        |
        v
EXACT METAROCQ MACHINE IMAGE
        |
        v
HOL4 KERNEL-CHECKED E2E REFINEMENT:
machine behavior refines every in-scope MetaRocq specification/proof obligation
```

## 5. Remaining formal obligations

The unified documentation is complete ONLY as an instruction set.

Publication remains BLOCKED until the implementation actually produces kernel-checked artifacts for, at minimum:

```text
PEREGRINE
[ ] complete source/proof snapshot theorem
[ ] complete proof replay theorem
[ ] source -> LambdaBox refinement
[ ] complete LambdaBox -> CakeML theorem
[ ] exact CakeML application semantics
[ ] exact CakeML -> machine theorem
[ ] embedded certificate correspondence
[ ] fresh HOL4 reconstruction

METAROCQ
[ ] complete source/specification/proof inventory theorem
[ ] complete PCUIC replay theorem
[ ] verified erasure + retained replay-state theorem
[ ] exact application of the verified Peregrine bridge
[ ] exact MetaRocq CakeML semantics theorem
[ ] exact in-HOL4 CakeML compilation theorem
[ ] exact machine-byte binding
[ ] one composed source/specification -> machine refinement theorem
[ ] recursive machine replay correspondence
[ ] final assumption/oracle/completeness mutation audit
```

## 6. Stack preservation

```text
existing source stack:
  docs/selfhost-bootstrap-01-foundation
    -> docs/selfhost-bootstrap-02-reflection
    -> docs/selfhost-bootstrap-03-hol4-machine-proof
    -> docs/selfhost-bootstrap-04-runtime-audit
    -> docs/peregrine-selfhost-01-source-bootstrap
    -> docs/peregrine-selfhost-02-cakeml-certificate
    -> docs/peregrine-selfhost-03-independent-replay

new unified stack:
  docs/unified-e2e-01-peregrine
    -> docs/unified-e2e-02-metarocq
```

No source branch is force-moved and no original instruction file is deleted.

## References

### MetaRocq
- https://github.com/MetaRocq/metarocq/blob/9.1/README.md
- https://github.com/MetaRocq/metarocq/blob/9.1/INSTALL.md

### Peregrine
- https://github.com/peregrine-project/peregrine-tool/blob/master/doc/overview.md
- https://github.com/peregrine-project/peregrine-tool/blob/d768b83ffa7dab35b8d72241f0570b5bb6aedae9/theories/Pipeline.v
- https://github.com/peregrine-project/cakeml-backend

### CakeML
- https://github.com/CakeML/cakeml
- https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/cv_translator/eval_cake_compileLib.sig

### HOL4
- https://github.com/HOL-Theorem-Prover/HOL
- https://github.com/HOL-Theorem-Prover/HOL/blob/40dd5b03de658f4bd9e3f4225fb0f1602ac90467/src/opentheory/postbool/OpenTheoryIO.sig
