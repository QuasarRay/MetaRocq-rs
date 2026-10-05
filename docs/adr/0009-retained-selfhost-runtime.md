# ADR 0009: Retain self-reflection through erasure

Status: experimental, fail closed.

## Decision

The Original-MetaRocq self-host variation has one extraction root:
`selfhost_entrypoint`.

The root keeps three categories reachable as ordinary executable data:

1. the complete pinned PCUIC module snapshot materialized by PR #15;
2. the OpenTheory proof-program payload and its publication status;
3. the runtime architecture manifest for MetaRocq, Peregrine, Candle and the
   CakeML compiler.

This is intentional. Proof terms are normally erased. The self-verification
inputs therefore cannot exist only as proofs in `Prop`; they must also be
represented as computational data consumed by the runtime replay path.

## Peregrine is a producer, not a proof root

The pinned Peregrine CakeML backend contains an axiom named
`trust_coq_kernel`. This branch does not use that axiom to establish the
correctness of the generated CakeML program.

Peregrine may generate lambda-box/CakeML artifacts. Acceptance requires the
separate retained proof payload, Candle/OpenTheory acceptance, the verified
CakeML compilation path, and machine-image replay.

## Single-image goal

The final target remains one machine image containing:

- the extracted MetaRocq self-host runner;
- the retained PCUIC/OpenTheory proof payload;
- the Candle/OpenTheory checker;
- the Candle-capable CakeML compiler runtime;
- the executable Peregrine transformation path needed for regeneration.

This PR establishes the MetaRocq-owned retained runtime contract and extraction
root. It does not yet claim that Candle and the compiler have been linked into
that one image.

## Fail-closed rule

`VerifySelf` cannot succeed unless all of the following hold:

- the runtime manifest is coherent;
- the baked snapshot has the pinned module count;
- PCUIC-to-HOL/OpenTheory lowering produced publishable proof articles;
- source identities match;
- Peregrine's trust axiom was not used;
- Candle accepts all articles;
- the CakeML image is on the verified compiler path;
- replay of the machine image matches the retained proof result.

Until the PCUIC-to-HOL/OpenTheory proof lowering is discharged, the retained
payload is explicitly `Unsupported`, so the executable architecture can be
built without misreporting end-to-end proof completion.
