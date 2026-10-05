# ADR 0010: Single-image recursive reflection without circular trust

Status: experimental, fail closed.

## Goal

Produce one CakeML/x64 image which simultaneously contains:

1. the extracted Original-MetaRocq self-host runner;
2. retained PCUIC self-snapshot and OpenTheory proof payload;
3. Peregrine regeneration machinery;
4. the verified OpenTheory reader / Candle kernel;
5. the Candle-capable CakeML compiler REPL.

The image may recursively inspect and replay its own architecture. It must not
use self-assertion as proof evidence.

## Exact v3213 theorem anchors

The contract pins the CakeML source revision
`c98da7fc904c5d6d0e9a75a18fac1796a9bfb1f9` and exact Git blob identities for:

- `readerProgProof.machine_code_sound`: OpenTheory acceptance to HOL validity
  and installed x64 machine code;
- `candle_prover_semantics.semantics_thm`: top-level Candle semantics;
- `compiler64Prog.semantics_compiler64_prog`: compiler semantics;
- `replProof.semantics_prog_compiler64_prog`: compiler REPL semantics;
- `x64BootstrapProof.candle_top_level_soundness`: the x64 theorem that imports
  both REPL verification and Candle prover semantics.

The pinned compiler source also defines `has_repl_flag` as accepting either
`--repl` or `--candle`, and selects Candle parsing when `--candle` is
present. Therefore the target architecture reuses the verified compiler image
as the Candle-capable execution host instead of pretending that an unrelated
second compiler binary is necessary.

## Recursive reflection

The trust graph is represented inside MetaRocq and has explicit decreasing
ranks:

```
recursive self image
  -> PCUIC self theory
  -> HOL/OpenTheory lowering derivation
  -> Candle article acceptance
  -> verified CakeML compilation
  -> installed machine image
  -> bootstrap seed
```

Rocq checks a theorem that every edge strictly decreases. The executable
recursive verifier is fuel-bounded and a separate theorem establishes that it
cannot accept the recursive self image when the bootstrap seed is false.

This preserves recursive *reflection* while rejecting recursive *trust*.

## Remaining semantic blocker

The structural single-image contract is proved, but semantic readiness remains
false until the MetaRocq-owned PCUIC-to-HOL/OpenTheory proof-producing lowering
is proved. No CakeML linking or source digest can replace that theorem.

## Peregrine

Peregrine remains a generator. Its pinned CakeML backend's
`trust_coq_kernel` axiom is forbidden as proof evidence. Its output becomes
acceptable only through the independent retained proof path and CakeML/Candle
machine-code theorem chain.
