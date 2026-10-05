# ADR 0014: Reconcile PCUIC certificates with the checked CakeML lineage

Status: implemented as a fail-closed reconciliation layer.

## Branch preservation

Two useful Selfhost lines existed:

- the corrected runtime/Candle/CakeML line:
  PR #20 -> #21 -> #22 -> #23;
- the older advisory line:
  PR #17 -> #18 -> #19 -> `07-dual-proof-export`.

The older line is not merged wholesale because it branched before the corrected
#16 checkpoint and would reintroduce duplicate single-image, CI, HOL4-manifest
and CakeML composition machinery.

This layer ports only unique semantic assets.

## Reused from the older line

The following ideas are restored on top of #23:

1. exact PCUIC theorem certificates and a separate source-assumption ledger;
2. a deep HOL embedding obligation schema for PCUIC;
3. the pinned Original-MetaRocq safe-checker contract and explicit premises;
4. certificate replay through a checker/HOL/OpenTheory/Candle bridge;
5. an independent OpenTheory -> Holide -> Lambdapi -> Rocq -> MetaRocq/PCUIC
   round-trip requirement;
6. Candle kernel-controlled export requirements;
7. executable MetaRocq CI acceptance policy;
8. per-certificate dual PCUIC/Candle evidence;
9. reflective dual certification of the recursion machinery itself.

## Deliberately not copied

The stale `HOL4ReuseContract.v`, old single-image contracts and old CI DSL are
not copied.

`HOL4RoundTripIR.v` instead consumes the corrected
`HOL4ReuseManifest.v`.

The current `DualProofLedger.v` is extended rather than replaced.

## Recursive identity correction

The inherited recursive identity gate still depended on
`shared_source_ready`, which in turn depended on the unproved Peregrine CakeML
backend wrapper.

PR #22 bypassed that wrapper by executing the pure candidate compiler and
requiring an independent translation certificate.

This layer therefore binds recursive self-identity to
`validated_gateway_publishable`. It remains false until the real checked
EAst -> CakeML semantics theorem and the rest of the translation certificate
are discharged.

## Erasure preservation

The reconciled extraction root exposes the complete PCUIC certificate corpus,
the assumption ledger and every certificate-replay job as runtime data.

The proof terms are therefore retained intentionally through lambda-box
extraction instead of relying on ordinary `Prop` proof terms that erasure may
remove.

## Current hard boundaries

Publication remains blocked on genuine semantic work:

- faithful PCUIC-as-HOL data/relations;
- checker-encoding faithfulness and checker soundness in HOL;
- source assumption/guard/normalization closure;
- proof-producing OpenTheory reconstruction;
- independent reverse round-trip;
- checked EAst -> CakeML observational preservation;
- Candle safe suffix proof and exact machine-image binding;
- recursive identity replay from the installed image.

No CI exit status or generated artifact substitutes for these theorems.
