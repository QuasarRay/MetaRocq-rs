# 11 — Milestone 01 — Freeze the E2E Claim, Scope, and Trusted Base

> **UNIFIED SEQUENCE STEP 11 OF 22 — METAROCQ SOURCE/SPECIFICATION -> MACHINE REFINEMENT.**  
> Reused from `docs/selfhost-bootstrap/01-trust-and-e2e-completion-criteria.md` on `docs/selfhost-bootstrap-04-runtime-audit`. The original manual remains preserved. This unified copy is downstream of the verified Peregrine foundation from Steps 01–10.

## Mandatory prerequisite from Part I

Before starting this MetaRocq half, REQUIRE the exact outputs of unified Steps 01–10:

```text
Peregrine source identity
+ complete retained Peregrine proof/replay corpus
+ proved Peregrine LambdaBox -> CakeML bridge
+ exact CakeML program theorem
+ exact Peregrine machine-code theorem
+ independently replayable HOL4 proof/certificate state
```

Do NOT substitute an unverified native Peregrine binary or CI success for those results.

## Objective

Before changing source code, define exactly what the final build is allowed to claim.

The target is:

> The exact final MetaRocq machine image refines the exact pinned MetaRocq source snapshot, and the build has independently replayed and machine-checked every in-scope PCUIC proof/specification required by that source snapshot, with HOL4 as the final build-time proof authority.

Do NOT weaken this into “MetaRocq contains proofs”, “Rocq accepted the files”, “CakeML is verified”, or “the hashes match”. Those are necessary intermediate facts, not the final E2E statement.

## 1. Create one machine-readable scope manifest

Create:

```text
spec/selfhost-e2e-scope.json
```

It MUST identify, by immutable commit and file digest:

1. MetaRocq source commit;
2. PCUIC syntax, typing, universes, reduction, conversion/cumulativity, SafeChecker, erasure and quotation roots;
3. every source directory whose proof-bearing declarations are in scope;
4. Peregrine and the CakeML backend source commit;
5. CakeML source commit;
6. HOL4 source commit;
7. target architecture and CakeML compiler configuration;
8. the final entrypoint that is self-reflected and extracted.

Reuse the repository's existing pins where possible. At the baseline used by this manual the important pins are:

```text
MetaRocq:
  7197056adbb9c15288b4c8d43407bf25786f723e

Peregrine:
  d768b83ffa7dab35b8d72241f0570b5bb6aedae9

HOL4:
  40dd5b03de658f4bd9e3f4225fb0f1602ac90467
```

The existing CakeML selfhost contract also references the pinned CakeML compiler source used by the project. Move that identity into the same E2E scope manifest rather than allowing multiple independent pins.

## 2. Define the final theorem shape before implementation

Create a HOL4 theory reserved for the final composition, for example:

```text
formal/hol4/selfhost/MetaRocqE2EScript.sml
```

The final theorem SHOULD have the conceptual shape:

```text
MetaRocqE2E
  exact_source_snapshot
  exact_complete_proof_corpus
  exact_lambdabox
  exact_cakeml_program
  exact_machine_image
```

and imply BOTH:

```text
AllInScopeMetaRocqProofsValid exact_source_snapshot exact_complete_proof_corpus
```

and:

```text
MachineRefines
  exact_machine_image
  (MetaRocqSpecification exact_source_snapshot exact_complete_proof_corpus)
```

The theorem MUST bind the exact artifacts used in the build. Do not prove only a generic theorem and then leave the concrete source/image association to JSON.

## 3. Make “complete proof corpus” a theorem obligation

The existing selfhost branch already retains proof-bearing constants and a separate assumption ledger.

Extend this into an explicit completeness theorem:

```text
every_in_scope_proof_bearing_declaration source_snapshot
  <->
member complete_retained_certificate_corpus
```

The important property is bidirectional:

- every required source proof appears in the corpus;
- every retained proof has a source declaration identity.

