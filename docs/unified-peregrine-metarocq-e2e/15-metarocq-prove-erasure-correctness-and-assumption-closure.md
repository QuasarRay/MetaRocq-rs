# 15 — Milestone 05 — Close Erasure Correctness and the Assumption Ledger

> **UNIFIED SEQUENCE STEP 15 OF 22 — METAROCQ SOURCE/SPECIFICATION -> MACHINE REFINEMENT.**  
> Reused from `docs/selfhost-bootstrap/05-erasure-correctness-and-assumption-closure.md` on `docs/selfhost-bootstrap-04-runtime-audit`. The original manual remains preserved. This unified copy is downstream of the verified Peregrine foundation from Steps 01–10.

## Objective

Bind the self-reflective MetaRocq source state to the exact LambdaBox artifact with a theorem that preserves the properties needed by the final E2E claim, while making every undischarged logical assumption explicit.

This milestone MUST prevent a common failure mode:

```text
MetaRocq theorem is valid in Rocq
        |
        v
erasure/extraction succeeds
        |
        v
generated program exists
```

without a theorem that the generated program preserves the relevant source semantics.

The target is instead:

```text
exact source/proof state
        |
        | MetaRocq erasure correctness
        v
exact LambdaBox state
        |
        +-- complete retained proof corpus preserved
        +-- assumptions preserved
        +-- self-replay behavior preserved
```

## 1. Identify the exact upstream erasure theorem used by this build

Do not cite “MetaRocq erasure is verified” generically.

At the pinned MetaRocq revision:

```text
7197056adbb9c15288b4c8d43407bf25786f723e
```

record the exact theorem(s), source file(s), and dependencies that justify the PCUIC→erased-language step used by the selfhost program.

Add those identities to:

```text
spec/selfhost-e2e-scope.json
```

and to a machine-readable theorem manifest such as:

```text
generated/e2e/erasure-theorems.json
```

The manifest is evidence transport only; the theorem itself must remain kernel-checked.

## 2. Prove the retained payload is computational, not erased proof matter

For every field required by runtime replay, prove or inspect that it is ordinary data in `Type` and survives erasure.

The retained payload should include:

```text
quoted PCUIC statement AST
quoted PCUIC proof/body AST
certificate identity
assumption identity
dependency identity
replay-job description
source/proof digests
```

Do not rely on a theorem proof object in `Prop` remaining present after extraction.

The intended pattern is:

```text
proof : P                       -- logical evidence
quote proof : PCUIC.term        -- executable syntax data
retain (quote proof)            -- survives extraction
```

## 3. Define the exact observable relation across erasure

Define a relation/record that captures only the semantic facts required by later stages.

For example:

```text
Record selfhost_erasure_observation := {
  observed_certificate_ids : list digest;
  observed_assumption_ids : list digest;
  observed_replay_ids : list digest;
  observed_entrypoint_id : digest;
  observed_runtime_contract_id : digest;
}.
```

Prove that the source-side observation and erased-program observation agree for the exact selfhost root.

Do NOT use file hash equality as the proof. Hashes may bind artifacts after the theorem exists; they cannot replace the theorem.

## 4. Audit the SafeChecker assumptions

The pinned MetaRocq SafeChecker is proved correct/complete relative to PCUIC but its architecture relies on a strong-normalization postulate for the verified reduction/conversion machinery.

Additionally, the current repository's own `spec/upstream.lock.json` records a specific warning about:

```text
safechecker-plugin/theories/Extraction.v
fake_abstract_guard_impl_properties
```

Treat this as a hard gate.

For every checker/guard/normalization assumption used by the selfhost path:

1. name the exact declaration;
2. record its source file and statement;
3. classify it:
   - proved;
   - imported foundational assumption;
   - temporary implementation assumption;
   - forbidden;
4. record where it appears in the final HOL4 dependency chain;
5. reject publication if a forbidden or unclassified assumption remains.

## 5. Remove fake/placeholder guard evidence from the publication path

If the extraction path still relies on a declaration equivalent to:

```text
fake_abstract_guard_impl_properties
```

you have two choices:

### Preferred

Provide a concrete guard implementation and prove the properties required by the checker/extraction theorem.

