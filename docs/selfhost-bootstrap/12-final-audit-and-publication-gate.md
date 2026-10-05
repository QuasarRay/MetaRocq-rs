# Milestone 12 — Final Independent Audit and Publication Gate

## Objective

Perform a final clean-room audit that answers one question:

> Does the exact machine artifact being published have a HOL4-kernel-checked E2E theorem tying it to the exact MetaRocq source snapshot, the complete in-scope proof/specification corpus, the exact extraction/Peregrine/CakeML path, and the explicit remaining assumption set?

The project MUST NOT use the word “E2E verified” for a build that fails any mandatory gate in this file.

## 1. Freeze the release candidate

Before the final proof run, record immutable identities for:

```text
MetaRocq-rs commit
MetaRocq upstream commit
Peregrine core commit
Peregrine CakeML backend commit
CakeML commit
HOL4 commit
scope manifest digest
target architecture/configuration
```

The release candidate MUST be built from a clean Git checkout.

Verify:

```bash
git status --porcelain
git submodule status 2>/dev/null || true

git -C .aegis/references/metarocq diff --exit-code
git -C .aegis/references/peregrine diff --exit-code
git -C .aegis/references/peregrine-cakeml diff --exit-code
git -C .aegis/cakeml diff --exit-code
git -C .aegis/hol4 diff --exit-code
```

Any dirty proof-producing source tree blocks publication.

## 2. Rebuild from the complete dependency chain

Run:

```bash
./tools/selfhost-e2e.sh clean
./tools/selfhost-e2e.sh pins
./tools/selfhost-e2e.sh prove
./tools/selfhost-e2e.sh replay-machine
./tools/selfhost-e2e.sh audit
```

Do not manually copy a theorem database, machine image, LambdaBox artifact, or CakeML artifact from an earlier build.

The final run must reconstruct the required artifacts from the pinned inputs or verify a content-addressed cache whose complete dependency key matches exactly.

## 3. Audit source/proof-corpus completeness

Verify all of the following:

```text
[ ] all configured source roots are present
[ ] the exact quoted environment is bound to the release source snapshot
[ ] every in-scope proof-bearing declaration appears exactly once in the certificate corpus
[ ] every retained certificate maps back to exactly one in-scope source declaration
[ ] theorem statement identity matches the source declaration
[ ] proof/body identity matches the source declaration
[ ] dependencies/universe information required for replay are preserved
[ ] the self-reflection/replay machinery itself is in scope
[ ] no proof-bearing source module was silently removed to make the build pass
```

A length/count check is only a secondary sanity check. The authoritative completeness result must be the proved identity/membership relation described in Milestone 03.

## 4. Audit the complete assumption ledger

Generate and inspect:

```text
generated/e2e/assumption-ledger.json
generated/e2e/final/assumptions.txt
```

Every assumption reachable from the final theorem MUST be classified.

Mandatory checks:

```text
[ ] no Admitted/admit
[ ] no unreviewed Axiom/Parameter
[ ] no hidden fake guard implementation premise
[ ] SafeChecker normalization assumptions are explicit
[ ] Peregrine assumptions are explicit
[ ] CakeML target/FFI/machine assumptions are explicit
[ ] HOL4 foundational axioms/tags are understood
[ ] no unexpected oracle theorem is reachable
[ ] all temporary assumptions are either discharged or keep the final theorem explicitly conditional
```

If the theorem conclusion is conditional, the release report MUST display the premise prominently.

Never convert:

```text
A ==> MetaRocqE2E ...
```

into the prose claim:

```text
MetaRocq is unconditionally E2E verified.
```

unless `A` has actually been discharged.

## 5. Audit the source → LambdaBox boundary

Check:

```text
[ ] exact final source entrypoint is the one covered by the erasure theorem
[ ] the complete retained certificate corpus remains computational data
[ ] the complete assumption ledger remains computational/auditable data
[ ] replay jobs remain reachable
[ ] proof erasure has not removed the quoted proof AST needed for replay
[ ] exact LambdaBox artifact identity matches the theorem-bound artifact
[ ] mutation of the LambdaBox artifact invalidates the downstream proof
```

Record:

```bash
sha256sum generated/original-selfhost/reconciled-selfhost.ast
```

and compare it with the exact final manifest.

## 6. Audit the LambdaBox → Peregrine → CakeML boundary

Check:

```text
[ ] exact Peregrine CakeML backend commit is pinned
[ ] the backend correctness theorem builds
[ ] verified_cakeml_pipeline_theorem or its exact strengthened successor is instantiated
[ ] the theorem is instantiated for the exact selfhost LambdaBox program
[ ] CakeML semantic-version skew has been eliminated or explicitly bridged by theorem
[ ] all used primitives/FFIs are mapped
[ ] no unproved serializer/parser boundary is on the critical path
[ ] exact CakeML program identity is recorded
```