A count equality alone is insufficient. Bind declarations by stable kernel name plus statement/proof digest.

## 4. Keep the assumption ledger separate

Never silently convert a body-less declaration, axiom, normalization postulate, FFI assumption, or hardware assumption into an ordinary proved theorem.

The final pipeline MUST preserve:

```text
source assumption
  -> retained assumption
  -> extraction assumption
  -> HOL4 theorem dependency
  -> final E2E assumption ledger
```

The MetaRocq SafeChecker documentation explicitly states that its verified checker relies on a strong-normalization postulate. Therefore the final build must either independently discharge the corresponding assumption or expose it in the final theorem dependency report. Do not hide it behind a Boolean “checker passed”.

## 5. Establish the trusted-computing-base policy

For this project, treat the following as UNTRUSTED producers unless the final theorem says otherwise:

- the ordinary Rocq kernel;
- MetaRocq's plugin execution;
- generated `.vo` files;
- Peregrine executables;
- the standalone CakeML compiler executable;
- shell/Python orchestration;
- GitHub Actions;
- hashes and manifests.

They may produce inputs and evidence, but they do not authorize the final claim.

The intended build-time authority is the pinned HOL4 kernel and the HOL4 theorem graph it constructs.

Document remaining foundational assumptions explicitly:

- HOL4 logic and kernel implementation;
- the CakeML HOL4 models/theorems actually used;
- target ISA/machine/FFI assumptions;
- any PCUIC metatheory assumption not independently discharged.

## 6. Add fail-closed publication gates

Create a single command, eventually:

```bash
./tools/selfhost-e2e.sh verify
```

It MUST return success only if all of the following exist and are checked:

- exact source-snapshot manifest;
- complete proof-corpus theorem/evidence;
- exact assumption ledger;
- exact LambdaBox binding;
- exact Peregrine-to-CakeML refinement theorem;
- exact in-logic CakeML compilation theorem;
- exact machine-image digest;
- final HOL4 E2E theorem;
- theorem-tag/oracle/assumption audit.

If any stage is missing, the result MUST be BLOCKED, not “partial success”.

## 7. Never accept these substitutes

Reject the final build if the only evidence for any stage is:

- a process exit code;
- a generated file existing;
- matching hashes without a semantic theorem;
- `Admitted`, `admit`, `Axiom` introduced to close a missing proof;
- an untracked HOL4 oracle;
- a Rocq theorem used only because Rocq accepted it;
- a compiler output used only because the compiler executable emitted it.

## Completion gate

Milestone 01 is complete only when the repository contains:

- the immutable E2E scope manifest;
- a documented final HOL4 theorem signature/contract;
- an explicit TCB and assumption policy;
- a fail-closed list of mandatory proof artifacts;
- no claim that the E2E theorem is already proved.

## References

### MetaRocq

- Architecture, PCUIC metatheory, SafeChecker, erasure and quotation overview: https://github.com/MetaRocq/metarocq/blob/9.1/README.md
- Installation/package decomposition, including quotation of typing derivations: https://github.com/MetaRocq/metarocq/blob/9.1/INSTALL.md
- Correct and Complete Type Checking and Certified Erasure for Coq, in Coq: https://dl.acm.org/doi/10.1145/3706056

### CakeML

- CakeML repository: https://github.com/CakeML/cakeml
- Verified CakeML Compiler Backend: https://cakeml.org/jfp19.pdf
- Concrete x64 E2E proof composition example: https://github.com/CakeML/cakeml/blob/master/examples/compilation/x64/proofs/helloProofScript.sml

### HOL4

- HOL4 logic/documentation index: https://hol-theorem-prover.org/docs/trindemossen-2/
- HOL4 developer/kernel documentation: https://hol-theorem-prover.org/docs/trindemossen-2/Developers/
- HOL4 repository: https://github.com/HOL-Theorem-Prover/HOL
