# 10 — Final Reuse Report: What Already Existed, What Was Reused, and What Had to Be Added

## Objective

Record exactly how much of this instruction set REUSES the previous MetaRocq self-hosting/HOL4 architecture, and exactly which parts are genuinely NEW Peregrine-specific work.

This report MUST distinguish:

```text
INSTRUCTION ARCHITECTURE COMPLETE
!=
ALL FORMAL THEOREMS IMPLEMENTED
```

The existence of these instructions does NOT mean that the final `PeregrineSelfHostE2E` theorem already exists.

## 1. Foundational Manual Reused WITHOUT Duplication

The previous MetaRocq E2E manual already contained 12 authoritative milestones:

```text
01 trust and E2E completion criteria
02 pinned laptop toolchain
03 complete source/proof corpus
04 self-reflection and LambdaBox retention
05 erasure correctness and assumption closure
06 Peregrine -> CakeML semantic boundary
07 HOL4 independent replay authority
08 CakeML in-logic machine compilation
09 unified E2E HOL4 theorem
10 recursive machine self-replay
11 local operation/debugging/recovery
12 final audit/publication gate
```

Result:

```text
FOUNDATIONAL MILESTONES REUSED:        12 / 12
FOUNDATIONAL MILESTONES REIMPLEMENTED:  0 / 12
```

Therefore the new Peregrine collection is a DELTA over the previous manual, NOT a replacement.

## 2. Existing Peregrine/HOL4 Implementation Scaffolding Reused

PR #30 already contained reusable implementation seams:

```text
1. metatheory/peregrine-selfhost/*
   source manifest / snapshot / proof corpus / extraction root

2. tools/peregrine_selfhost_pipeline.sh
   exact producer path + prebuilt-toolchain preference

3. formal/hol4/PeregrineGeneratedCompileScript.sml
   serialized CakeML input
   -> HOL-side parser
   -> exact CakeML program
   -> eval_cake_compile_x64

4. formal/hol4/PeregrineSelfHostContractScript.sml
   fail-closed HOL4 theorem/tag qualification scaffold

5. cakeml/peregrine-selfhost/CertificateRuntime.sml
   certificate runtime data carrier

6. spec/peregrine-selfhost-e2e.json
   explicit trust boundary + required obligation ledger

7. docs/adr/0016-peregrine-selfhost-cakeml-hol4.md
   authority model + non-circular certificate design
```

These implementation seams are REUSED by Milestones 06–09.

Do NOT invent a second certificate-runtime architecture.

## 3. New Peregrine Delta Milestones Added

This directory adds 11 numbered delta milestones:

```text
00 reuse map and stronger target
01 clone/pin/submodule/source audit
02 build Peregrine selfhost LambdaBox + replay corpus
03 bootstrap with prebuilt MetaRocq seed
04 prebuilt Peregrine -> CakeML candidate
05 close real Peregrine -> CakeML proof gap
06 exact CakeML/HOL4 machine attestation
07 embed non-circular proof capsule
08 fresh HOL4 independent revalidation
09 one-command runbook/publication gate
10 reuse/new-work report
```

These files SPECIALIZE the old 12-milestone manual.

They do NOT duplicate it.

## 4. Count-Based Reuse Classification

### Primarily reuse/specialization — Milestones 00 through 04

These apply existing architecture to the exact Peregrine target:

```text
00 classify reuse and freeze the stronger target
01 freeze exact Peregrine source/dependencies
02 specialize complete proof retention to Peregrine
03 specialize bootstrap seed selection
04 specialize the prebuilt Peregrine candidate producer
```

Count:

```text
5 / 11 delta milestones = primarily reuse/specialization
```

### Genuinely NEW formal obligations — Milestones 05 through 08

These exist because the stronger requested target is NOT already closed by the previous manual or by the audited upstream repositories:

```text
05 close the missing complete Peregrine -> CakeML theorem
06 instantiate exact Peregrine application semantics + exact CakeML machine theorem
07 embed a portable non-circular proof capsule + prove correspondence
08 make a fresh HOL4 instance reconstruct the outer E2E theorem
```

Count:

```text
4 / 11 delta milestones = primarily new formal work
```

### Integration/reporting — Milestones 09 through 10

```text
09 final staged runbook/publication gate
10 this reuse/new-work report
```

