# 03 — Build ONE Self-Reflective LambdaBox Executable of Peregrine + the Complete Peregrine Proof Replay State

> **UNIFIED SEQUENCE STEP 03 OF 22 — PEREGRINE TRUST FOUNDATION.**  
> Reused from `docs/peregrine-selfhost-certificate/02-build-peregrine-selfhost-lambdabox.md` on `docs/peregrine-selfhost-03-independent-replay`. The original manual remains preserved. This copy reorders and connects the existing instructions into the unified Peregrine -> MetaRocq E2E sequence. Execute this file completely before continuing to the next numbered file.

## Objective

Use MetaRocq to produce ONE LambdaBox program whose executable root contains:

```text
Peregrine.Pipeline.peregrine_pipeline
Peregrine.Pipeline.peregrine_validate

PLUS

the complete retained proof-replay state for EVERY in-scope
Peregrine-owned theorem/proof declaration

PLUS

a separate complete assumption ledger

PLUS

a deterministic command interface for:
  - running Peregrine;
  - validating LambdaBox input;
  - enumerating certificates;
  - enumerating assumptions;
  - replaying one certificate;
  - replaying all certificates;
  - returning exact source/corpus identities.
```

The output MUST be a single:

```text
generated/peregrine-selfhost/peregrine-selfhost.ast
```

artifact.

## REUSE

Do NOT invent another certificate architecture.

Reuse:

```text
docs/selfhost-bootstrap/03-capture-complete-source-and-proof-corpus.md
docs/selfhost-bootstrap/04-self-reflection-and-lambdabox-retention.md
docs/selfhost-bootstrap/05-erasure-correctness-and-assumption-closure.md
```

Reuse the existing MetaRocq-rs concepts:

```text
PCUICCertificateIR
source assumption ledger
replay jobs
retained executable proof data
fail-closed completeness theorem
```

Generalize them if necessary so both MetaRocq-selfhost and Peregrine-selfhost can use the same infrastructure.

Do NOT copy/paste a second incompatible implementation.

## 1. Define Exactly What “All Peregrine Proofs” Means

Create:

```text
spec/peregrine-proof-scope.json
```

The primary scope SHOULD be:

```text
every kernel declaration whose defining source belongs to
the pinned peregrine-project/peregrine-tool theories/** tree
and whose declaration contains a proof body / theorem body.
```

This includes:

- `Theorem`;
- `Lemma`;
- `Corollary`;
- generated `Program` obligations with bodies;
- proof-bearing definitions used as correctness evidence;
- backend correctness lemmas;
- transformation-preservation lemmas;
- wellformedness proofs;
- serialization/deserialization proofs if used in the final chain.

Imported MetaRocq/Ceres/CertiRocq/Rocq theorems are TRANSITIVE DEPENDENCIES.

They MUST be pinned and represented in the dependency ledger, but do not falsely count them as “Peregrine-owned proofs.”

## 2. Create a Dedicated Peregrine Selfhost Formalization Directory

Create:

```text
metatheory/peregrine-selfhost/
  PeregrineSourceManifest.v
  PeregrineSnapshot.v
  PeregrineCertificateIR.v
  PeregrineReplay.v
  PeregrineSelfHostRoot.v
  ExtractPeregrineSelfHost.v
```

Prefer thin wrappers around reusable modules from:

```text
metatheory/original-selfhost/
```

where their representations are generic enough.

If a data type is genuinely generic, MOVE/GENERALIZE it rather than duplicating it.

## 3. Import the Exact Peregrine Core

The root file should import the formal Peregrine pipeline:

```coq
From Peregrine Require Import Pipeline.
```

The two primary runtime functions are:

```coq
Pipeline.peregrine_pipeline
Pipeline.peregrine_validate
```

Do NOT use the OCaml `bin/` CLI as the formal source root.

The official Peregrine build itself extracts these Rocq definitions into host code from:

```text
theories/Extraction.v
```

That is strong evidence that these are the intended executable middle-end roots.

## 4. Recursively Quote the Exact Peregrine Root

MetaRocq officially provides:

```coq
MetaRocq Quote Recursively Definition name := term.
```

and the Template Monad primitive:

```coq
tmQuoteRecTransp term bypass_opacity
```

where bypassing opacity allows recursive quotation of opaque bodies when available to the quoting mechanism.

Create an explicit root, conceptually:

```coq
Definition peregrine_formal_core :=
  (Pipeline.peregrine_pipeline,
   Pipeline.peregrine_validate).
```

Then quote it recursively.

For ordinary inspection:

```coq
MetaRocq Quote Recursively Definition
  peregrine_core_snapshot :=
  peregrine_formal_core.
```

For the programmatic snapshot builder, prefer an explicit Template Monad call so opacity policy is visible:

