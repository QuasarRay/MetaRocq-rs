# 16 — Milestone 06 — Integrate the Exact Peregrine CakeML Backend and Close LambdaBox → CakeML

> **UNIFIED SEQUENCE STEP 16 OF 22 — METAROCQ SOURCE/SPECIFICATION -> MACHINE REFINEMENT.**  
> Reused from `docs/selfhost-bootstrap/06-peregrine-cakeml-backend.md` on `docs/selfhost-bootstrap-04-runtime-audit`. The original manual remains preserved. This unified copy is downstream of the verified Peregrine foundation from Steps 01–10.

## Mandatory verified-Peregrine handoff

This milestone MUST consume the exact Part I result from Steps 01–10.

The acceptable bridge is:

```text
exact retained MetaRocq LambdaBox artifact
        |
        v
proved Peregrine LambdaBox -> CakeML transformation theorem
        |
        v
exact theorem-stage CakeML AST / serialized program
```

The following are NOT acceptable replacements:

```text
native peregrine process exited 0
CI says green
trust_coq_kernel
an admitted backend obligation
an unproved serializer/parser correspondence
an executable whose hash is not theorem-bound
```

The Peregrine machine theorem from Part I establishes the trusted implementation boundary; the transformation theorem is what connects the exact MetaRocq LambdaBox input to the exact CakeML program used below.

## Objective

Replace the current “candidate CakeML output exists and passes syntactic gates” condition with a theorem-backed translation path from the exact retained LambdaBox program to the exact CakeML program later compiled in HOL4.

The required invariant is:

```text
exact LambdaBox program L
        |
        | exact Peregrine/CakeML backend implementation
        | + checked correctness theorem
        v
exact CakeML program K

Semantics_LambdaBox(L)
  refines/is-related-to
Semantics_CakeML(K)
```

A successful printer run, AST conversion, supported-fragment Boolean, or no-`Raise` check is not enough.

## 1. Add the dedicated Peregrine CakeML backend to the toolchain lock

The current repository pins `peregrine-project/peregrine-tool`, but the dedicated CakeML backend now lives separately:

```text
https://github.com/peregrine-project/cakeml-backend
```

At the time this manual was written, the upstream `main` head was:

```text
a5df761d5032b01ae66fc82965f1a79f313e1bbc
```

Do NOT depend on moving `main`. After reviewing the exact upstream commit, add an immutable entry to:

```text
spec/toolchain.lock.json
spec/selfhost-e2e-scope.json
```

For example:

```json
"peregrine_cakeml_backend": {
  "repository": "https://github.com/peregrine-project/cakeml-backend.git",
  "commit": "a5df761d5032b01ae66fc82965f1a79f313e1bbc"
}
```

If you intentionally select a newer commit, record it explicitly and re-run the entire downstream proof chain.

## 2. Materialize the backend from source

Use a dedicated checkout:

```bash
rm -rf .aegis/references/peregrine-cakeml
git clone https://github.com/peregrine-project/cakeml-backend.git \
  .aegis/references/peregrine-cakeml

git -C .aegis/references/peregrine-cakeml checkout --detach \
  a5df761d5032b01ae66fc82965f1a79f313e1bbc

git -C .aegis/references/peregrine-cakeml diff --exit-code
git -C .aegis/references/peregrine-cakeml rev-parse HEAD
```

Build it in the SAME isolated Rocq/opam environment used for MetaRocq unless its package metadata requires a separate switch.

Do not use an unpinned global `rocq-cakeml-extraction` installation for publication evidence.

## 3. Reuse the upstream correctness architecture

The backend's authoritative README documents the relevant structure:

```text
theories/
  CakeML/                 CakeML AST/semantic formalization
  Backend/...             compilation implementation
  Compile.v               compilation function
  CompileCorrect.v        compilation correctness
  Pipeline.v              MetaRocq/Peregrine pipeline
  PipelineCorrect.v       E2E correctness
```

and names an end-to-end theorem:

```text
verified_cakeml_pipeline_theorem
```

Do not reimplement this proof architecture from scratch.

Your work is to instantiate or strengthen the upstream theorem for the exact self-reflective MetaRocq LambdaBox artifact and to connect the resulting CakeML semantics to the exact CakeML version compiled in HOL4.

## 4. Resolve CakeML-version skew BEFORE trusting the theorem

This is a mandatory gate.

The Peregrine CakeML backend README states that its CakeML formalization mirrors a specific CakeML source revision:

```text
e1650fc504837c0fbd3931cc5066914ffdc9d877
```

The current MetaRocq-rs selfhost contract has separately referenced CakeML:

```text
c98da7fc904c5d6d0e9a75a18fac1796a9bfb1f9
```

Do NOT assume these AST/semantics versions are interchangeable.

Choose one of the following:

### Preferred path — align the CakeML pin

If the Peregrine theorem is built against `e1650fc...`, pin the downstream CakeML/HOL4 compilation stage to the same compatible CakeML semantics revision, then re-run all CakeML-related proofs and examples.

### Alternative path — prove an explicit compatibility bridge

If you must retain `c98da7...`, prove that the exact CakeML AST and semantic definitions consumed by the downstream compiler are equivalent/refinement-compatible with the Peregrine backend's mirrored definitions for the used fragment.

A printer-level or datatype-name similarity check is not sufficient.

## 5. Replace the current candidate-only gate with a semantic theorem

The current MetaRocq-rs branch already proves useful facts about:

```text
PAst_to_EAst
east_program_supported
Compile.compile_program
candidate_cakeml_no_raise
```

Keep those as defensive/syntactic gates.

