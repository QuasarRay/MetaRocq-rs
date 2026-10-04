# 07 — Embed the HOL4/Peregrine Proof Capsule into the SAME CakeML Program WITHOUT Creating a Circular “Proof of Its Own Bytes”

## Objective

Make the final CakeML program carry the complete proof/provenance material required to independently reconstruct its validation.

The final machine program MUST contain:

```text
Peregrine selfhost core
+
complete retained Peregrine proof-replay state
+
source/proof/assumption manifests
+
exact LambdaBox identity
+
exact CakeML-core identity
+
HOL4/OpenTheory replay artifacts that are non-circular
+
exact toolchain/target identities
+
future-HOL4 reconstruction instructions/data
```

The exact final machine-code theorem is produced AFTER compilation.

Therefore the design MUST avoid trying to embed that exact theorem into the program BEFORE compiling it.

## REUSE

Reuse the non-circular rule from:

```text
docs/selfhost-bootstrap/10-recursive-machine-self-replay.md
```

and the exact-machine theorem from:

```text
06-cakeml-hol4-exact-machine-attestation.md
```

This milestone adds the missing self-certificate representation.

## 1. Understand the Fixed-Point Problem BEFORE Writing Code

The invalid design is:

```text
program K0
  -> compile
  -> machine M0
  -> prove theorem T0 about exact M0
  -> embed T0 into program
  -> program becomes K1
  -> compile
  -> machine becomes M1
  -> T0 no longer proves the exact final machine
```

Repeating this does NOT automatically converge.

Therefore a literal ordinary data constant containing:

```text
"the exact final theorem of my own final complete bytes"
```

is NOT a sound bootstrap design.

Do NOT solve this with a stale hash, a self-reported Boolean, or by excluding the proof section from the hash without proving that exclusion matches execution semantics.

## 2. Split the Certificate into Two Levels

### Level 1 — Embedded Core Proof Capsule

This exists BEFORE final CakeML compilation.

It MUST be part of the exact final CakeML program semantics.

### Level 2 — Outer Exact-Machine Attestation

This exists AFTER final in-logic CakeML compilation.

It is the HOL4:

```text
machine_code_sound
```

theorem, optionally exported as an OpenTheory article.

A future HOL4 instance regenerates/rechecks Level 2 from Level 1 + the exact machine code.

This is the recommended E2E architecture.

## 3. Define the Level-1 Capsule Schema

Create a versioned canonical schema, for example:

```text
spec/peregrine-proof-capsule-v1.json
```

and a corresponding CakeML data representation.

Conceptually:

```text
PeregrineProofCapsuleV1 {
  format_version
  source_snapshot
  source_manifest
  certificate_corpus
  assumption_ledger
  replay_jobs
  lambdabox_artifact
  lambdabox_digest
  peregrine_source_commit
  peregrine_backend_commit
  cakeml_semantics_commit
  hol4_commit
  cakeml_core_ast_digest
  theorem_statements
  portable_hol_articles
  theorem_dependency_manifest
  target_config
  reconstruction_recipe
}
```

Do NOT include a field claiming:

```text
final_machine_theorem_verified = true
```

unless that field is interpreted only as data checked against an OUTER theorem.

The field itself is not evidence.

## 4. Include Only NON-CIRCULAR HOL4 Proof Artifacts Inside Level 1

Safe to embed before final compilation:

- source/proof-corpus replay articles that do not depend on final machine bytes;
- translation/candidate-binding theorem articles that refer to the Peregrine core/CakeML core;
- generic CakeML compiler theorem identifiers/dependency manifests;
- HOL4 theory source required to replay/reconstruct;
- exact theorem conclusions for lower layers;
- exact source/toolchain/configuration pins;
- proof-assumption ledger;
- a theorem SCHEMA for the outer machine theorem;
- the exact reconstruction algorithm/recipe.

Not safe to embed as an ordinary pre-compilation constant:

- the already-instantiated theorem whose conclusion identifies the complete final code produced by compiling the program containing that same theorem artifact.

## 5. Separate the Translated Peregrine Core from the CakeML Certificate Service

Define:

```text
K_core
  = exact CakeML AST proved to refine the Peregrine LambdaBox core

CapsuleService(P)
  = small CakeML component exposing/checking capsule P

K_final
  = composition of K_core + CapsuleService(P)
```

This avoids pretending Peregrine itself generated the post-translation certificate-service logic.

You MUST separately prove the composition:

```text
K_core refines PeregrineCoreSpec
CapsuleService(P) satisfies CapsuleSpec(P)
-------------------------------------------
K_final satisfies PeregrineSelfHostSpec + CapsuleSpec
```

inside HOL4.

## 6. Generate the Canonical Capsule Bytes BEFORE Final Compilation

Create:

