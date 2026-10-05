# 01 — Reuse the Existing MetaRocq E2E Manual and Freeze the Stronger Peregrine Target

> **UNIFIED SEQUENCE STEP 01 OF 22 — PEREGRINE TRUST FOUNDATION.**  
> Reused from `docs/peregrine-selfhost-certificate/00-reuse-map-and-target.md` on `docs/peregrine-selfhost-03-independent-replay`. The original manual remains preserved. This copy reorders and connects the existing instructions into the unified Peregrine -> MetaRocq E2E sequence. Execute this file completely before continuing to the next numbered file.

## Objective

Do NOT restart the existing selfhost formalization.

This milestone defines exactly which parts of:

```text
docs/selfhost-bootstrap/
```

remain authoritative, and exactly which additional obligations exist because the subject being self-hosted is now **Peregrine itself** and because the executable must carry a replayable HOL4 certification capsule.

The final target is:

```text
exact Peregrine Rocq source P
+ complete in-scope Peregrine proof corpus C
+ exact assumption ledger A
        |
        | MetaRocq quotation + verified erasure
        v
exact self-reflective LambdaBox program L
        |
        | independently provisioned MetaRocq bootstrap seed
        v
materialized L
        |
        | prebuilt Peregrine candidate execution
        | + proof-producing Peregrine→CakeML bridge
        v
exact CakeML program K
        |
        | eval_cake_compile_x64 INSIDE HOL4
        v
exact machine-code object M
        |
        | CakeML compile_correct + application semantics
        v
HOL4 theorem:
  machine(M) refines PeregrineSelfHostSpec(P,C,A)
        |
        | embedded Level-1 proof capsule
        v
M carries enough proof/provenance material for
ANOTHER HOL4 instance to reconstruct the validation
and regenerate the outer exact-machine theorem.
```

## 1. Reuse These Previous Milestones WITHOUT Rewriting Them

### REUSE: Milestone 01 — trust and E2E completion criteria

Reuse:

```text
docs/selfhost-bootstrap/01-trust-and-e2e-completion-criteria.md
```

Unchanged requirements:

- exact artifact identities;
- proof-corpus completeness;
- separate assumption ledger;
- HOL4 as final proof authority;
- process success/hashes are NOT semantic proofs;
- fail-closed final gate.

### REUSE: Milestone 02 — pinned laptop toolchain

Reuse:

```text
docs/selfhost-bootstrap/02-laptop-pinned-toolchain.md
```

Only ADD:

- a dedicated pinned Peregrine selfhost checkout;
- a separately pinned Peregrine CakeML backend checkout;
- an explicit MetaRocq bootstrap-seed resolver.

Do NOT create another global opam/HOL4/CakeML installation.

### REUSE: Milestone 03 — complete source/proof corpus

Reuse the exact certificate/assumption architecture from:

```text
docs/selfhost-bootstrap/03-capture-complete-source-and-proof-corpus.md
```

Change only the source scope from “MetaRocq selfhost source” to the exact in-scope Peregrine Rocq theories and their transitive proof dependencies.

### REUSE: Milestones 04–05 — retained proof data through erasure

Reuse:

```text
04-self-reflection-and-lambdabox-retention.md
05-erasure-correctness-and-assumption-closure.md
```

The same rule applies:

```text
proof term in Prop
    -> quoted structured PCUIC proof AST in Type
    -> retained executable replay data
    -> survives LambdaBox erasure
```

Do NOT modify erasure merely to keep raw `Prop` proof terms.

### REUSE: Milestones 06–09 — Peregrine/CakeML/HOL4/machine theorem

Reuse the architecture, BUT apply the stronger upstream audit in this delta.

The old Milestone 06 assumed that a separate Peregrine CakeML correctness theorem could be pinned. The current audit shows that this theorem path is incomplete upstream at the examined revisions.

Therefore:

```text
old architecture = reusable
upstream theorem availability assumption = NOT reusable
```

This delta must close that gap rather than mark it green.

### REUSE: Milestone 10 — recursive machine self-replay

Reuse its non-circular trust principle:

```text
HOL4 proves the machine behavior
        |
        v
machine replays its retained state
        |
        v
runtime replay confirms theorem-bound identity
```

Do NOT allow:

```text
machine says it is valid
=> therefore it is valid
```

### REUSE: Milestones 11–12 — local operation and publication audit

Reuse exactly:

- one deterministic local driver;
- semantic cache keys;
- clean-checkout reproduction;
- theorem-tag/oracle audit;
- mutation tests;
- no proof weakening;
- precise release language.

This delta extends the publication checklist; it does not replace it.

## 2. Define the NEW Obligations

The previous manual did NOT fully specify the following.

### NEW-1 — Peregrine source as the program being self-hosted

You must define one exact Rocq-level Peregrine root based on:

```text
Pipeline.peregrine_pipeline
Pipeline.peregrine_validate
```

plus the explicit retained replay runtime.

The OCaml executable in `bin/` is a host wrapper around extracted Rocq code. It is NOT the formal source root.

### NEW-2 — Peregrine's own complete proof replay corpus

The retained corpus must now cover the in-scope Peregrine theorem-bearing Rocq theories, not merely MetaRocq-rs's selfhost helper theories.

### NEW-3 — independent MetaRocq bootstrap seed

The pipeline that creates the Peregrine LambdaBox image must be executed by a pre-existing MetaRocq-capable seed.

Priority:

```text
MetaRocq-rs exact prebuilt binary artifact, IF one genuinely exists
        >
pinned prebuilt MetaRocq/Rocq package environment
        >
one-time build from exact pinned MetaRocq source
```

