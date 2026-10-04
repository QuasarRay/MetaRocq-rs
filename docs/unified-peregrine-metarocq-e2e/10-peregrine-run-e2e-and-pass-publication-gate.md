# 10 — Execute the Entire Peregrine Self-Hosting + HOL4 Certificate Chain with ONE Fail-Closed Command

> **UNIFIED SEQUENCE STEP 10 OF 22 — PEREGRINE TRUST FOUNDATION.**  
> Reused from `docs/peregrine-selfhost-certificate/09-one-command-e2e-runbook-and-publication-gate.md` on `docs/peregrine-selfhost-03-independent-replay`. The original manual remains preserved. This copy reorders and connects the existing instructions into the unified Peregrine -> MetaRocq E2E sequence. Execute this file completely before continuing to the next numbered file.

## Objective

Turn Milestones 00–08 into ONE deterministic local workflow whose final success condition is:

```text
HOL4 constructed and kernel-checked the exact PeregrineSelfHostE2E theorem
AND
fresh independent HOL4 reconstructed the same theorem-bound validation
```

Everything else is intermediate state.

A generated file, successful compiler exit, CI green check, digest match, replay Boolean, or serialized theorem name MUST NOT independently authorize publication.

## REUSE

Reuse WITHOUT copying/reimplementing:

```text
docs/selfhost-bootstrap/11-local-operation-debugging-and-recovery.md
docs/selfhost-bootstrap/12-final-audit-and-publication-gate.md
```

Also reuse the existing PR #30 producer:

```text
tools/peregrine_selfhost_pipeline.sh
```

Extend/refactor it into the final staged driver rather than creating a second competing pipeline.

## 1. Create ONE Canonical Driver

Preferred path:

```text
tools/peregrine-selfhost-e2e.sh
```

or rename/extend the existing:

```text
tools/peregrine_selfhost_pipeline.sh
```

but keep ONE canonical implementation.

Required commands:

```text
pins
clone
seed
snapshot
lambdabox
candidate
translation-proof
hol4-replay
cakeml-program
capsule
machine
compose-e2e
replay-machine
fresh-revalidate
audit
mutations
clean
prove
publish-check
```

## 2. Keep Strict Failure Semantics

Use:

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

No mandatory stage may contain:

```bash
... || true
```

unless the failure is ONLY being recorded as a diagnostic and the stage status remains `BLOCKED`.

Do NOT convert missing proof evidence into warnings during `publish-check`.

## 3. Stage 01 — `pins`

Verify exact immutable identities for:

```text
MetaRocq upstream
MetaRocq-rs branch/commit
Peregrine
Peregrine CakeML backend proof branch/commit
CakeML
HOL4
scope manifest
compiler configuration
capsule schema
```

Fail if any proof-producing checkout is dirty.

Record:

```text
generated/peregrine-selfhost/stages/01-pins.json
```

## 4. Stage 02 — `clone`

Execute the exact Milestone-01 recursive clone/audit.

Required result:

```text
Peregrine exact detached commit
submodule sync/update --recursive complete
current pinned revision has mechanically confirmed empty submodule set
separate CakeML backend checkout pinned independently
```

Do NOT identify Git dependencies with Git submodules.

## 5. Stage 03 — `seed`

Resolve the MetaRocq producer in EXACT priority order:

```text
1. genuine MetaRocq-rs prebuilt MetaRocq executable artifact, IF available and exact
2. exact prebuilt Rocq + MetaRocq plugin environment already produced by MetaRocq-rs
3. one-time exact source build of the pinned MetaRocq environment
```

Record the selected seed binary/plugin/source identities.

The seed produces artifacts.

It is NOT the final semantic authority.

## 6. Stage 04 — `snapshot`

Materialize:

```text
exact Peregrine source module snapshot
complete proof-bearing declaration corpus
complete body-less assumption ledger
one replay job per proof certificate
```

Require the completeness theorem/check from Milestone 02.

Dropping one proof must invalidate the stage.

## 7. Stage 05 — `lambdabox`

Execute the MetaRocq self-hosting pipeline with the selected seed.

Required artifact:

```text
generated/peregrine-selfhost/peregrine-selfhost.ast
```

The root MUST reach:

```text
Peregrine.Pipeline.peregrine_pipeline
retained complete proof corpus
assumption ledger
proof replay runtime
capsule preparation state
```

Record exact LambdaBox identity.

## 8. Stage 06 — `candidate`

Use the exact prebuilt Peregrine executable as candidate producer:

```bash
peregrine cakeml \
  generated/peregrine-selfhost/peregrine-selfhost.ast \
  -o generated/peregrine-selfhost/cakeml/peregrine-selfhost.cml
```