Count:

```text
2 / 11 delta milestones = integration/reporting
```

## 5. Count-Based Overall Reuse View

If you count the old 12 foundational milestones together with the 11 Peregrine delta milestones:

```text
TOTAL MILESTONE UNITS: 23

12 old foundational milestones reused directly
 5 new delta milestones primarily reuse/specialize them
 4 new delta milestones contain genuinely new formal obligations
 2 new delta milestones integrate/report
```

Therefore, on a SIMPLE MILESTONE-COUNT basis:

```text
DIRECT REUSE + SPECIALIZATION:
  17 / 23 ~= 73.9%

GENUINELY NEW FORMAL-OBLIGATION MILESTONES:
   4 / 23 ~= 17.4%

INTEGRATION / REPORTING:
   2 / 23 ~= 8.7%
```

IMPORTANT:

This is a DOCUMENT-ARCHITECTURE metric.

It is NOT an effort-weighted metric.

The 4 genuinely new formal milestones are disproportionately difficult and contain most of the remaining proof risk.

## 6. Reuse by the User's Five Requested Phases

### Requested Phase 1 — separate Peregrine branch + recursive submodules

Status:

```text
MOSTLY NEW OPERATIONAL SPECIALIZATION
```

Already reused:

- immutable source pinning;
- separate dependency checkout policy;
- source identity recording;
- fail-closed dirty-tree checks.

New Peregrine-specific work:

- exact Peregrine commit;
- `--recurse-submodules` cloning policy;
- mechanical confirmation that the pinned revision currently has NO `.gitmodules` / gitlinks;
- separate official CakeML backend checkout because it is NOT a Peregrine submodule.

Documented in:

```text
01-clone-pin-and-audit-peregrine.md
```

### Requested Phase 2 — one Peregrine LambdaBox containing all proof replays

Status:

```text
ARCHITECTURE HEAVILY REUSED
PEREGRINE SCOPE SPECIALIZED
```

Reused:

- source quotation as data;
- proof retention as computational Type-level data;
- separate assumption ledger;
- replay-job completeness;
- LambdaBox retention pattern;
- source/proof completeness gate.

New:

- exact Peregrine module scope;
- exact Peregrine executable root;
- complete Peregrine proof-corpus specialization;
- one retained replay job per in-scope proof;
- requirement that the final LambdaBox root keeps both Peregrine and its replay state reachable.

Documented in:

```text
02-build-peregrine-selfhost-lambdabox.md
```

### Requested Phase 3 — execute with prebuilt MetaRocq, preferring MetaRocq-rs artifacts

Status:

```text
NEW SEED-RESOLUTION POLICY BUILT ON EXISTING TOOLCHAIN REUSE
```

The existing project already reused pinned Rocq/MetaRocq environments.

The new exact priority is:

```text
1. genuine MetaRocq-rs MetaRocq binary artifact, IF one exists and matches the exact expected identity

2. exact prebuilt Rocq + MetaRocq plugin environment already materialized by MetaRocq-rs

3. exact one-time source build of the pinned MetaRocq environment
```

The seed is a bootstrap producer.

It is NOT final semantic proof evidence.

Documented in:

```text
03-bootstrap-with-prebuilt-metarocq-seed.md
```

### Requested Phase 4 — use prebuilt Peregrine to produce CakeML

Status:

```text
MOSTLY NEW PEREGRINE-SPECIFIC PRODUCER BINDING
```

New requirements:

- exact prebuilt Peregrine executable identity;
- exact `.ast` input identity;
- exact `.cml` candidate bytes/configuration;
- candidate != proof separation;
- exact candidate bytes bound to the theorem-stage CakeML AST;
- exact theorem-stage configuration equals candidate-generation configuration.

Documented in:

```text
04-prebuilt-peregrine-to-cakeml.md
05-close-peregrine-cakeml-proof-gap.md
```

### Requested Phase 5 — exact machine theorem + proof artifacts in the executable + future HOL4 replay

Status:

```text
LARGEST AMOUNT OF NEW FORMAL WORK
```

The old manual ALREADY provided the reusable architecture for:

```text
HOL4 as final authority
CakeML in-logic compilation
compile_correct composition
exact target-machine theorem
recursive runtime replay
final publication audit
```

The stronger Peregrine target requires NEW formal work:

1. a COMPLETE Peregrine -> CakeML pipeline theorem for the exact self-host program;
2. exact candidate bytes <-> exact proved CakeML AST correspondence;
3. exact Peregrine application/replay semantics connected to the CakeML program;
4. exact program-specific `eval_cake_compile_x64` theorem;
5. exact specialization of CakeML `compile_correct` + x64 configuration theorems;
6. an embedded Level-1 proof capsule carrying real replayable HOL4/OpenTheory proof material;
7. a HOL4 theorem proving the exact CakeML program exposes EXACTLY that capsule;
8. a final composed `PeregrineSelfHostE2E` theorem;
9. a FRESH second HOL4 instance reconstructing the core theorem and recompiling the exact CakeML program;
10. if one physical file must also contain the OUTER machine theorem, a separate proved container/loader projection theorem.

Documented in:

```text
05-close-peregrine-cakeml-proof-gap.md
06-cakeml-hol4-exact-machine-attestation.md
07-embed-non-circular-proof-capsule.md
08-future-hol4-independent-revalidation.md
09-one-command-e2e-runbook-and-publication-gate.md
```

## 7. Why "Most Architecture Was Reused" Does NOT Mean "Most Proof Effort Is Finished"

The reusable architecture answers questions such as:

```text
What are the trust boundaries?
Which exact artifacts must be shared between theorems?
How must proof corpus completeness be represented?
Why must proof data survive erasure?
Why must CakeML compile inside HOL4?
How must the final theorem compose?
How must assumptions/oracles be audited?
How must recursive self-replay avoid circularity?
How must publication fail closed?
```

Those questions are ALREADY answered.

The remaining hard work is narrower but deeper:

```text
prove the exact missing transformations
instantiate them for the exact self-hosted Peregrine program
bind exact bytes/ASTs/theorems together
prove the embedded capsule correspondence
reconstruct the whole chain in a fresh HOL4 instance
```

Therefore:

```text
ARCHITECTURAL DESIGN REUSE = VERY HIGH
REMAINING NEW FORMALIZATION SCOPE = NARROWER
REMAINING FORMALIZATION DIFFICULTY = STILL HIGH
```

## 8. What Was NOT Reimplemented

The new instruction stack deliberately does NOT create replacements for:

- MetaRocq quotation;
- PCUIC;
- MetaRocq SafeChecker;
- MetaRocq verified erasure;
- Peregrine's existing transformation framework;
- the existing verified `CompileCorrect.v` work;
- CakeML compiler correctness;
- CakeML x64 backend correctness;
- CakeML theorem-producing compiler evaluation;
- HOL4 kernel;
- HOL4 OpenTheory import/export;
- the existing MetaRocq-rs certificate/provenance structure;
- the existing PR #30 Peregrine selfhost scaffolding.

This is the most important reuse result.

The remaining work is COMPOSITION + MISSING PROOFS around the exact self-hosted program, not a rewrite of these foundations.

## 9. What Still Has to Be Implemented Before Publication Can Be Called E2E

The instruction set is complete.

The implementation is NOT yet complete until all of the following become real kernel-checked artifacts:

```text
[ ] complete Peregrine source/proof snapshot theorem
[ ] complete proof-replay theorem over the exact retained corpus
[ ] exact source -> LambdaBox refinement theorem
[ ] exact LambdaBox -> CakeML pipeline theorem
[ ] exact candidate bytes <-> proved CakeML AST theorem
[ ] exact CakeML application-semantics theorem
[ ] exact embedded capsule correspondence theorem
[ ] exact eval_cake_compile_x64 theorem for that same program
[ ] exact CakeML compile_correct/x64 machine theorem
[ ] one connected PeregrineSelfHostE2E theorem
[ ] machine runtime replay correspondence theorem
[ ] fresh independent HOL4 reconstruction theorem
[ ] mutation suite proving the publication gate is fail-closed
```

Optional stronger target:

```text
[ ] proved physical-container / loader projection theorem
    IF the OUTER exact-machine theorem itself must also be physically embedded
    in the same final executable file
```

## 10. Final Quantitative Summary

### Documentation architecture

```text
Previous foundational milestones reused:   12 / 12
Previous foundational milestones rewritten: 0 / 12

New Peregrine delta milestones:             11
  primarily reuse/specialization:            5
  primarily new formal work:                 4
  integration/reporting:                     2
```