No source-generated seed may silently certify itself.

### NEW-4 — prebuilt Peregrine candidate bootstrap

A prebuilt Peregrine executable may generate the CakeML candidate from the newly generated Peregrine LambdaBox image.

But candidate generation is NOT proof evidence.

### NEW-5 — close the real Peregrine→CakeML proof gap

The current upstream source audit exposes missing/incomplete correctness artifacts.

This is new formalization work.

### NEW-6 — embed the proof-replay capsule INTO the CakeML program

The final CakeML semantics must include a deterministic embedded capsule containing the proof/provenance data required for later independent revalidation.

### NEW-7 — avoid an impossible self-referential theorem

The exact final-machine theorem is produced AFTER compilation.

Therefore it cannot be an ordinary pre-compilation CakeML data constant that already describes its own final byte representation.

The correct target is:

```text
embedded inner proof capsule
+
external/reconstructible outer machine theorem
```

or, for the stronger “all in one physical file” variant:

```text
proved loader/container projection
  final-file -> verified code region + proof region
```

### NEW-8 — future-HOL4 reconstruction theorem

A second HOL4 installation must be able to:

1. parse/extract the embedded capsule;
2. independently replay the relevant proof artifacts;
3. reconstruct the exact CakeML program identity;
4. re-evaluate the in-logic CakeML compilation;
5. compare the exact machine-code representation;
6. regenerate the outer refinement theorem.

## 3. Freeze the New Final Specification

Define a specification equivalent to:

```text
PeregrineSelfHostSpec
  source_snapshot
  proof_corpus
  assumptions
  lambdabox
  cakeml_program
  embedded_capsule
  machine_code
```

whose required properties include:

```text
CompletePeregrineProofCorpus
AllRetainedPeregrineProofsReplay
PeregrinePipelineBehavior
LambdaBoxRefinesPeregrineSource
CakeMLRefinesLambdaBox
MachineRefinesCakeML
EmbeddedCapsuleEqualsBuildProofInputs
FutureHOL4CanReconstructValidation
```

Do not represent these as unrelated Boolean fields.

The final HOL4 theorem must compose them.

## 4. Define Two Publication Levels

### Level A — Recommended E2E target

The theorem-bound machine program contains the Level-1 proof capsule as ordinary CakeML data.

The final exact-machine theorem is stored externally but is reproducible from the embedded capsule.

This avoids circularity and stays inside the verified CakeML program semantics.

### Level B — Stronger single-physical-file target

The final packaged executable physically contains BOTH:

- theorem-bound executable code;
- outer proof article/attestation bytes.

This requires a proved packaging/loader theorem:

```text
load_code (pack code certificate) = code
extract_certificate (pack code certificate) = certificate
```

and a theorem showing the executable runtime semantics depend only on the verified code projection.

If this theorem does not exist, Level B is BLOCKED.

Do NOT silently call an unproved ELF note, appended trailer, `objcopy` section, linker script, or post-link mutation “verified.”

## 5. Freeze the Branching Strategy

All new documentation branches MUST stack on:

```text
docs/selfhost-bootstrap-04-runtime-audit
```

Do not edit the previous manual destructively.

Recommended stack:

```text
docs/peregrine-selfhost-01-source-bootstrap
  -> docs/peregrine-selfhost-02-cakeml-certificate
     -> docs/peregrine-selfhost-03-independent-replay
```

The implementation formalization can later follow an equivalent code PR stack.

## Completion Gate

This milestone is complete when:

- every previous milestone is classified as reused or overridden;
- the stronger Peregrine target is written precisely;
- the MetaRocq seed is explicitly non-circular;
- candidate generation is separated from proof evidence;
- the upstream Peregrine→CakeML proof gap is explicitly BLOCKED until closed;
- the embedded proof design avoids byte-level self-reference;
- Level A and Level B are distinguished.

## References

### MetaRocq

- MetaRocq architecture, quotation, PCUIC, erasure and SafeChecker: https://github.com/MetaRocq/metarocq/blob/9.1/README.md
- MetaRocq installation and package decomposition: https://github.com/MetaRocq/metarocq/blob/9.1/INSTALL.md

### Peregrine

- Peregrine pipeline architecture: https://github.com/peregrine-project/peregrine-tool/blob/master/doc/overview.md
- Peregrine Rocq frontend and MetaRocq erasure usage: https://github.com/peregrine-project/peregrine-tool/blob/master/doc/frontends.md
- Peregrine core pipeline source: https://github.com/peregrine-project/peregrine-tool/blob/d768b83ffa7dab35b8d72241f0570b5bb6aedae9/theories/Pipeline.v
- Official CakeML backend repository: https://github.com/peregrine-project/cakeml-backend

### CakeML

- In-logic CakeML compiler evaluator API: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/cv_translator/eval_cake_compileLib.sig
- CakeML end-to-end x64 proof composition example: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/examples/compilation/x64/proofs/helloProofScript.sml

### HOL4

- HOL4 theorem-to-OpenTheory article function: https://github.com/HOL-Theorem-Prover/HOL/blob/40dd5b03de658f4bd9e3f4225fb0f1602ac90467/src/opentheory/postbool/OpenTheoryIO.sml
- HOL4 OpenTheory article reader: https://github.com/HOL-Theorem-Prover/HOL/blob/40dd5b03de658f4bd9e3f4225fb0f1602ac90467/src/opentheory/reader/OpenTheoryReader.sig