Record producer digest/configuration and exact output bytes.

Status after this stage is:

```text
CANDIDATE_GENERATED
```

NOT:

```text
VERIFIED
```

## 9. Stage 07 — `translation-proof`

Build the exact Milestone-05 theorem chain:

```text
L_bytes -> L -> L_named -> K -> K_bytes
```

and require:

```text
PeregrineCakeMLPipelineCorrect
exact candidate serialization binding
Print Assumptions audit
```

Forbid:

```text
trust_coq_kernel
Admitted
vacuous post=True/obseq=True as correctness
stale candidate bytes
unproved parser/serializer identity
```

If this theorem is not present:

```text
BLOCK
```

## 10. Stage 08 — `hol4-replay`

Build the HOL4 theory that checks/reconstructs the complete retained proof replay.

Require a real HOL4 theorem for the exact complete corpus.

Audit:

```text
Thm.hyp
Tag.dest_tag
check_thm
```

Reject unexpected hypotheses/oracles.

## 11. Stage 09 — `cakeml-program`

Bind the exact proof-stage CakeML AST `K` to the exact HOL4 CakeML value:

```text
peregrine_selfhost_prog_def
```

Require exact parsing/serialization equality and the exact application semantics theorem.

Do NOT advance with only a successful CakeML parse.

## 12. Stage 10 — `capsule`

Construct the canonical Level-1 capsule and include it INSIDE the CakeML program.

Require:

```text
actual proof/article bytes
exact dependency manifest
source/proof/assumption identities
LambdaBox identity
CakeML identity
HOL4/CakeML pins
approved assumptions
```

Build/check:

```text
PeregrineEmbeddedCapsuleCorrect
```

## 13. Stage 11 — `machine`

Inside HOL4:

```text
exact K
  -> eval_cake_compile_x64
  -> exact M
  -> compile_correct/x64
  -> peregrine_selfhost_machine_correct
```

Record the exact theorem-bound machine-code representation.

Do NOT silently substitute externally linked ELF bytes.

## 14. Stage 12 — `compose-e2e`

Construct/check:

```text
PeregrineSelfHostE2E
```

The theorem must connect:

```text
complete source/proof corpus
complete proof replay
source -> LambdaBox
LambdaBox -> CakeML
CakeML program semantics
embedded capsule correspondence
in-logic CakeML compilation
machine refinement
```

This is the PRIMARY publication theorem.

## 15. Stage 13 — `replay-machine`

Execute the exact theorem-bound runtime command(s):

```text
VerifyAllRetainedProofs
ExposeCertificate
```

and compare the observed state to the theorem-predicted exact state.

The runtime report is recursive confirmation.

It is not the foundational proof.

## 16. Stage 14 — `fresh-revalidate`

Run Milestone 08 in a separate fresh HOL4/CakeML root.

Required output:

```text
FreshPeregrineSelfHostE2E
```

with the same exact artifact/specification identities and approved assumption policy.

If fresh replay cannot rebuild the theorem:

```text
PUBLICATION = BLOCKED
```

## 17. Stage 15 — `audit`

Generate the final human-readable trust report containing:

```text
exact source pins
proof corpus completeness
assumption ledger
forbidden proof shortcuts scan
Peregrine translation theorem
HOL4 replay theorem
CakeML program theorem
capsule correspondence theorem
CakeML compilation theorem
machine theorem
final E2E theorem
fresh E2E theorem
theorem hypotheses/tags/oracles
packaging boundary
```

Do NOT summarize a conditional theorem as unconditional.

## 18. Stage 16 — `mutations`

Run the complete negative suite.

At minimum mutate:

```text
one source proof
one proof body
one assumption
one LambdaBox node
one CakeML node
one candidate byte
one capsule article byte
Peregrine backend revision
CakeML revision
HOL4 revision
compiler target config
machine-code representation
runtime capsule output
fresh-replay dependency manifest
```

The final theorem or fresh theorem must fail for every semantically relevant mutation.

## 19. `prove` Executes Every Mandatory Proof-Producing Stage

Required order:

```text
pins
clone
seed
snapshot
lambdabox
candidate
translation-proof
hol4-replay
cakeml-program
capsule
machine
compose-e2e
replay-machine
fresh-revalidate
audit
```

`prove` MUST stop at the first missing theorem/identity.

No stage can be skipped merely because an old file exists.

Content-addressed caches are allowed only if their complete semantic dependency keys match.

## 20. `publish-check` Is the ONLY Release Authorization Command

Implement:

```bash
./tools/peregrine-selfhost-e2e.sh publish-check
```

It MUST require:

```text
pins exact/clean                         PASS
Peregrine clone/submodules               PASS
MetaRocq seed provenance                 PASS
source/proof completeness                PROVED
assumption classification                PASS
source -> LambdaBox                      PROVED
LambdaBox -> CakeML                      PROVED
candidate/proof AST identity             PROVED
complete HOL4 proof replay               PROVED
CakeML application semantics             PROVED
embedded capsule correspondence          PROVED
in-logic CakeML compilation              PROVED
machine refinement                       PROVED
unified PeregrineSelfHostE2E             PROVED
HOL4 hypothesis/oracle audit             PASS
runtime self-replay                      THEOREM-CONSISTENT
fresh independent HOL4 revalidation      PROVED
mutation suite                            PASS
release manifest                          EXACT
```

A missing stage is:

```text
BLOCKED
```

never implicit `PASS`.

## 21. Preserve Progress Through Stackable PRs

Use additive stacked branches:

```text
docs/selfhost-bootstrap-04-runtime-audit
  -> docs/peregrine-selfhost-01-source-bootstrap
     -> docs/peregrine-selfhost-02-cakeml-certificate
        -> docs/peregrine-selfhost-03-independent-replay
```

For implementation, create equivalent code branches from the latest accepted implementation layer.

When a proof fails:

```text
DO NOT reset to an old branch
DO NOT force-push away the failed work
DO NOT merge a stale historical branch wholesale
```

Instead:

1. fix the earliest failing semantic layer;
2. commit the fix on the current stack;
3. preserve the failed state in history;
4. regenerate only invalidated downstream artifacts;
5. update/open the next stacked PR.

## 22. Final Release Bundle

Generate:

```text
generated/peregrine-selfhost/final/
  README.md
  source-manifest.json
  proof-corpus-manifest.json
  assumption-ledger.json
  lambdabox-binding.json
  peregrine-cakeml-binding.json
  cakeml-program-binding.json
  embedded-capsule.bin
  capsule-manifest.json
  replay-theorem.txt
  cakeml-semantics-theorem.txt
  compile-theorem.txt
  machine-theorem.txt
  final-e2e-theorem.txt
  final-e2e-theorem-tags.txt
  fresh-e2e-theorem.txt
  fresh-e2e-theorem-tags.txt
  runtime-replay-report.json
  packaging-boundary.md
  environment.txt
  SHA256SUMS
```

This bundle makes every exact input/theorem inspectable.

It does NOT replace the theorem objects themselves.

## Completion Gate

The overall instruction set is successfully executed only when:

```text
./tools/peregrine-selfhost-e2e.sh publish-check
```

succeeds from a clean checkout AND the final audit bundle contains both:

```text
PeregrineSelfHostE2E
FreshPeregrineSelfHostE2E
```

for the same exact theorem-bound machine artifact/capsule state.

Until then, use the precise status:

```text
architecture specified
implementation partially mechanized
remaining proof obligations explicit
final E2E theorem NOT YET CLOSED
```

## References

### MetaRocq

- Official MetaRocq build/install instructions: https://github.com/MetaRocq/metarocq/blob/9.1/INSTALL.md
- Official architecture, quotation, SafeChecker and erasure overview: https://github.com/MetaRocq/metarocq/blob/9.1/README.md

### Peregrine

- Official Peregrine development/build instructions: https://github.com/peregrine-project/peregrine-tool/blob/master/doc/dev.md
- Official command documentation: https://github.com/peregrine-project/peregrine-tool/blob/master/doc/cmds.md
- Exact Peregrine pipeline source: https://github.com/peregrine-project/peregrine-tool/blob/d768b83ffa7dab35b8d72241f0570b5bb6aedae9/theories/Pipeline.v
- Official CakeML backend: https://github.com/peregrine-project/cakeml-backend

### CakeML

- Exact theorem-producing compiler API: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/cv_translator/eval_cake_compileLib.sig
- Exact x64 compilation example: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/examples/compilation/x64/helloCompileScript.sml
- Exact x64 machine-correctness proof example: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/examples/compilation/x64/proofs/helloProofScript.sml

### HOL4

- Official HOL4 repository: https://github.com/HOL-Theorem-Prover/HOL
- Official OpenTheory theorem/article interface: https://github.com/HOL-Theorem-Prover/HOL/blob/40dd5b03de658f4bd9e3f4225fb0f1602ac90467/src/opentheory/postbool/OpenTheoryIO.sig
- Official OpenTheory reader interface: https://github.com/HOL-Theorem-Prover/HOL/blob/40dd5b03de658f4bd9e3f4225fb0f1602ac90467/src/opentheory/reader/OpenTheoryReader.sig