### Temporary research path

Keep the assumption explicit and mark the final theorem conditional on it.

Do NOT:

- rename the fake evidence;
- hide it in generated code;
- convert it into a Boolean;
- treat successful extraction as discharge of the premise.

The final “no-Rocq-trust” publication target is not complete while such implementation assumptions are silently trusted.

## 6. Build a transitive assumption ledger

Extend the existing source assumption ledger into a transitive E2E ledger.

For each final theorem dependency, collect:

```text
source assumptions
PCUIC metatheory assumptions
SafeChecker assumptions
erasure assumptions
Peregrine assumptions
CakeML assumptions
HOL4 axioms/oracles
ISA / FFI / runtime assumptions
```

Generate:

```text
generated/e2e/assumption-ledger.json
generated/e2e/assumption-ledger.txt
```

Each record SHOULD include:

```json
{
  "name": "...",
  "origin": "...",
  "statement_digest": "...",
  "classification": "proved|foundational|temporary|forbidden",
  "used_by": ["..."],
  "discharge_status": "..."
}
```

## 7. Add source scanning only as a secondary guard

Run source scans for obvious proof holes:

```bash
grep -RInE '\b(Admitted|admit|Axiom|Parameter|Parameters)\b' \
  metatheory/original-selfhost \
  .aegis/references/metarocq \
  | tee generated/e2e/source-assumption-scan.txt
```

But do NOT equate “grep found nothing” with logical closure.

The authoritative result is the dependency/assumption information attached to the final checked theorem.

## 8. Prove the exact extracted entrypoint corresponds to the exact source root

Bind:

```text
ReconciledSelfHostEntrypoint.reconciled_selfhost_entrypoint
```

to the exact generated LambdaBox/Peregrine input.

Record:

```bash
sha256sum generated/original-selfhost/reconciled-selfhost.ast \
  > generated/e2e/lambdabox.sha256
```

Then ensure the source-to-erased theorem is instantiated for the exact entrypoint used to produce that artifact.

Do not prove correctness of a generic function while compiling a different wrapper.

## 9. Negative tests

The milestone is not complete until all of these fail closed:

- replace the retained proof corpus with `[]`;
- drop one assumption;
- use a different source entrypoint;
- use a different erasure configuration;
- introduce a new `Axiom` in an in-scope module;
- replace concrete guard evidence with the known fake placeholder;
- mutate the LambdaBox artifact after theorem generation.

## Completion gate

Milestone 05 is complete only when:

- the exact erasure theorem(s) used by the build are pinned and instantiated;
- the retained certificate/replay data are proved to survive the relevant erasure semantics;
- all checker/guard/normalization assumptions are explicit;
- fake/placeholder evidence cannot silently enter the publication path;
- the source root and exact LambdaBox artifact are cryptographically bound to the proof record;
- no later stage is allowed to claim unconditional E2E correctness while an undischarged conditional premise remains.

## References

### MetaRocq

- MetaRocq overview of verified SafeChecker and erasure: https://github.com/MetaRocq/metarocq/blob/9.1/README.md
- MetaRocq erasure theories: https://github.com/MetaRocq/metarocq/tree/9.1/erasure/theories
- MetaRocq SafeChecker theories: https://github.com/MetaRocq/metarocq/tree/9.1/safechecker/theories
- Correct and Complete Type Checking and Certified Erasure for Coq, in Coq: https://dl.acm.org/doi/10.1145/3706056

### CakeML

- CakeML verified compiler backend paper, including semantic preservation through the compiler pipeline: https://cakeml.org/jfp19.pdf
- CakeML repository: https://github.com/CakeML/cakeml
- CakeML x64 E2E proof composition pattern: https://github.com/CakeML/cakeml/blob/master/examples/compilation/x64/proofs/helloProofScript.sml

### HOL4

- HOL4 official documentation: https://hol-theorem-prover.org/docs/trindemossen-2/
- HOL4 logic description: https://hol-theorem-prover.org/docs/trindemossen-2/Description/
- HOL4 developer/kernel documentation: https://hol-theorem-prover.org/docs/trindemossen-2/Developers/