Do not accept a syntactic `PAst -> EAst -> Compile.compile_program` equality by itself as a semantic refinement proof.

## 7. Audit HOL4 independent proof replay

Check that HOL4, not ordinary Rocq acceptance, authorizes the final proof-validity claim.

Mandatory checks:

```text
[ ] pinned HOL4 source revision is exact and clean
[ ] complete source/proof replay is actually evaluated/reconstructed
[ ] HOL4 produces a real thm for the complete replay result
[ ] source/corpus completeness is a dependency of that theorem
[ ] theorem hypotheses match the approved assumption set
[ ] theorem oracle/tag metadata match policy
[ ] removing or mutating one source proof prevents successful final theorem construction
```

Record the exact theorem conclusion in:

```text
generated/e2e/final/replay-theorem.txt
```

Do not record only its theorem name.

## 8. Audit CakeML in-logic compilation

Verify the exact compilation path:

```text
exact CakeML program definition
        |
        | eval_cake_compile_x64 / exact target equivalent
        v
program-specific HOL4 compilation theorem
        |
        | compile_correct
        v
machine-level refinement theorem
```

Mandatory checks:

```text
[ ] no standalone compiler output is being trusted as the theorem source
[ ] CakeML source revision matches the proof environment
[ ] exact target/backend configuration is fixed
[ ] exact application semantics theorem is for the same program definition
[ ] exact compiler-evaluation theorem is for the same program definition
[ ] exact machine theorem is for the compiler result from that theorem
[ ] FFI/machine initialization premises are explicit
```

## 9. Audit the exact machine artifact

Distinguish these artifacts:

```text
A. theorem-bound CakeML machine-code representation
B. emitted assembly, if any
C. object file, if any
D. linked/packaged executable, if any
E. actually executed runtime image
```

The final report MUST state exactly which of A–E the HOL4 theorem covers.

If an external assembler/linker/ELF loader transforms A into D and that transformation is not proved, do NOT state that D is byte-for-byte E2E verified merely because A is.

Either:

1. extend the proof to the packaged image; or
2. publish the machine-code theorem with an explicit packaging/loading trust boundary.

Before runtime replay, verify the exact theorem-bound identity.

## 10. Audit unified theorem composition

The final HOL4 theorem graph MUST contain a connected path:

```text
exact source/proof state
        |
        v
complete proof replay validity
        |
        v
source/self-reflective semantics
        |
        v
exact LambdaBox refinement
        |
        v
exact Peregrine/CakeML refinement
        |
        v
exact CakeML program semantics
        |
        v
exact in-logic CakeML compilation
        |
        v
exact machine semantics
```

Reject a release containing individually valid but disconnected theorems.

The final theorem SHOULD be named clearly, for example:

```text
MetaRocqE2ETheory.MetaRocqE2E
```

and the audit bundle should contain its exact printed conclusion.

## 11. Audit recursive machine self-replay

Execute:

```bash
./tools/selfhost-e2e.sh replay-machine
```

Verify:

```text
[ ] machine image identity matches the release manifest
[ ] runtime source snapshot identity matches the build-time source
[ ] runtime certificate-corpus identity matches the build-time corpus
[ ] runtime assumption-ledger identity matches the build-time ledger
[ ] replay result matches the theorem-predicted result
[ ] runtime FFI inputs satisfy the theorem premises
[ ] the correspondence is theorem-backed, not only string/hash comparison
```

Remember: runtime self-replay is recursive confirmation of the already proved machine semantics. It is not the foundational reason the machine is trusted.

## 12. Perform a second independent clean build

From a separate clean worktree/clone:

```bash
git worktree add ../MetaRocq-rs-release-audit HEAD
cd ../MetaRocq-rs-release-audit

./tools/selfhost-e2e.sh pins
./tools/selfhost-e2e.sh prove
./tools/selfhost-e2e.sh audit
```

Compare the two builds.

At minimum compare:

```text
source snapshot digest
quoted environment digest
proof corpus digest
assumption ledger digest
LambdaBox digest
Peregrine backend identity
CakeML program digest
HOL4 theorem conclusion
HOL4 assumption/tag report
CakeML target configuration
theorem-bound machine-code digest
```

If reproducible final bytes are claimed, compare the exact final bytes too.

A second successful build is a reproducibility check, not a substitute for the theorem.

## 13. Run the complete mutation suite

Before publication, confirm that each deliberate mutation prevents final acceptance:

```text
[ ] omit one source proof
[ ] alter one theorem statement
[ ] alter one proof body
[ ] add one unapproved assumption
[ ] introduce an oracle theorem
[ ] alter retained LambdaBox proof state
[ ] alter Peregrine backend revision
[ ] alter primitive/FFI mapping
[ ] alter CakeML semantic/compiler revision
[ ] alter CakeML program AST
[ ] alter target compiler configuration
[ ] alter theorem-bound machine code
[ ] substitute an old manifest or theorem report
[ ] run a different executable in the runtime replay step
```

