# 05 — Close the REAL Peregrine LambdaBox → CakeML Correctness Gap Before Using the Candidate as Proof Evidence

## Objective

Produce ONE theorem-backed chain showing that the exact self-hosted Peregrine LambdaBox program:

```text
L = generated/peregrine-selfhost/peregrine-selfhost.ast
```

is semantically related to the exact CakeML AST:

```text
K
```

whose serialization is exactly the prebuilt Peregrine candidate:

```text
generated/peregrine-selfhost/cakeml/peregrine-selfhost.cml
```

This milestone is NEW work.

The previous manual already defined the architecture, but the current upstream audit proves that you MUST NOT assume a complete ready-made E2E theorem exists.

## REUSE

Reuse:

```text
docs/selfhost-bootstrap/06-peregrine-cakeml-backend.md
```

for:

- version alignment;
- exact artifact binding;
- no unverified serialization hole;
- primitive/FFI ledger;
- semantic theorem requirement.

This file replaces ONLY the earlier assumption that the entire upstream Peregrine→CakeML theorem is readily available.

## 1. Freeze the Verified Compile-Correct Revision That Actually Exists

The audited official branch:

```text
peregrine-project/cakeml-backend
branch: verified-compile-correct
commit: 5baed0b21618480b30711eb9df87e9bf00537372
```

contains:

```text
theories/Backend/CompileCorrect.v
```

The upstream commit message describes the result as:

```text
verified lambda-box -> CakeML compilation
forward simulation
first-order functional fragment
closes by Qed
no admits / no custom axioms
```

with reported assumptions including functional extensionality / Rocq primitive foundations.

Pin this exact revision for the first proof attempt:

```bash
git -C .aegis/references/peregrine-cakeml-selfhost \
  checkout --detach 5baed0b21618480b30711eb9df87e9bf00537372

git -C .aegis/references/peregrine-cakeml-selfhost \
  diff --exit-code

test -s \
  .aegis/references/peregrine-cakeml-selfhost/theories/Backend/CompileCorrect.v
```

Record the commit in the selfhost lock manifest.

## 2. Do NOT Claim That Upstream Provides the Complete Pipeline Theorem Yet

At the audited source state:

```text
CompileCorrect.v      EXISTS on verified-compile-correct
PipelineCorrect.v     DOES NOT EXIST on that branch
```

Meanwhile current `main` documentation mentions:

```text
PipelineCorrect.v
verified_cakeml_pipeline_theorem
```

but the audited `main` tree does not contain the named file.

Therefore define:

```text
UPSTREAM_COMPILE_CORRECT = AVAILABLE
UPSTREAM_PIPELINE_CORRECT = MISSING
```

The final publication gate MUST remain BLOCKED until a complete local/upstream pipeline theorem is present and checked.

## 3. Do NOT Solve This by Trusting `trust_coq_kernel`

The convenience execution wrapper in the separate backend still contains:

```coq
Axiom trust_coq_kernel : forall conf p,
  pre (malfunction_pipeline conf) ...
```

This is allowed only as an execution shortcut for producing candidate output.

It is forbidden in the final proof path.

Your new theorem must receive/derive the actual preconditions.

## 4. Define the Exact Semantic Nodes of the Missing Composition

Do NOT attempt to prove a giant theorem in one step.

Name the exact intermediate values:

```text
L_bytes    exact serialized Peregrine LambdaBox artifact
L          exact deserialized/unserialized LambdaBox program
L_named    exact named/wellformed LambdaBox program after required transforms
K          exact CakeML AST
K_bytes    exact serialized CakeML candidate
```

Then close these edges independently:

```text
T1: deserialize_lambdabox L_bytes = L

T2: verified_middle_end L = L_named
    and semantics(L_named) refines semantics(L)

T3: compile L_named = K

T4: semantics(K) simulates/refines semantics(L_named)

T5: serialize_cakeml K = K_bytes

T6: K_bytes =
    bytes(generated/.../peregrine-selfhost.cml)
```

