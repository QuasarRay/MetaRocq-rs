# Unified Peregrine -> MetaRocq Machine-Verification Manual

This directory is the SINGLE SEQUENTIAL instruction path that merges the two previously separate manuals:

1. formally verify Peregrine, its retained proof-replay state, its LambdaBox -> CakeML bridge, and its exact CakeML-generated machine code;
2. then use that verified Peregrine/CakeML/HOL4 boundary to prove that the exact CakeML-generated MetaRocq machine image refines the complete in-scope MetaRocq source/specification/proof corpus E2E.

## Non-negotiable dependency

Do NOT begin the MetaRocq proof-composition phase by merely assuming that Peregrine is trustworthy.

Part I MUST first produce an exact, kernel-checked Peregrine machine-code theorem and independently replayable proof/certificate state. Part II may reuse that theorem, exact source identities, and exact transformation theorem; it MUST NOT silently replace them with native-process success, CI success, an admitted Peregrine backend obligation, `trust_coq_kernel`, or an unhashed executable.

## Execute in this order

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

### PART II — Prove MetaRocq source/specifications -> exact CakeML-generated machine code

Steps 11–22 are added by the next stacked branch.

```text
PEREGRINE MACHINE THEOREM + VERIFIED LAMBDABOX->CAKEML BRIDGE
                         |
                         v
COMPLETE METAROCQ SOURCE / PROOF / SPECIFICATION CORPUS
                         |
                         v
METAROCQ SELF-REFLECTION + VERIFIED ERASURE
                         |
                         v
VERIFIED PEREGRINE BRIDGE
                         |
                         v
EXACT CAKEML PROGRAM
                         |
                         v
HOL4 THEOREM-PRODUCING CAKEML COMPILATION
                         |
                         v
EXACT METAROCQ MACHINE IMAGE
                         |
                         v
ONE COMPOSED HOL4 E2E REFINEMENT THEOREM
```

## Current documentation status

```text
PART_I_REORGANIZATION = COMPLETE ON THIS BRANCH
PART_II_UNIFICATION   = NEXT STACKED BRANCH
FORMAL_PROOFS         = NOT CLAIMED COMPLETE BY DOCUMENTATION ALONE
```
