# Unified Peregrine -> MetaRocq Machine-Verification Manual

This directory is the SINGLE SEQUENTIAL instruction path that merges the two previously separate manuals:

1. formally verify Peregrine, its retained proof-replay state, its LambdaBox -> CakeML bridge, and its exact CakeML-generated machine code;
2. then use that verified Peregrine/CakeML/HOL4 boundary to prove that the exact CakeML-generated MetaRocq machine image refines the complete in-scope MetaRocq source/specification/proof corpus E2E.

## Non-negotiable dependency

Do NOT begin the MetaRocq proof-composition phase by merely assuming that Peregrine is trustworthy.

Part I MUST first produce an exact, kernel-checked Peregrine machine-code theorem and independently replayable proof/certificate state. Part II may reuse that theorem, exact source identities, and exact transformation theorem; it MUST NOT silently replace them with native-process success, CI success, an admitted Peregrine backend obligation, `trust_coq_kernel`, or an unhashed executable.

## Execute in this exact order

### PART I — Formally verify Peregrine down to exact machine code

1. `01-peregrine-freeze-reuse-map-and-e2e-target.md`
2. `02-peregrine-clone-pin-and-audit.md`
3. `03-peregrine-build-selfhost-lambdabox-and-proof-replay-corpus.md`
4. `04-peregrine-bootstrap-with-prebuilt-metarocq-seed.md`
5. `05-peregrine-use-prebuilt-peregrine-to-produce-cakeml.md`
6. `06-peregrine-close-lambdabox-to-cakeml-proof-gap.md`
7. `07-peregrine-prove-exact-cakeml-machine-code-in-hol4.md`
8. `08-peregrine-embed-non-circular-proof-capsule.md`
9. `09-peregrine-revalidate-with-fresh-independent-hol4.md`
10. `10-peregrine-run-e2e-and-pass-publication-gate.md`

### PART II — Prove complete MetaRocq source/specifications -> exact CakeML-generated machine code

11. `11-metarocq-freeze-trust-and-e2e-completion-criteria.md`
12. `12-metarocq-reproduce-pinned-toolchain.md`
13. `13-metarocq-capture-complete-source-specification-and-proof-corpus.md`
14. `14-metarocq-self-reflection-and-lambdabox-retention.md`
15. `15-metarocq-prove-erasure-correctness-and-assumption-closure.md`
16. `16-metarocq-reuse-verified-peregrine-to-cakeml-bridge.md`
17. `17-metarocq-replay-complete-proof-corpus-in-hol4.md`
18. `18-metarocq-compile-exact-cakeml-program-inside-hol4.md`
19. `19-metarocq-compose-unified-source-to-machine-hol4-theorem.md`
20. `20-metarocq-prove-recursive-machine-self-replay.md`
21. `21-metarocq-local-operation-debugging-and-recovery.md`
22. `22-metarocq-final-audit-and-publication-gate.md`

### FINAL REPORT

23. `23-unified-reuse-provenance-and-open-proof-obligations.md`

## The exact handoff

```text
STEPS 01–10
PEREGRINE SOURCE + PROOF REPLAY
        -> VERIFIED LAMBDABOX->CAKEML
        -> EXACT CAKEML
        -> HOL4
        -> EXACT PEREGRINE MACHINE THEOREM
                     |
                     v
STEP 16 REUSES THE PROVED BRIDGE, NOT AN ASSUMPTION
                     |
                     v
STEPS 11–22
COMPLETE METAROCQ SOURCE/SPEC/PROOF CORPUS
        -> PCUIC REPLAY + VERIFIED ERASURE
        -> VERIFIED PEREGRINE BRIDGE
        -> EXACT METAROCQ CAKEML
        -> HOL4 CAKEML COMPILATION
        -> EXACT METAROCQ MACHINE IMAGE
        -> ONE E2E REFINEMENT THEOREM
```

## Status

```text
UNIFIED_INSTRUCTION_COLLECTION = COMPLETE
SOURCE_MANUALS                 = PRESERVED
FORMAL_IMPLEMENTATION          = NOT CLAIMED COMPLETE
PUBLICATION                    = FAIL-CLOSED UNTIL THEOREMS ARE KERNEL-CHECKED
```

## Branch stack

```text
docs/peregrine-selfhost-03-independent-replay
  -> docs/unified-e2e-01-peregrine
  -> docs/unified-e2e-02-metarocq
```
