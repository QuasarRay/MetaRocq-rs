# ADR 0008: Original MetaRocq self-hosting through OpenTheory and Candle

Status: **experimental, fail closed**.

## Context

The project already contains a separate HOL4 -> OpenTheory -> PCUIC migration experiment. This ADR specifies the reverse, self-hosting direction without replacing that work:

```text
Original MetaRocq source + metatheory
          |
          | compile-time quotation
          v
baked PCUIC source/metatheory snapshot
          |
          | MetaRocq-defined proof lowering
          v
OpenTheory article
          |
          | verified CakeML/Candle reader
          v
independently checked HOL theorems
          |
          +-------------------------------+
          |                               |
          v                               v
self-verification evidence       lambda-box extraction
                                          |
                                          | Peregrine
                                          v
                                        CakeML
                                          |
                                          v
                           single self-verifying executable
```

The intended final executable is simultaneously:

1. the extracted MetaRocq metaprogram/runtime needed by this experiment,
2. the holder of the baked Original-MetaRocq/PCUIC snapshot,
3. the producer of the OpenTheory proof article,
4. the orchestrator of Candle verification,
5. and the producer of the final replay/evidence result.

It must not depend on a live Rocq plugin environment after extraction.

## Decision 1: quote before extraction

The self-hosted executable receives a build-time snapshot, not access to the live Rocq environment.

MetaRocq already exposes `tmQuoteModule`, `tmQuoteRec`, and `tmQuoteRecTransp`. The build variation will use these APIs to identify the MetaRocq modules and recursively quote the definitions/theorems that form the self-verification root set.

The result is retained in PCUIC-compatible data and becomes part of the lambda-box program.

## Decision 2: the proof IR is implemented in MetaRocq

The pipeline IR and OpenTheory IR live under `metatheory/original-selfhost/` as Rocq/MetaRocq source.

GitHub Actions, Python and shell are outside the trusted transformation path. They may install exact pins, invoke the extracted binary, compile generated CakeML and archive evidence. They may not choose lemmas, invent proof steps, translate proofs, or decide proof acceptance.

## Decision 3: OpenTheory is a proof format, not an assertion format

A PCUIC theorem may be exported only when its derivation has been lowered into OpenTheory/HOL primitive proof steps.

The exporter must never turn a difficult source theorem into an OpenTheory `axiom` command merely to make the article check.

The lowering API is therefore fail closed. Unsupported source constructs produce `Unsupported`; an article is publishable only when all required proof derivations were lowered.

## Decision 4: Candle verification reuses the verified CakeML OpenTheory reader

The CakeML v3213 source revision already used by the parent branch contains:

- `examples/opentheory/readerScript.sml`, the OpenTheory VM implementation;
- `readerSoundnessScript.sml`, relating accepted theorems to HOL semantics;
- `compilation/proofs/readerProgProofScript.sml`, carrying the checker result through CakeML compilation to machine-code behavior.

This is the independent Candle boundary. The project will generate the existing article format rather than inventing another Candle-specific proof language.

## Decision 5: Peregrine remains the lambda-box -> CakeML backend

The pinned Peregrine revision already contains the CakeML backend and the lambda-box middle end. This branch reuses it rather than writing another code generator.

The final bootstrap is two-level:

```text
G0: pinned Rocq + Original MetaRocq + Peregrine
       |
       +--> quote/build the self-host MetaRocq program
       +--> lambda-box
       +--> CakeML
       +--> G1 executable

G1:
       +--> read its baked PCUIC snapshot
       +--> produce OpenTheory proof article
       +--> require Candle/OpenTheory acceptance
       +--> emit replay/evidence result
```

A future fixed-point stage may require G1 to reproduce its own lambda-box/CakeML bytes. That is a stronger claim than self-verifying its baked mathematical/source contract and is not silently assumed by this ADR.

## Current hard obligation

There is no generic already-qualified compiler that turns the complete MetaRocq/PCUIC proof corpus into native HOL/OpenTheory proofs.

Therefore the central formalization obligation is:

```text
quoted PCUIC derivation
       |
       | verified lowering
       v
HOL/OpenTheory derivation
       |
       | Candle verified reader
       v
HOL semantic theorem
```

The architecture may be implemented before this lowering is complete, but the e2e status remains **BLOCKED** until:

1. every theorem selected for the complete metatheory root set has a generated derivation,
2. the generated article contains no proof holes or source-theorem escape axioms,
3. Candle accepts the exact article bytes,
4. and the lowering itself has a semantics-preservation theorem adequate for the translated fragment.

## Relationship to Rust-native MetaRocq-rs

This branch is intentionally advisory and isolated. It may produce reusable proof IRs or a Rust-native formalization suggestion, but it does not select the canonical Rust-native MetaTheory. That authority remains with GPT-6 Astra according to the project policy.