```coq
MetaRocq Run (
  p <- tmQuoteRecTransp peregrine_formal_core true ;;
  ...
).
```

Do NOT let opacity behavior be an undocumented default.

## 5. Build a Source-Origin Index

Recursive quotation gives the transitive environment needed by the root.

It does NOT by itself tell a human which declarations are Peregrine-owned versus imported.

Build a source-origin manifest from the pinned tree:

```bash
find .aegis/references/peregrine-selfhost/theories \
  -type f -name '*.v' -print \
  | LC_ALL=C sort \
  > generated/e2e/peregrine-theory-files.txt
```

For each proof-bearing kernel declaration, retain:

```text
kernel name
source file
source repository commit
statement AST
proof/body AST
universe context
direct referenced kernel names
declaration digest
statement digest
proof digest
```

The Rocq/MetaRocq quoted environment is authoritative for declaration contents.

The source-origin index is an audit binding.

## 6. Split Proof-Bearing Declarations from Assumptions

Use the same rule as the previous manual.

Conceptually:

```text
constant body = Some proof
  -> Peregrine certificate corpus

constant body = None
  -> assumption ledger
```

Do NOT turn:

- axioms;
- admitted obligations;
- abstract parameters;
- external FFI assumptions;
- unsafe extraction assumptions

into “proved certificates.”

In particular, the known:

```text
CakeMLBackend.v:
  Admitted
  trust_coq_kernel
```

MUST appear in the forbidden/unresolved assumption audit if that in-tree backend is included.

## 7. Prove Corpus Completeness Bidirectionally

Do NOT accept:

```text
length corpus = N
```

as completeness.

Prove an exact relation equivalent to:

```text
forall d,
  PeregrineOwnedProofDeclaration exact_snapshot d
  <->
  exists c,
    In c peregrine_certificate_corpus /\
    certificate_exactly_represents c d
```

and uniqueness:

```text
forall d c1 c2,
  represents c1 d ->
  represents c2 d ->
  c1 = c2
```

The final HOL4 chain must later rely on this theorem so that dropping ONE Peregrine proof makes the final publication theorem unavailable.

## 8. Reify Proofs BEFORE Erasure

Do NOT expect raw proof objects in `Prop` to survive extraction.

Required architecture:

```text
Peregrine proof : theorem
        |
        | MetaRocq quotation
        v
PCUIC syntax of statement + proof body in Type
        |
        | retained by executable root
        v
LambdaBox computational data
```

The retained certificate is ordinary executable data.

This is the SAME architecture already specified for MetaRocq itself.

## 9. Define a Single Command-Based Selfhost Runtime

Do not expose several unrelated extraction roots.

Create one command type, conceptually:

```coq
Inductive peregrine_selfhost_command :=
| RunPeregrine
| ValidatePeregrineInput
| ListCertificates
| ListAssumptions
| ReplayCertificate
| ReplayAllCertificates
| ReportIdentity.
```

Create a single response type containing deterministic results.

Then define:

```coq
Definition peregrine_selfhost_entrypoint
  : peregrine_selfhost_command
    -> peregrine_selfhost_response :=
  ...
```

The `RunPeregrine` command MUST call the exact:

```text
Pipeline.peregrine_pipeline
```

definition.

The validation command MUST call:

```text
Pipeline.peregrine_validate
```

Do NOT reimplement their logic in a second wrapper.

## 10. Define the Replay Runtime as Evidence, NOT Foundational Trust

The runtime MAY contain a checker/replay engine over retained PCUIC syntax.

It MUST expose:

```text
per-certificate replay result
complete aggregate replay result
assumption set identity
certificate corpus identity
source snapshot identity
```

But later HOL4 independently establishes what the replay computation means.

Therefore:

```text
runtime ReplayAll = useful executable evidence
HOL4 theorem = final authority
```

Do NOT reverse this trust direction.

## 11. Ensure the Replay Runtime Itself Is in the Quoted Scope

This is essential for self-reference.

The exact source snapshot MUST include the NEW:

- certificate construction;
- assumption construction;
- replay functions;
- replay result types;
- command interpreter;
- identity reporting logic.

Otherwise the executable could validate an older Peregrine but omit its own validation machinery.

Add a theorem equivalent to:

```text
SelfReplayImplementationIncluded
  exact_source_snapshot
  peregrine_selfhost_entrypoint
```

derived from exact kernel membership.

Do NOT represent this as a manually set Boolean.

## 12. Extract ONE LambdaBox Program

Use the Peregrine Rocq frontend after the retained root is complete.

Conceptual extraction driver:

```coq
From Peregrine.Plugin Require Import Loader.
From MetaRocqRs.PeregrineSelfHost
  Require Import PeregrineSelfHostRoot.

Peregrine Extract
  "generated/peregrine-selfhost/peregrine-selfhost.ast"
  peregrine_selfhost_entrypoint.
```

