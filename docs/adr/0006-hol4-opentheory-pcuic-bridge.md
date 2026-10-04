# ADR 0006: isolate HOL4 → OpenTheory → Rocq → PCUIC reuse bridge

Status: **experimental, fail-closed, off the primary formalization critical path**.

## Context

MetaRocq-rs already contains qualified HOL4/Aegis infrastructure and earlier HOL4 work may contain reusable formal material. The primary project goal remains the Rust-native MetaRocq/PCUIC metatheory and its implementation. This bridge exists only to harvest reusable HOL4 results mechanically; it does not make HOL4 a prerequisite for the primary formalization or implementation roadmap.

No production-quality one-step HOL4 → PCUIC translator exists. `coq-hol-light` is also not an OpenTheory importer: it is the large Rocq library produced by the HOL-Light-specific `hol2dk` → Lambdapi pipeline. Reusing it as though it parsed HOL4 would create a false trust boundary.

## Decision

Reuse existing translator/checker implementations instead of implementing a new logical translator:

```text
clean pinned HOL4 theorem object
    │ official OpenTheoryIO.thm_to_article
    ▼
OpenTheory article
    │ Holide (producer)
    ▼
Dedukti proof
    │ Lambdapi independent check
    ▼
checked STT proof
    │ Lambdapi's existing Holide/STT → Rocq exporter
    │ + coq-hol-light mapping/alignment catalog audit
    ▼
Rocq source
    │ Rocq kernel
    ▼
kernel-checked Rocq theorem
    │ MetaRocq PCUIC tmQuoteRecTransp
    ▼
PCUIC program
```

`spec/hol4-opentheory-pcuic.lock.json` pins every source revision and every upstream adapter/configuration file that is part of this route. The `tools/hol4_pcuic_*.py` modules orchestrate those tools without shell-evaluated command strings and write hash-bound evidence.

### Role of coq-hol-light

The project reuses `coq-hol-light` as a **Rocq-side mapping/alignment catalog and proven large-scale precedent**, not as an OpenTheory parser. Exact source-symbol matches are reported automatically. Applying a non-core mapping requires an independently checked Rocq mapping proof and is deliberately not guessed by this bridge.

The packaged `coq-hol-light` theorem database must **never** satisfy a proof gate: its README documents that translated theorems are distributed as axioms for fast loading. The bridge therefore rejects imports of `HOLLight.theorems` and never counts those packaged axioms as proof evidence. Full regenerated proofs are the acceptable path.

## Trust boundaries

1. **HOL4**: the source theorem is fetched from an already-built HOL4 theory and exported with HOL4's own pinned OpenTheory logger. A wrong-revision or tracked-dirty `HOLDIR` is rejected.
2. **Holide**: a translation producer, not a trust root. Its article check and successful exit are insufficient by themselves.
3. **Lambdapi**: the exact Dedukti bytes to be exported are independently type-checked. The exporter is then reused with its pinned STT encoding/mapping files. Upstream documentation warns that export alone may produce incomplete output, so export is never accepted without the next gate.
4. **Rocq kernel**: generated theorem modules containing `Admitted`, `admit`, new `Axiom`/`Parameter`, or `HOLLight.theorems` are rejected, then compiled by the project-compatible Rocq 9.1 kernel. Standard HOL support assumptions are isolated and reported explicitly.
5. **MetaRocq**: only the kernel-accepted theorem is recursively quoted into PCUIC, including dependencies and opaque bodies.

This establishes a reliable *translation/checking backbone*. It does **not** by itself prove that arbitrary HOL and PCUIC semantics are equivalent; the classical HOL assumptions and every nontrivial mapping remain explicit proof obligations.

## Failure policy

Missing sources/tools, wrong commits, dirty pinned sources, symlink/path redirection, malformed identifiers, failed intermediate checks, generated proof holes, untracked theorem axioms, or missing kernel artifacts block the pipeline. A process exit code, hash, mapping-name match, or generated `.v` file is not sufficient proof acceptance.

## Prioritization

This experiment does not edit `.agents/roadmaps/metarocq-bootstrap.json` and opens no existing formal gate. It is intended to reduce future Astra work by mechanically migrating reusable HOL4 results into the Rust-native PCUIC development. Independent HOL4 verification remains separable from the primary MetaRocq-rs formalization/implementation path.
