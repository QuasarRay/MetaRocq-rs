# ADR 0013: Reuse the existing HOL4/OpenTheory migration backbone

Status: experimental, fail closed.

## Decision

The self-host work must not create a second HOL4/OpenTheory import stack.

This branch already inherits the qualified migration infrastructure from
`generated/hol4-pcuic-proof-migration`:

1. HOL4 theorem export through the official pinned OpenTheory logger;
2. OpenTheory translation through pinned Holide;
3. independent Dedukti checking through pinned Lambdapi;
4. STT-to-Rocq export with explicit mapping/assumption reporting;
5. Rocq kernel checking;
6. MetaRocq recursive quotation back into
   `MetaRocq.PCUIC.PCUICProgram.pcuic_program`;
7. the existing fail-closed Original-MetaRocq CakeML replay diagnostic.

The self-host direction is different:

```
PCUIC / MetaRocq certificate
  -> HOL deep embedding
  -> OpenTheory
  -> Candle
```

The existing reverse direction is reused as an independent round-trip validator:

```
PCUIC source
  -> generated OpenTheory
  -> Holide
  -> independently checked Dedukti
  -> Rocq kernel
  -> MetaRocq re-quotation
  -> compare PCUIC statement + assumption ledger
```

A translation is not publishable merely because Candle accepts the generated
article. It must also survive this reverse migration without changing the
represented theorem or introducing hidden assumptions.

## Existing HOL4 scope

The repository contains qualified HOL4 adapter/bootstrap material and migration
smoke theories. Those artifacts are useful proof/tool qualification evidence.

They are not a complete HOL4 formalization of the full PCUIC metatheory. The
self-host stack therefore reuses them for migration, differential checking, and
machine-verification support without calling them a semantic-equivalence proof.

## No duplication policy

The following inherited files are pinned by
`HOL4ReuseContract.v` and are reused rather than rewritten:

- `formal/hol4/MetaRocqBootstrapScript.sml`
- `formal/hol4/MetaRocqMigrationSmokeScript.sml`
- `tools/hol4_pcuic_core.py`
- `tools/hol4_pcuic_translate.py`
- `tools/harvest_hol4_pcuic.py`
- `tools/original_cakeml_replay_gate.py`
- `spec/hol4-opentheory-pcuic.lock.json`
- `metatheory/bootstrap/Hol4ImportedQuote.v.in`

If a later change needs behavior already present in those assets, it must adapt
or call that behavior instead of creating a parallel implementation.

## Candle design pattern

Candle's verified architecture is used as the target pattern:

1. prove source-level soundness for a kernel-prefixed program;
2. prove the interactive/evaluation residual is safe;
3. use the verified CakeML compiler theorem to transport soundness to machine
   code;
4. constrain externally observable theorem export to a kernel-controlled
   channel.

For this project, the corresponding residual is the extracted MetaRocq
self-reflection and CI interpreter. It does not become trusted merely because
Peregrine emitted CakeML source.

## Current blocker

The remaining semantic blocker is still the proof-producing PCUIC-to-HOL
encoding/checker bridge. The existing reverse bridge reduces duplicate work and
gives a strong differential validation path, but it does not prove that forward
translation by itself.