If the exact logical path differs after creating the new modules, update only the module path.

Do NOT change the final root.

Build:

```bash
mkdir -p generated/peregrine-selfhost

eval "$(opam env --switch .aegis/opam --set-switch)"

rocq compile \
  -Q metatheory/peregrine-selfhost MetaRocqRs.PeregrineSelfHost \
  metatheory/peregrine-selfhost/PeregrineSourceManifest.v

rocq compile \
  -Q metatheory/peregrine-selfhost MetaRocqRs.PeregrineSelfHost \
  metatheory/peregrine-selfhost/PeregrineSnapshot.v

rocq compile \
  -Q metatheory/peregrine-selfhost MetaRocqRs.PeregrineSelfHost \
  metatheory/peregrine-selfhost/PeregrineCertificateIR.v

rocq compile \
  -Q metatheory/peregrine-selfhost MetaRocqRs.PeregrineSelfHost \
  metatheory/peregrine-selfhost/PeregrineReplay.v

rocq compile \
  -Q metatheory/peregrine-selfhost MetaRocqRs.PeregrineSelfHost \
  metatheory/peregrine-selfhost/PeregrineSelfHostRoot.v

rocq compile \
  -Q metatheory/peregrine-selfhost MetaRocqRs.PeregrineSelfHost \
  metatheory/peregrine-selfhost/ExtractPeregrineSelfHost.v
```

Then:

```bash
test -s generated/peregrine-selfhost/peregrine-selfhost.ast

sha256sum \
  generated/peregrine-selfhost/peregrine-selfhost.ast \
  > generated/e2e/peregrine-selfhost-lambdabox.sha256
```

## 13. Prove Retention Across Erasure

Reuse the previous source→LambdaBox observation theorem pattern.

The observation MUST include at least:

```text
Peregrine source snapshot digest
Peregrine certificate corpus digest
Peregrine assumption ledger digest
ordered certificate identities
ordered replay-job identities
RunPeregrine command availability
ReplayAllCertificates command availability
```

Prove that the extracted LambdaBox program exposes the same exact retained observation.

## 14. Add Mandatory Mutation Tests

The final selfhost LambdaBox stage MUST fail if you:

1. remove one Peregrine theorem certificate;
2. alter one retained statement;
3. alter one proof AST;
4. drop one assumption;
5. remove `peregrine_pipeline` from the root;
6. remove `ReplayAllCertificates`;
7. change source commit without regenerating the corpus;
8. use the in-tree CakeML `trust_coq_kernel` as proof closure.

## Completion Gate

This milestone is complete only when ONE LambdaBox artifact contains:

- the formal Peregrine core;
- exact pipeline + validation functions;
- complete Peregrine-owned proof certificate corpus;
- complete assumption ledger;
- deterministic replay jobs;
- replay implementation itself inside the reflected scope;
- one command-based executable root;
- a proved source→LambdaBox retained-state relation.

A successful `.ast` generation WITHOUT the completeness/retention theorems is NOT completion.

## References

### MetaRocq

- Official recursive quotation command and architecture: https://github.com/MetaRocq/metarocq/blob/9.1/README.md
- Template Monad recursive quotation implementation/API: https://github.com/MetaRocq/metarocq/blob/9.1/template-rocq/theories/TemplateMonad/Core.v
- Official self-erasure example: https://github.com/MetaRocq/metarocq/blob/9.1/test-suite/self_erasure.v
- Verified erasure theories: https://github.com/MetaRocq/metarocq/tree/9.1/erasure/theories

### Peregrine

- Formal pipeline definitions: https://github.com/peregrine-project/peregrine-tool/blob/d768b83ffa7dab35b8d72241f0570b5bb6aedae9/theories/Pipeline.v
- Peregrine's own ordinary extraction roots: https://github.com/peregrine-project/peregrine-tool/blob/d768b83ffa7dab35b8d72241f0570b5bb6aedae9/theories/Extraction.v
- Official Rocq frontend extraction command: https://github.com/peregrine-project/peregrine-tool/blob/master/doc/frontends.md
- Peregrine backend architecture: https://github.com/peregrine-project/peregrine-tool/blob/master/doc/backends.md

### CakeML

- CakeML program/machine compilation is theorem-producing inside HOL4: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/examples/compilation/x64/helloCompileScript.sml
- CakeML E2E proof composition: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/examples/compilation/x64/proofs/helloProofScript.sml

### HOL4

- HOL4 official repository: https://github.com/HOL-Theorem-Prover/HOL
- HOL4 OpenTheory proof export API used by the later independent replay layer: https://github.com/HOL-Theorem-Prover/HOL/blob/40dd5b03de658f4bd9e3f4225fb0f1602ac90467/src/opentheory/postbool/OpenTheoryIO.sig
