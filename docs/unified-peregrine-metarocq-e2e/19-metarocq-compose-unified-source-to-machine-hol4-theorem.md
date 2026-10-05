# 19 — Milestone 09 — Compose One Unified HOL4 Theorem from MetaRocq Source and Every Proof to Exact Machine Code

> **UNIFIED SEQUENCE STEP 19 OF 22 — METAROCQ SOURCE/SPECIFICATION -> MACHINE REFINEMENT.**  
> Reused from `docs/selfhost-bootstrap/09-unified-e2e-hol4-theorem.md` on `docs/selfhost-bootstrap-04-runtime-audit`. The original manual remains preserved. This unified copy is downstream of the verified Peregrine foundation from Steps 01–10.

## Required final theorem shape

The composed theorem MUST connect ALL of the following in one explicit theorem graph:

```text
pinned MetaRocq source + every in-scope specification/proof
  -> complete quoted/replayed PCUIC state
  -> verified erasure / retained LambdaBox state
  -> verified Peregrine LambdaBox->CakeML theorem from Part I
  -> exact CakeML program
  -> HOL4 theorem-producing CakeML compilation
  -> exact target machine image
```

The theorem graph MUST NOT replace any arrow with “tool succeeded”.

## Objective

Compose the previously separate correctness results into one HOL4 theorem graph whose root is the exact MetaRocq source/proof state and whose leaf is the exact machine-code image.

This milestone closes the central bootstrapping requirement:

> The exact machine image refines the exact self-reflective MetaRocq source/specification, and the exact source proof corpus was completely replayed and accepted by the HOL4-checked compilation/replay process.

Do NOT publish a set of unrelated “green” stages.

The theorem graph must compose.

## 1. Define the exact theorem dependencies

The final theorem must consume theorem objects equivalent to:

```text
T_scope
  exact source snapshot/corpus is complete

T_replay
  complete replay of exact source/proof corpus is accepted
  and implies AllInScopeProofsValid

T_erasure
  exact source/self-reflective state
  refines/preserves required observables in exact LambdaBox artifact

T_peregrine
  exact LambdaBox artifact
  refines exact CakeML program

T_cakeml_semantics
  exact CakeML program satisfies the self-reflective MetaRocq specification

T_compile
  exact CakeML program compiles in HOL4 to exact machine program

T_machine
  exact machine execution refines exact CakeML semantics
```

Every theorem must be instantiated for the SAME artifact identities.

## 2. Reject disconnected theorem graphs

These are insufficient:

```text
A: all MetaRocq proofs valid
B: some CakeML program compiles correctly
```

unless HOL4 proves that the program in B is exactly the result of the source/extraction/Peregrine chain covered by A.

Likewise this is insufficient:

```text
A: exact source erases correctly
B: exact machine image is compiler output
```

unless the CakeML program between A and B is theorem-bound on both sides.

Every intermediate node must be shared, not merely have matching human-readable names.

## 3. Create one canonical E2E artifact record

Inside HOL4 define or generate an immutable record containing identities of:

```text
MetaRocq source snapshot
quoted PCUIC environment
complete certificate corpus
assumption ledger
LambdaBox program
Peregrine backend/configuration
CakeML program
CakeML compiler configuration
machine program/image
```

Call it conceptually:

```text
exact_mr_e2e_artifacts
```

Theorems SHOULD be parameterized/instantiated through this record so a stale theorem cannot accidentally be combined with a newer artifact.

## 4. State the final source/proof specification explicitly

The specification should make the proof-replay requirement part of program meaning.

Conceptually:

```text
MetaRocqSpecification S C =
  SourceBehaviorCorrect S
  /\ CompleteCorpusFor S C
  /\ AllInScopeProofsValid S C
  /\ SelfReplayBehavior S C
  /\ AssumptionPolicySatisfied S
```

Then the machine theorem can target the entire specification rather than only the ordinary runtime behavior.

This makes “every proof was checked” an E2E semantic obligation, not an external build report.

## 5. Compose the proof in HOL4

In:

```text
formal/hol4/selfhost/MetaRocqE2EScript.sml
```

import only the exact checked theories produced by Milestones 07 and 08 and the exact source/Peregrine bridge theories.

The proof should structurally:

1. obtain exact source/corpus completeness;
2. obtain complete replay acceptance;
3. derive all in-scope proof validity;
4. specialize source→LambdaBox refinement;
5. specialize LambdaBox→CakeML refinement;
6. rewrite to the exact CakeML program definition;
7. apply the exact program semantics theorem;
8. apply the exact CakeML compile theorem;
9. apply the machine configuration theorem;
10. conclude machine refinement of the full MetaRocq specification.

Prefer theorem composition and rewriting over re-proving upstream facts.

## 6. Produce two final theorem forms

### Development theorem

During implementation, keep all explicit assumptions visible:

```text
|- AssumptionSet A
   ==>
   MetaRocqE2E exact_mr_e2e_artifacts
```

### Publication theorem

Only after the policy-approved premises are discharged or explicitly accepted:

```text
|- MetaRocqE2E exact_mr_e2e_artifacts
```

or, if unavoidable foundational premises remain:

```text
|- ExplicitFoundationalAssumptions F
   ==>
   MetaRocqE2E exact_mr_e2e_artifacts
```

Never print the conditional theorem as though it were unconditional.