The final theorem is the composition of T1–T6.

## 5. Prefer the Logic-Level LambdaBox Value Over Re-Trusting the File Parser

The strongest path is:

```text
MetaRocq/Peregrine extraction theorem
   already knows exact LambdaBox value L
             |
             +--> serialize L = L_bytes
             |
             +--> proof pipeline consumes L directly
```

Then the prebuilt CLI candidate is checked for equality against the theorem-derived serialized output.

This avoids making the host file parser foundational.

If the file parser is used in the theorem path, its parser/deserializer correctness must become an explicit theorem obligation.

## 6. Reuse Peregrine's Verified Middle-End Transformations

The official Peregrine pipeline is built as a composition of transformations.

For every transform used by the exact CakeML configuration, record:

```text
transform name
precondition
postcondition
observational-equivalence/refinement theorem
exact configuration enabling it
```

Do NOT include an optional transform merely because the prebuilt CLI uses it by default.

Either:

- configure the CLI to use exactly the proved transform sequence; or
- extend the proof chain to cover the exact default configuration.

The candidate and theorem configurations MUST match.

## 7. Instantiate `CompileCorrect.v` for the Exact Used Fragment

The `verified-compile-correct` branch proves a forward-simulation result for a restricted functional fragment.

Before using it, prove that:

```text
L_named
```

satisfies every required fragment/wellformedness predicate.

The audited proof source restricts features such as:

- unsupported primitives;
- lazy/force;
- certain projections/cofix/evars;
- constructor/name constraints;
- small supported recursive/constructor shapes in the proof development.

Do NOT infer fragment membership from “Peregrine generated output.”

Prove it for the exact program.

If the self-hosted Peregrine program itself uses a construct outside the current `CompileCorrect.v` theorem's fragment:

```text
DO NOT weaken the program
DO NOT fake the proof

extend CompileCorrect.v
or add a semantics-preserving preprocessing theorem
```

until the exact selfhost program is covered.

## 8. Create a Local Pipeline-Correctness File Instead of Waiting on a Name

Create:

```text
metatheory/peregrine-selfhost/PeregrineCakeMLPipelineCorrect.v
```

Its job is to compose the exact existing verified pieces.

The theorem should have the conceptual form:

```coq
Theorem peregrine_selfhost_to_cakeml_correct :
  ExactPeregrineSelfHostInput L ->
  ExactCakeMLConfig cfg ->
  PipelinePreconditions L cfg ->
  CakeMLProgramOf L cfg = K ->
  ObservationalRefinement
    (LambdaBoxSemantics L)
    (CakeMLSemantics K).
```

Use the actual semantic relations/types from the pinned proof libraries.

Do NOT create a new informal relation named `ObservationalRefinement` merely to make the theorem easy.

The placeholder above describes the required meaning.

## 9. Prove the Exact Candidate Serialization Binding

After obtaining `K`, prove or independently check:

```text
CakeMLSerialize K
=
candidate_cml_bytes
```

The separate backend contains CakeML serialization/deserialization formalization.

Use it.

If the existing serializer theorem is incomplete, add the missing round-trip theorem for the exact subset used by `K`.

Do NOT accept a string comparison generated by the same untrusted executable as the only evidence.

## 10. Audit `Print Assumptions` for Every New Rocq Theorem

For:

```text
compile_correct
peregrine_selfhost_to_cakeml_correct
serializer/deserializer round-trip theorem
exact candidate binding theorem
```

record:

```coq
Print Assumptions theorem_name.
```

Generate:

```text
generated/e2e/peregrine-cakeml-rocq-assumptions.txt
```

Fail on:

- `Admitted`;
- `trust_coq_kernel`;
- a new custom axiom;
- a hidden extraction assumption;
- an unexpected unsafe transform premise.

If `functional_extensionality` remains in the compile proof, record it explicitly in the transitive assumption ledger rather than hiding it.

