# Peregrine Self-Hosting + HOL4 Self-Certificate Manual — Delta over the Existing MetaRocq E2E Manual

## Project Goal

This directory contains ONLY the additional instructions that are missing from:

```text
docs/selfhost-bootstrap/
```

Do NOT duplicate or replace the previous 12 milestones.

The existing manual already defines the reusable:

```text
MetaRocq source/proof snapshot
  => retained executable proof corpus
  => LambdaBox retention
  => Peregrine/CakeML semantic boundary
  => HOL4 complete replay authority
  => CakeML in-logic compilation
  => exact machine-code theorem
  => recursive runtime replay
  => fail-closed publication audit
```

This delta specializes that architecture to a stronger target:

```text
Peregrine source + Peregrine proofs
        |
        | MetaRocq self-reflection
        v
ONE LambdaBox executable containing:
  - the Peregrine Rocq middle-end itself;
  - its exact configuration/parser/validation/transform/backend core;
  - the complete retained Peregrine proof replay corpus;
  - explicit assumption/replay metadata.
        |
        | execute extraction using an independently provisioned
        | MetaRocq bootstrap seed
        v
exact Peregrine LambdaBox image
        |
        | prebuilt Peregrine candidate generator
        | + separately checked proof-producing translation path
        v
exact CakeML program
        |
        | CakeML compiler evaluated inside HOL4
        v
exact machine code + HOL4 theorem
        |
        | embed a non-circular proof capsule in the same
        | executable semantics
        v
ONE executable that carries:
  - Peregrine;
  - its retained proof replay state;
  - exact provenance;
  - HOL4/OpenTheory replay artifacts;
  - enough information for a FUTURE HOL4 instance to
    reconstruct the outer exact-machine theorem.
```

## The Critical Non-Circularity Rule

Do NOT require the final executable to literally contain, before compilation, a theorem whose statement already hashes or names the complete final executable bytes.

That is circular:

```text
embed proof of final bytes
  => program changes
  => final bytes change
  => embedded proof is stale
```

The required architecture is therefore TWO-LEVEL:

```text
LEVEL 1 — Embedded Core Proof Capsule
  carried by the CakeML program BEFORE machine compilation

LEVEL 2 — Outer Exact-Machine HOL4 Attestation
  produced AFTER exact CakeML compilation
```

A future HOL4 instance can extract Level 1 from the executable, replay the exact derivations, re-evaluate the exact CakeML compiler equation, and regenerate Level 2.

If you additionally insist that Level 2 itself is physically appended into the same executable file, you MUST prove the loader/container theorem described in the later milestones. Do NOT silently treat an ELF note/trailer/linker transformation as semantics-preserving.

## Current Upstream Facts This Manual Treats as Hard Constraints

At the source revisions audited on 2026-10-04:

1. `peregrine-project/peregrine-tool` has NO `.gitmodules` file. Use `--recurse-submodules` anyway and mechanically verify that the current submodule set is empty.
2. The separate official `peregrine-project/cakeml-backend` repository is NOT a Git submodule of `peregrine-tool`; clone and pin it separately.
3. The pinned Peregrine in-tree `theories/backends/CakeMLBackend.v` still contains an `Admitted` obligation and `Axiom trust_coq_kernel`. It MAY generate a candidate CakeML artifact; it MUST NOT be accepted as final proof evidence.
4. The current `cakeml-backend` `main` commit `a5df761d5032b01ae66fc82965f1a79f313e1bbc` documents `CompileCorrect.v` and `PipelineCorrect.v`, but those files are not both present in that tree.
5. The branch `verified-compile-correct` contains a substantial `CompileCorrect.v`, but `PipelineCorrect.v` was not present in the audited branch. Therefore the complete Peregrine→CakeML E2E pipeline theorem is currently a MISSING proof obligation unless a newer reviewed upstream commit closes it.
6. The existing MetaRocq-rs selfhost workflow publishes LambdaBox/`.vo`/`.vos`/`.glob` evidence, not a standalone MetaRocq executable. The bootstrap-seed procedure MUST detect a real binary artifact before preferring it.

These facts are not excuses to weaken the target. They define where this delta must fail closed.

## Execute This Delta in Order

1. `00-reuse-map-and-target.md`
2. `01-clone-pin-and-audit-peregrine.md`
3. `02-build-peregrine-selfhost-lambdabox.md`
4. `03-bootstrap-with-prebuilt-metarocq-seed.md`
5. `04-prebuilt-peregrine-to-cakeml.md`
6. `05-close-peregrine-cakeml-proof-gap.md`
7. `06-cakeml-hol4-exact-machine-attestation.md`
8. `07-embed-non-circular-proof-capsule.md`
9. `08-future-hol4-independent-revalidation.md`
10. `09-one-command-e2e-runbook-and-publication-gate.md`
11. `10-reuse-versus-new-work-report.md`

## Reuse Policy

Whenever a new file says:

```text
REUSE: selfhost-bootstrap/Milestone NN
```

follow that existing milestone literally unless this delta explicitly overrides one part.

Do NOT copy the old instructions into a new implementation.

Do NOT fork a second certificate corpus, assumption ledger, HOL4 build, CakeML machine theorem, or publication-gate format merely because the subject is now Peregrine.

The entire point of this stack is to reuse the previously designed trust chain and add only the missing Peregrine-specific recursion/certificate layer.

## References

### MetaRocq

- Official MetaRocq architecture, quotation, PCUIC, SafeChecker and erasure overview: https://github.com/MetaRocq/metarocq/blob/9.1/README.md
- Official MetaRocq installation/package layout: https://github.com/MetaRocq/metarocq/blob/9.1/INSTALL.md

### Peregrine

- Official Peregrine repository: https://github.com/peregrine-project/peregrine-tool
- Official pipeline overview: https://github.com/peregrine-project/peregrine-tool/blob/master/doc/overview.md
- Official local-development instructions: https://github.com/peregrine-project/peregrine-tool/blob/master/doc/dev.md
- Official CakeML backend repository: https://github.com/peregrine-project/cakeml-backend

### CakeML

- Official CakeML repository: https://github.com/CakeML/cakeml
- The theorem-producing compiler evaluator interface: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/cv_translator/eval_cake_compileLib.sig
- Concrete x64 in-logic compilation example: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/examples/compilation/x64/helloCompileScript.sml

### HOL4

- Official HOL4 repository: https://github.com/HOL-Theorem-Prover/HOL
- HOL4 OpenTheory theorem/article bridge: https://github.com/HOL-Theorem-Prover/HOL/blob/40dd5b03de658f4bd9e3f4225fb0f1602ac90467/src/opentheory/postbool/OpenTheoryIO.sml
- HOL4 OpenTheory article reader interface: https://github.com/HOL-Theorem-Prover/HOL/blob/40dd5b03de658f4bd9e3f4225fb0f1602ac90467/src/opentheory/reader/OpenTheoryReader.sig