### Simple combined milestone-count view

```text
reuse/specialization: 17 / 23 ~= 73.9%
new formal obligations: 4 / 23 ~= 17.4%
integration/reporting: 2 / 23 ~= 8.7%
```

### Formal-effort interpretation

Do NOT infer:

```text
17.4% new milestones
=> only 17.4% of the proof effort remains
```

The remaining new milestones contain the most technically difficult program-specific proof obligations.

A more accurate qualitative summary is:

```text
TRUST-CHAIN DESIGN:
  mostly reused and already specified

TOOLCHAIN / PRODUCER OPERATIONS:
  mostly reused with Peregrine-specific binding

NEW FORMAL THEORY:
  concentrated in four narrow but difficult areas

FINAL IMPLEMENTATION STATUS:
  blocked until those proof obligations are mechanized
```

## 11. Final Stack Preservation Report

The final documentation stack is:

```text
PR #31
docs/peregrine-selfhost-01-source-bootstrap
  => README + 00–03

PR #32
docs/peregrine-selfhost-02-cakeml-certificate
  => 04–07

PR #33
docs/peregrine-selfhost-03-independent-replay
  => 08–10 + README status update
```

The stack preserves progress incrementally.

No later PR rewrites the earlier milestone files.

The intended review order is:

```text
#31 -> #32 -> #33
```

## Final Status

```text
INSTRUCTION_SET = COMPLETE
REUSE_STRATEGY = EXPLICIT
STACKED_PR_HISTORY = PRESERVED

FINAL_PEREGRINE_E2E_THEOREM = NOT_YET_CLOSED
PUBLICATION = BLOCKED UNTIL THE EXPLICIT THEOREM OBLIGATIONS ARE PROVED
```

## References

### MetaRocq

- Official MetaRocq architecture, quotation, PCUIC, SafeChecker, verified erasure, and self-erasure overview: https://github.com/MetaRocq/metarocq/blob/9.1/README.md
- Official MetaRocq installation/package decomposition: https://github.com/MetaRocq/metarocq/blob/9.1/INSTALL.md
- Official MetaRocq erasure theories: https://github.com/MetaRocq/metarocq/tree/9.1/erasure/theories
- Official MetaRocq self-erasure test: https://github.com/MetaRocq/metarocq/blob/9.1/test-suite/self_erasure.v

### Peregrine

- Official Peregrine pipeline overview: https://github.com/peregrine-project/peregrine-tool/blob/master/doc/overview.md
- Exact pinned Peregrine pipeline source: https://github.com/peregrine-project/peregrine-tool/blob/d768b83ffa7dab35b8d72241f0570b5bb6aedae9/theories/Pipeline.v
- Official Peregrine CakeML backend repository: https://github.com/peregrine-project/cakeml-backend
- Existing verified LambdaBox -> CakeML compile proof baseline: https://github.com/peregrine-project/cakeml-backend/blob/5baed0b21618480b30711eb9df87e9bf00537372/theories/Backend/CompileCorrect.v

### CakeML

- Official CakeML repository: https://github.com/CakeML/cakeml
- Exact theorem-producing compiler evaluator API: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/cv_translator/eval_cake_compileLib.sig
- Exact x64 compiler wrapper: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/cv_translator/eval_cake_compile_x64Lib.sml
- Official exact-machine proof composition example using `compile_correct`: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/examples/compilation/x64/proofs/helloProofScript.sml

### HOL4

- Official HOL4 repository: https://github.com/HOL-Theorem-Prover/HOL
- Official theorem/article transport interface: https://github.com/HOL-Theorem-Prover/HOL/blob/40dd5b03de658f4bd9e3f4225fb0f1602ac90467/src/opentheory/postbool/OpenTheoryIO.sig
- Official OpenTheory import/export implementation: https://github.com/HOL-Theorem-Prover/HOL/blob/40dd5b03de658f4bd9e3f4225fb0f1602ac90467/src/opentheory/postbool/OpenTheoryIO.sml
- Official OpenTheory reader contract: https://github.com/HOL-Theorem-Prover/HOL/blob/40dd5b03de658f4bd9e3f4225fb0f1602ac90467/src/opentheory/reader/OpenTheoryReader.sig