## 11. Bind the CakeML Version Exactly

The proof model mirrors:

```text
CakeML:
e1650fc504837c0fbd3931cc5066914ffdc9d877
```

Use that exact CakeML revision in the HOL4 stage unless you prove a compatibility bridge.

Required equality chain:

```text
Peregrine proof model's CakeML AST/semantics
            =
HOL4 CakeML revision's AST/semantics
```

Do NOT mix `c98da7...` from earlier experiments with `e1650fc...` by assumption.

## 12. Create an Exact Translation Certificate

Only after the theorem is closed, emit a machine-readable audit certificate containing:

```text
L_bytes digest
L semantic identity
L_named semantic identity
K semantic identity
K_bytes digest
Peregrine source commit
Peregrine CakeML proof commit
CakeML semantic commit
pipeline theorem name
compile theorem name
serializer theorem name
assumption set
```

The certificate is audit metadata.

The theorem objects are the semantic evidence.

## 13. Add Mandatory Negative Tests

The theorem build MUST fail if:

1. `PipelineCorrect.v` is merely referenced by name but absent;
2. `trust_coq_kernel` is used to discharge the exact precondition;
3. one unsupported constructor is introduced into `L_named`;
4. candidate `.cml` changes by one byte;
5. CakeML revision changes;
6. candidate config differs from theorem config;
7. `CompileCorrect.v` is replaced by the ordinary in-tree `Admitted` backend;
8. one serializer theorem is removed;
9. one proof assumption becomes unclassified.

## Completion Gate

This milestone is complete only when:

- the real `CompileCorrect.v` source is pinned and builds;
- its exact fragment covers the self-hosted Peregrine program;
- a local/upstream complete pipeline correctness theorem is actually present;
- all required preconditions are proved rather than replaced by `trust_coq_kernel`;
- exact LambdaBox semantics compose into exact CakeML semantics;
- exact CakeML AST serializes to the prebuilt Peregrine candidate bytes;
- theorem assumptions are audited;
- the current upstream absence of `PipelineCorrect.v` is no longer a hole in YOUR final chain.

Until then:

```text
PEREGRINE_TO_CAKEML_E2E = BLOCKED
```

## References

### MetaRocq

- MetaRocq transformation and verified erasure foundation: https://github.com/MetaRocq/metarocq/blob/9.1/README.md
- MetaRocq erasure correctness development: https://github.com/MetaRocq/metarocq/tree/9.1/erasure/theories
- MetaRocq SafeChecker: https://github.com/MetaRocq/metarocq/tree/9.1/safechecker/theories

### Peregrine

- Official Peregrine pipeline composition: https://github.com/peregrine-project/peregrine-tool/blob/d768b83ffa7dab35b8d72241f0570b5bb6aedae9/theories/Pipeline.v
- Official CakeML backend repository: https://github.com/peregrine-project/cakeml-backend
- Audited compile-correct branch: https://github.com/peregrine-project/cakeml-backend/tree/5baed0b21618480b30711eb9df87e9bf00537372
- Verified compile proof source: https://github.com/peregrine-project/cakeml-backend/blob/5baed0b21618480b30711eb9df87e9bf00537372/theories/Backend/CompileCorrect.v

### CakeML

- Exact CakeML revision mirrored by the Peregrine backend: https://github.com/CakeML/cakeml/tree/e1650fc504837c0fbd3931cc5066914ffdc9d877
- CakeML in-logic compiler-evaluation interface: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/cv_translator/eval_cake_compileLib.sig
- CakeML compiler correctness composition example: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/examples/compilation/x64/proofs/helloProofScript.sml

### HOL4

- HOL4 official repository: https://github.com/HOL-Theorem-Prover/HOL
- HOL4 proof export API for the later portable certificate layer: https://github.com/HOL-Theorem-Prover/HOL/blob/40dd5b03de658f4bd9e3f4225fb0f1602ac90467/src/opentheory/postbool/OpenTheoryIO.sml