But publication MUST additionally require a theorem equivalent to:

```text
peregrine_compile exact_lambdabox = exact_cakeml_program
/\
lambdabox_behavior exact_lambdabox
    ~
cakeml_behavior exact_cakeml_program
```

where `~` is the exact simulation/refinement/equivalence relation established by the backend theorem.

Do not set `translation_east_semantics_preserved := true` manually. Derive the accepted certificate from the proof.

## 6. Instantiate correctness for the exact selfhost artifact

Produce a theorem/certificate tied to:

```text
generated/original-selfhost/reconciled-selfhost.ast
```

The build should compute/derive:

```text
L = exact LambdaBox term from the retained MetaRocq root
K = exact CakeML program produced from L
```

Then instantiate the Peregrine correctness theorem on `L`.

Store the CakeML artifact under:

```text
generated/e2e/cakeml/
```

and record:

```bash
sha256sum generated/original-selfhost/reconciled-selfhost.ast \
  > generated/e2e/cakeml/input-lambdabox.sha256

sha256sum generated/e2e/cakeml/* \
  > generated/e2e/cakeml/output.sha256
```

Hashes bind the concrete artifact; the theorem supplies semantics.

## 7. Do not introduce an unverified serialization hole

If the backend theorem proves correctness of an internal CakeML AST but the next stage reads serialized S-expressions/text, the serializer/parser pair becomes part of the boundary.

You MUST do one of:

1. keep the CakeML value in logic and hand it directly to CakeML's in-logic compilation definitions; or
2. prove/verify serialization and parsing round-trip correctness for the exact format.

Preferred:

```text
Peregrine theorem produces CakeML AST value
           |
           v
HOL4/CakeML in-logic compiler consumes corresponding exact AST
```

Avoid:

```text
proved AST
   -> unverified pretty printer
   -> text
   -> unverified parser
   -> different AST
```

## 8. Bind primitive/FFI mappings explicitly

Inspect every LambdaBox primitive that the selfhost program can exercise.

For each primitive mapping record:

```text
source primitive
Peregrine representation
CakeML primitive/FFI
semantic theorem
machine/runtime assumption
```

Reject unmapped primitives.

Do not silently map mathematical integers to fixed-width machine integers, exceptions to aborts, or strings/bytes to different encodings without a theorem or explicit bounded-domain premise.

## 9. Integrate the theorem into MetaRocq-rs publication state

Replace unresolved fields in the current `CakeMLTranslationCertificate.v` only through theorem-derived evidence.

The accepted state should bind at least:

```text
LambdaBox digest
Peregrine backend commit
CakeML semantics/version identity
CakeML program digest
supported-fragment theorem
semantic-preservation theorem identity
primitive/FFI ledger identity
assumption set
```

Do not keep Candle-specific fields as mandatory if HOL4 is now the primary proof authority. Preserve historical fields for audit if useful, but do not let them distort the new trust chain.

## 10. Local build command

Create a deterministic command, for example:

```bash
./tools/selfhost-e2e.sh peregrine
```

It should:

1. verify MetaRocq/Peregrine/backend/CakeML revisions;
2. regenerate the exact LambdaBox artifact;
3. compile the CakeML backend proofs;
4. generate the exact CakeML AST/program;
5. instantiate/check the LambdaBox→CakeML theorem;
6. emit theorem/artifact identities;
7. fail if the theorem, exact artifact binding, or primitive mapping is incomplete.

## 11. Negative tests

The following MUST fail:

- mutate one LambdaBox constructor after theorem generation;
- compile with a different Peregrine backend commit;
- change the CakeML semantic version without a compatibility proof;
- remove the correctness theorem and keep only syntactic gates;
- alter a primitive mapping;
- serialize/parse through an unproved format and claim identity;
- change the CakeML output while retaining stale hashes.

## Completion gate

Milestone 06 is complete only when:

- the exact Peregrine CakeML backend is pinned by commit;
- its correctness theorem is built locally;
- CakeML semantic-version skew is eliminated or explicitly proved compatible;
- the exact selfhost LambdaBox artifact is translated to one exact CakeML program;
- a checked theorem relates the LambdaBox and CakeML semantics for that exact program;
- primitive/FFI mappings are explicit;
- no unverified serialization boundary remains on the publication path.

## References

### Peregrine

- Peregrine CakeML backend repository: https://github.com/peregrine-project/cakeml-backend
- Backend architecture and `verified_cakeml_pipeline_theorem`: https://github.com/peregrine-project/cakeml-backend/blob/main/README.md
- Peregrine project organization: https://github.com/peregrine-project

### MetaRocq

- MetaRocq verified erasure and related-project overview: https://github.com/MetaRocq/metarocq/blob/9.1/README.md
- MetaRocq installation/package layout: https://github.com/MetaRocq/metarocq/blob/9.1/INSTALL.md
- MetaRocq erasure theories: https://github.com/MetaRocq/metarocq/tree/9.1/erasure/theories

### CakeML

- CakeML repository: https://github.com/CakeML/cakeml
- Verified CakeML Compiler Backend: https://cakeml.org/jfp19.pdf
- CakeML compiler-evaluation API used later: https://github.com/CakeML/cakeml/blob/master/cv_translator/eval_cake_compileLib.sig

### HOL4

- HOL4 official documentation: https://hol-theorem-prover.org/docs/trindemossen-2/
- HOL4 logic description: https://hol-theorem-prover.org/docs/trindemossen-2/Description/
- HOL4 developer/kernel documentation: https://hol-theorem-prover.org/docs/trindemossen-2/Developers/