## 7. The machine image must refine every specification/proof in scope

Interpret “machine code refines every proof” precisely.

A machine instruction does not literally execute a logical theorem as a theorem.

The E2E statement instead proves:

1. the complete source proof/specification corpus is valid under the replay semantics;
2. that validity is part of the exact self-reflective source specification;
3. the exact executable source state is transformed through proved refinement steps;
4. the exact machine program refines that full source specification.

Thus the final machine theorem transitively depends on the validity/completeness theorem for every in-scope source proof.

This is the correct formal meaning of:

```text
machine image refines MetaRocq source + all specified proofs
```

## 8. Bind theorem completion to exact content hashes

After HOL4 constructs the theorem, create an audit manifest:

```text
generated/e2e/final/
  theorem.txt
  theorem-dependencies.txt
  assumptions.txt
  artifacts.json
  SHA256SUMS
```

`artifacts.json` should include:

```json
{
  "metarocq_source_commit": "...",
  "source_snapshot_digest": "...",
  "proof_corpus_digest": "...",
  "assumption_ledger_digest": "...",
  "lambdabox_digest": "...",
  "peregrine_backend_commit": "...",
  "cakeml_commit": "...",
  "cakeml_program_digest": "...",
  "hol4_commit": "...",
  "machine_program_digest": "...",
  "final_theorem": "MetaRocqE2E..."
}
```

The hashes bind identity. The HOL4 theorem establishes semantics.

## 9. Audit the final theorem's hypotheses and tags

At build end, inspect:

```sml
Thm.hyp metarocq_e2e_thm
Tag.dest_tag (Thm.tag metarocq_e2e_thm)
```

Compare against the explicit allowlist.

Fail publication on:

- unexpected hypothesis;
- new axiom;
- unexpected oracle;
- source assumption not present in the ledger;
- different machine/program identity;
- stale theorem dependency.

Store the audit result as text for human review, but derive pass/fail from the theorem metadata and explicit policy.

## 10. Add a one-command final HOL4 build

Create:

```bash
./tools/selfhost-e2e.sh prove
```

It must execute, in order:

```text
verify pins
snapshot source
prove corpus completeness
regenerate LambdaBox
check erasure binding
run/verify Peregrine CakeML backend
construct exact CakeML HOL definition
replay/check complete proof state in HOL4
compile CakeML in HOL4
apply CakeML compiler correctness
compose final E2E theorem
audit assumptions/oracles
emit final manifest
```

No step may be skipped because a stale artifact already exists unless the artifact is content-addressed and its theorem dependency is verified to match exactly.

## 11. Add theorem-level mutation tests

Create controlled mutations and confirm that `MetaRocqE2E` cannot be produced:

- delete one source proof from the corpus;
- change one statement but preserve its name;
- change one proof body;
- introduce one new assumption;
- mutate the LambdaBox AST;
- mutate the CakeML AST;
- change Peregrine backend revision;
- change CakeML compiler revision;
- change x64 target config;
- mutate the machine-code representation;
- substitute an old theorem manifest.

These are stronger than unit tests because the final theorem itself must disappear/fail to build.

## 12. Keep CI subordinate to local theorem generation

GitHub Actions can reproduce:

```bash
./tools/selfhost-e2e.sh prove
```

but CI success is not the authority.

Your laptop must be able to generate the same theorem/artifact identities from a clean checkout.

CI only transports/reproduces the result.

## Completion gate

Milestone 09 is complete only when:

- the complete source/proof validity theorem is produced by HOL4;
- exact source→LambdaBox refinement is theorem-bound;
- exact LambdaBox→CakeML refinement is theorem-bound;
- exact CakeML semantics is theorem-bound;
- exact in-logic CakeML compilation is theorem-bound;
- exact target machine semantics is theorem-bound;
- all theorems compose in HOL4 to one final E2E theorem graph;
- the final theorem is audited for assumptions/oracles;
- mutating any intermediate exact artifact prevents theorem completion.

## References

### MetaRocq

- MetaRocq PCUIC metatheory, verified SafeChecker, erasure and quotation overview: https://github.com/MetaRocq/metarocq/blob/9.1/README.md
- MetaRocq package/install overview: https://github.com/MetaRocq/metarocq/blob/9.1/INSTALL.md
- Correct and Complete Type Checking and Certified Erasure for Coq, in Coq: https://dl.acm.org/doi/10.1145/3706056

### CakeML

- CakeML in-logic compiler evaluator API: https://github.com/CakeML/cakeml/blob/master/cv_translator/eval_cake_compileLib.sig
- x64 concrete compiler-evaluation theorem example: https://github.com/CakeML/cakeml/blob/master/examples/compilation/x64/helloCompileScript.sml
- x64 concrete machine-level correctness composition: https://github.com/CakeML/cakeml/blob/master/examples/compilation/x64/proofs/helloProofScript.sml
- Verified CakeML Compiler Backend: https://cakeml.org/jfp19.pdf

### HOL4

- HOL4 official documentation: https://hol-theorem-prover.org/docs/trindemossen-2/
- HOL4 logic description: https://hol-theorem-prover.org/docs/trindemossen-2/Description/
- HOL4 developer/kernel documentation: https://hol-theorem-prover.org/docs/trindemossen-2/Developers/
- HOL4 source repository: https://github.com/HOL-Theorem-Prover/HOL