```text
generated/peregrine-selfhost/capsule/
  capsule-v1.cbor-or-sexp
  source-manifest.json
  proof-corpus-manifest.json
  assumption-ledger.json
  theorem-dependencies.json
  reconstruction.json
  proofs/*.art
  SHA256SUMS
```

Choose ONE canonical serialization.

Prefer a format whose encoder/decoder can be defined/proved inside CakeML/HOL4 or whose exact bytes are generated as a constant by the build.

Do NOT use nondeterministic JSON whitespace/key order as theorem-bound identity.

A canonical S-expression or a deliberately specified binary format is preferable.

## 7. Embed the Capsule as Ordinary CakeML Data

Generate a CakeML value representing the exact bytes:

```text
embedded_proof_capsule : word8 list
```

or the equivalent CakeML string/byte-vector representation supported by the pinned program basis.

The generated CakeML/HOL4 definition MUST prove:

```text
embedded_proof_capsule = exact_capsule_bytes
```

and:

```text
sha256/identity used by the manifest
corresponds to exact_capsule_bytes
```

if you use a digest.

Do NOT make the file on disk authoritative over the theorem-bound CakeML value.

## 8. Add a Deterministic CakeML Certificate Interface

The final program SHOULD expose commands equivalent to:

```text
--certificate-info
--emit-proof-capsule
--verify-inner-proof-capsule
--replay-peregrine-proofs
```

The exact CLI surface may be different, but the semantics must provide equivalent operations.

At minimum:

```text
EmitProofCapsule
  -> returns exact embedded capsule bytes

ReplayPeregrineProofs
  -> returns exact retained replay report

CertificateInfo
  -> returns exact source/corpus/toolchain identities
```

These behaviors MUST be part of `PeregrineSemanticsTheory`.

## 9. Reuse CakeML's Verified OpenTheory Reader for Runtime Inner-Proof Checking

CakeML contains an end-to-end verified OpenTheory article checker example.

Its official proof reaches a theorem:

```text
machine_code_sound
```

and proves soundness of accepted article theorems.

For the strongest runtime capsule service:

1. reuse/adapt the CakeML OpenTheory reader as a library component;
2. feed it the embedded `.art` proof artifacts;
3. expose the result through `VerifyInnerProofCapsule`;
4. preserve the reader's soundness theorem in the final application semantics.

Do NOT write a new ad-hoc “OpenTheory parser” merely to reduce implementation work.

If integrating the full reader is too large initially:

```text
Level-1 capsule embedding = allowed
runtime OpenTheory replay = BLOCKED/PENDING
future HOL4 replay = still mandatory
```

Do not fake runtime proof checking.

## 10. Prove the Exact Capsule Is Reachable in Machine Semantics

The final HOL4 application theorem MUST include:

```text
Machine executes EmitProofCapsule
  =>
returns exact_capsule_bytes
```

and:

```text
exact_capsule_bytes
contains exact source/proof/replay identities
```

The proof must transitively pass through:

```text
K_final CakeML semantics
  ->
CakeML compiler correctness
  ->
machine semantics
```

This is what makes the proof capsule genuinely part of the theorem-bound machine program rather than an unrelated sidecar.

## 11. Generate the OUTER Exact-Machine Theorem AFTER Compilation

After compiling `K_final` inside HOL4:

```text
K_final
  -> eval_cake_compile_x64
  -> exact machine M
```

derive:

```text
T_outer:
  MachineSemantics(M)
    refines
  PeregrineSelfHostSpec
    + CapsuleSpec(exact_capsule_bytes)
```

Then export:

```text
generated/peregrine-selfhost/proofs/
  outer-machine-code-sound.art
```

This article is NOT an input to the compilation that produced `M`.

That non-circular sequencing is mandatory.

## 12. Define What “CakeML Compiler Certifies That HOL4 Validated It” Means Precisely

Do NOT anthropomorphize the executable.

The exact formal claim is:

```text
HOL4 evaluated the CakeML compiler definition
on the exact K_final program.

HOL4 produced a theorem describing the exact compiler output.

HOL4 combined that theorem with CakeML's generic compiler-correctness theorem
and the exact application-semantics theorem.

The resulting HOL4 theorem proves the exact machine-code semantics.

The machine program itself carries the exact lower-layer proof/replay inputs
required to reconstruct that conclusion later.
```

This is stronger and more precise than embedding a string saying:

```text
"HOL4 verified me"
```

## 13. Make Future Reconstruction a Property of the Capsule

The capsule's `reconstruction_recipe` MUST identify:

```text
HOL4 commit
CakeML commit
Peregrine commit
Peregrine CakeML proof commit
theory names
theorem names
CakeML program/capsule reconstruction
target config
compiler-evaluation call
expected machine-code digest/identity
expected theorem conclusion schema
```

A future HOL4 installation can then regenerate `T_outer`.

Milestone 08 defines the exact replay procedure.

## 14. Stronger Level-2 SINGLE-PHYSICAL-FILE Variant