The pipeline is not fail-closed if a semantically relevant mutation can retain a green final status without regenerating/rechecking its dependent theorem.

## 14. Produce the final audit bundle

Create:

```text
generated/e2e/final/
  README.md
  release-scope.json
  source-manifest.json
  proof-corpus-manifest.json
  assumption-ledger.json
  erasure-binding.json
  peregrine-binding.json
  cakeml-binding.json
  machine-binding.json
  replay-theorem.txt
  machine-theorem.txt
  final-theorem.txt
  theorem-dependencies.txt
  theorem-tags.txt
  runtime-replay-report.json
  environment.txt
  SHA256SUMS
```

Do not put secrets, private tokens, or machine-specific credentials in this bundle.

The bundle should be sufficient for a human engineer to identify every exact input and theorem involved in the claim.

## 15. Use precise release language

Allowed only if supported:

```text
"The pinned HOL4 kernel checked theorem T, whose conclusion connects
the exact source/proof snapshot S through the proved extraction,
Peregrine, CakeML and target-machine refinement chain to machine
artifact M, subject to the explicitly listed assumptions A."
```

If `A` is empty except for the intended HOL4/CakeML machine-model foundation, say exactly that.

Do NOT say:

```text
"fully verified"
"zero trust"
"no assumptions"
"binary verified"
```

unless the actual theorem boundary supports those exact claims.

## 16. Final one-command publication gate

Implement:

```bash
./tools/selfhost-e2e.sh publish-check
```

It MUST fail unless:

```text
pins                         PASS
source/proof completeness    PROVED
assumption classification    PASS
source->LambdaBox             PROVED
LambdaBox->CakeML             PROVED
complete HOL4 proof replay    PROVED
CakeML application semantics  PROVED
in-logic CakeML compilation   PROVED
machine refinement            PROVED
unified E2E composition       PROVED
theorem tag/oracle audit      PASS
runtime self-replay           THEOREM-CONSISTENT
clean-build reproduction      PASS
mutation suite                PASS
release manifest              EXACT
```

A missing stage is `BLOCKED`, never implicitly `PASS`.

## Completion gate

The complete bootstrap is finished only when `publish-check` succeeds from a clean checkout and the final HOL4 theorem printed in the audit bundle binds the exact source/proof corpus to the exact theorem-covered machine artifact.

Until that condition holds, the repository may describe the work as:

```text
architecture complete
proof obligations explicit
pipeline partially mechanized
E2E proof not yet closed
```

but MUST NOT claim final E2E verification.

## References

### MetaRocq

- MetaRocq architecture, PCUIC metatheory, SafeChecker, erasure, quotation, and self-erasure overview: https://github.com/MetaRocq/metarocq/blob/9.1/README.md
- MetaRocq installation/package layout, including quotation of typing derivations: https://github.com/MetaRocq/metarocq/blob/9.1/INSTALL.md
- PCUIC theories: https://github.com/MetaRocq/metarocq/tree/9.1/pcuic/theories
- SafeChecker theories: https://github.com/MetaRocq/metarocq/tree/9.1/safechecker/theories
- Erasure theories: https://github.com/MetaRocq/metarocq/tree/9.1/erasure/theories
- Correct and Complete Type Checking and Certified Erasure for Coq, in Coq: https://dl.acm.org/doi/10.1145/3706056

### Peregrine

- Peregrine CakeML backend and E2E backend correctness architecture: https://github.com/peregrine-project/cakeml-backend
- CakeML backend README, documenting `CompileCorrect.v`, `PipelineCorrect.v`, and `verified_cakeml_pipeline_theorem`: https://github.com/peregrine-project/cakeml-backend/blob/main/README.md

### CakeML

- CakeML theorem-producing compiler evaluation API: https://github.com/CakeML/cakeml/blob/master/cv_translator/eval_cake_compileLib.sig
- Concrete x64 in-logic compilation theorem: https://github.com/CakeML/cakeml/blob/master/examples/compilation/x64/helloCompileScript.sml
- Concrete x64 E2E machine proof using `compile_correct`: https://github.com/CakeML/cakeml/blob/master/examples/compilation/x64/proofs/helloProofScript.sml
- Verified CakeML Compiler Backend: https://cakeml.org/jfp19.pdf
- CakeML source repository: https://github.com/CakeML/cakeml

### HOL4

- HOL4 official documentation: https://hol-theorem-prover.org/docs/trindemossen-2/
- HOL4 installation instructions: https://hol-theorem-prover.org/install
- HOL4 logic description: https://hol-theorem-prover.org/docs/trindemossen-2/Description/
- HOL4 developer/kernel documentation: https://hol-theorem-prover.org/docs/trindemossen-2/Developers/
- HOL4 source repository: https://github.com/HOL-Theorem-Prover/HOL
