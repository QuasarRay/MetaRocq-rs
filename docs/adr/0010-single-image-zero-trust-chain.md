# ADR 0010: Single-image zero-trust chain

Status: experimental and fail closed.

## Reuse first

This layer does not recreate the repository's existing HOL4/OpenTheory work.
`HOL4ReuseManifest.v` binds the inherited qualification theorem, PCUIC-first
policy, CakeML replay gate and architecture decision by repository path and blob
SHA. Any future migration should consume those assets or mechanically transform
them; it should not create a parallel copy.

## Candle pattern adopted

The self-host architecture follows the same shape used by Candle and the
verified OpenTheory checker:

1. maintain a source-level invariant over theorem-bearing runtime values;
2. require OpenTheory article acceptance through the verified reader;
3. bind the generated CakeML source to the verified compiler theorem;
4. transport the soundness property to the concrete machine-code image;
5. replay the machine image and connect its exported facts back to the retained
   source-level claims.

The important distinction is between **upstream theorem availability** and
**local binding**. Candle/CakeML already prove the reader and compiler theorems,
but this project must still prove that its generated article, CakeML source and
machine image are exactly the objects those theorems describe.

## Dual proof rule

Anything accepted as part of the final self image has two obligations:

- a PCUIC/MetaRocq proof anchor;
- a Candle/OpenTheory proof anchor.

Machine-code-relevant claims additionally require a CakeML machine-code
transport theorem. The acceptance function has no mode where Candle success
alone or PCUIC success alone is sufficient.

## CI/CD

`SelfCICD.v` is the canonical CI plan for this experiment. GitHub Actions is
only a bootstrap/execution transport until the extracted image can interpret
the plan itself. The final image is required to carry and interpret the same
plan that built it.

## Current blocker

The structural single-image contract now exists, but publication remains
blocked because the PCUIC-to-HOL/OpenTheory proof lowering is not yet
semantically discharged and the local bindings from generated CakeML to
Candle/CakeML machine-code theorems are not yet proved.
