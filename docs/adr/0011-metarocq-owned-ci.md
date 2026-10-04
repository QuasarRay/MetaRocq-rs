# ADR 0011: CI/CD policy belongs to the extracted MetaRocq program

Status: experimental, fail closed.

## Decision

The authoritative bootstrap order, acceptance policy, and failure state machine
are executable MetaRocq data/functions.

GitHub Actions is not the proof pipeline. It is a bootstrap host which:

1. installs pinned dependencies;
2. compiles the MetaRocq-defined pipeline;
3. extracts the single lambda-box program;
4. invokes that program and the pinned verified runtime;
5. archives resulting bytes and proof evidence.

It must not independently decide that the image is correct.

## MetaRocq CI order

The extracted program retains this ordered program:

1. pin exact sources;
2. quote the complete PCUIC MetaTheory;
3. produce proof-carrying HOL deep-embedding derivations;
4. serialize OpenTheory articles;
5. replay them with the verified Candle/OpenTheory path;
6. extract one reflective lambda-box root;
7. prove the appended MetaRocq residual safe and semantics preserving;
8. compose the Candle/compiler/MetaRocq image;
9. compile with the verified CakeML path;
10. bind source/proof/binary identities;
11. replay recursive self-verification from the installed image;
12. publish.

The interpreter cannot skip a missing stage. In particular, it has a checked
theorem that an absent HOL derivation prevents acceptance.

## Image composition

CakeML v3213 already proves

`compiler64_prog = candle_code ++ prog /\ EVERY safe_dec prog`

for a residual program and then proves `candle_top_level_soundness`.

The self-host architecture therefore extends this existing append composition.
It does not introduce an unrelated native linker as a new trusted component.

The new MetaRocq residual cannot be called safe merely because Peregrine emits
it. The final composition requires separate evidence for:

- `EVERY safe_dec` of the additional residual;
- semantic preservation of the additional residual;
- exact final image identity.

## Current blocking stage

The CI interpreter currently stops at the HOL-lowering stage because the
proof-producing PCUIC -> HOL/OpenTheory derivation compiler remains incomplete.
This is intentional and executable, not a documentation-only caveat.