If you REQUIRE:

```text
ONE physical executable file
contains:
  machine code M
  exact outer theorem article T_outer.art
```

you cannot simply append the article and retain the old whole-file theorem.

Instead define:

```text
B = pack(M, P, T_outer.art)
```

and prove:

```text
load_code(B) = M
extract_inner_capsule(B) = P
extract_outer_article(B) = T_outer.art
```

plus:

```text
ExecutionSemantics(B) = ExecutionSemantics(M)
```

under the exact loader model.

### Recommended container theorem

Define a minimal deterministic certificate container with:

```text
magic
version
code_length
capsule_length
outer_article_length
code_bytes
capsule_bytes
outer_article_bytes
checksum/index
```

Prove parser/projection theorems in HOL4.

### Standard Linux ELF warning

If `B` must be a normal ELF executable and you use:

- linker scripts;
- `objcopy --add-section`;
- ELF notes;
- appended trailers;
- `strip`;

you MUST prove that the actual Linux/ELF loader maps the code exactly as the CakeML machine theorem expects, or state that loader/packaging is outside the verified boundary.

CakeML's machine-code theorem by itself does NOT prove arbitrary ELF post-processing correct.

## 15. Preferred Publication Hierarchy

### Tier 1 — Fully coherent now

```text
theorem-bound machine code
contains Level-1 capsule
+
outer exact-machine article is external
and reproducible from capsule
```

### Tier 2 — Stronger after container proof

```text
one physical proof-carrying executable container
contains code + Level-1 capsule + Level-2 article
and HOL4 proves container projections/loader semantics
```

Do NOT claim Tier 2 while only Tier 1 has been proved.

## 16. Mandatory Self-Reference Mutation Tests

The final theorem/reconstruction MUST fail if:

1. one embedded capsule byte changes;
2. one lower-layer article changes;
3. one certificate-corpus entry changes;
4. capsule reports a different CakeML commit;
5. capsule reports a different machine digest;
6. a stale `T_outer.art` is paired with a newer machine code;
7. a post-link tool changes executable code bytes;
8. a Level-2 container parser reads overlapping/malformed sections;
9. a runtime “verified=true” field is accepted without theorem evidence.

## Completion Gate

Level 1 is complete only when:

- the exact final CakeML program contains the exact canonical proof capsule;
- the capsule contains all non-circular replay/provenance artifacts needed by future HOL4;
- final CakeML semantics prove exact capsule observability;
- final machine theorem proves those semantics;
- `T_outer` is generated only after final compilation;
- a fresh HOL4 can later reconstruct it.

Level 2 is complete only when:

- the outer theorem article is also physically in one file;
- the container/loader projection is formally proved;
- code bytes theorem-bound by CakeML remain exactly the bytes executed;
- proof/capsule extraction is formally related to the same file.

## References

### MetaRocq

- MetaRocq recursive quotation and proof/program reflection foundation: https://github.com/MetaRocq/metarocq/blob/9.1/README.md
- MetaRocq Template Monad quotation API: https://github.com/MetaRocq/metarocq/blob/9.1/template-rocq/theories/TemplateMonad/Core.v
- MetaRocq verified erasure: https://github.com/MetaRocq/metarocq/tree/9.1/erasure/theories

### Peregrine

- Peregrine formal pipeline: https://github.com/peregrine-project/peregrine-tool/blob/d768b83ffa7dab35b8d72241f0570b5bb6aedae9/theories/Pipeline.v
- Peregrine CakeML backend contract and serialized output: https://github.com/peregrine-project/peregrine-tool/blob/d768b83ffa7dab35b8d72241f0570b5bb6aedae9/doc/backends.md
- Peregrine CakeML proof development: https://github.com/peregrine-project/cakeml-backend

### CakeML

- Verified OpenTheory checker compilation and machine-code soundness example: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/examples/opentheory/compilation/proofs/readerProgProofScript.sml
- OpenTheory reader compiler evaluation: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/examples/opentheory/compilation/readerCompileScript.sml
- Theorem-producing CakeML compiler evaluator: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/cv_translator/eval_cake_compileLib.sig

### HOL4

- HOL4 theorem→OpenTheory article bridge: https://github.com/HOL-Theorem-Prover/HOL/blob/40dd5b03de658f4bd9e3f4225fb0f1602ac90467/src/opentheory/postbool/OpenTheoryIO.sml
- HOL4 article→theorem bridge: https://github.com/HOL-Theorem-Prover/HOL/blob/40dd5b03de658f4bd9e3f4225fb0f1602ac90467/src/opentheory/postbool/OpenTheoryIO.sig
- HOL4 OpenTheory reader contract: https://github.com/HOL-Theorem-Prover/HOL/blob/40dd5b03de658f4bd9e3f4225fb0f1602ac90467/src/opentheory/reader/OpenTheoryReader.sig
