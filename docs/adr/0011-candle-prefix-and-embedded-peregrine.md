# ADR 0011: Candle/compiler prefix and embedded Peregrine

Status: experimental and fail closed.

## Exact Candle composition point

At pinned CakeML v3213 commit
`c98da7fc904c5d6d0e9a75a18fac1796a9bfb1f9`,
`x64BootstrapProofScript.sml` proves:

- `compiler64_prog_eq_candle_code_append`: the CakeML compiler program is
  `candle_code ++ prog`, and every declaration in the suffix satisfies
  `safe_dec`;
- `candle_top_level_soundness`: the resulting x64 machine semantics only
  emits Candle-approved theorem events;
- `cake_compiled_thm`: the compiler image is connected to CakeML's verified
  compilation theorem.

This is the reusable composition seam for the MetaRocq variation. The intended
source image is therefore the existing Candle-enabled compiler program plus a
MetaRocq-generated CakeML suffix, with a new `EVERY safe_dec` proof for that
suffix.

## Peregrine is now partially embedded

The pinned Peregrine implementation exposes its parsing, validation,
name-sanitization and transformation pipeline as Rocq definitions. This PR
imports and executes those definitions directly from the MetaRocq extraction
root through `EmbeddedPeregrine.prepare_cakeml`.

The backend is deliberately not accepted yet. The pinned
`Peregrine.CakeMLBackend` contains two independent proof holes:

1. the final obligation of `cakeml_pipeline` is `Admitted`;
2. `trust_coq_kernel` is an axiom used by `extract_cakeml`.

The final zero-trust image must reconstruct both obligations or bypass this
wrapper using a backend whose required theorem is proved. Neither hole may be
silently inherited.

## Erasure and recursive identity

The suffix-safety certificate, Candle theorem bindings, component revisions,
CI-plan identity and replay digests remain computational data. The final image
must report the same architecture/claims that were baked into the source
snapshot and must replay the same retained proof set.

## Current blocking obligations

The shared source image remains unpublishable until:

1. the MetaRocq-generated CakeML suffix is bound to the exact generated source;
2. `EVERY safe_dec` and syntax safety are proved for that suffix;
3. both Peregrine CakeML backend proof holes are eliminated;
4. the extended CakeML source program is locally connected to the pinned
   Candle/CakeML machine-code theorem;
5. recursive source/PCUIC/OpenTheory/CakeML/machine-code identity digests are
   generated and proved consistent.
