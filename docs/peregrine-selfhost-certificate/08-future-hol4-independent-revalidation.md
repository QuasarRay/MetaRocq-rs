# 08 — Make a FRESH HOL4 Instance Reconstruct the Entire Validation from the Executable's Embedded Capsule

## Objective

Prove the recursive property requested by the project WITHOUT trusting the original build process merely because it produced a green report.

A completely separate HOL4 checkout must be able to start from:

```text
exact machine artifact M
+ embedded Level-1 capsule C extracted from M/the theorem-bound runtime
+ immutable upstream pins
```

and reconstruct:

```text
Peregrine source/proof validity
        -> source/LambdaBox refinement
        -> LambdaBox/CakeML refinement
        -> exact CakeML program K
        -> eval_cake_compile_x64 K = M_model
        -> compile_correct/x64
        -> outer PeregrineSelfHostE2E theorem
```

The final result is a NEW HOL4 theorem object created by the fresh verifier.

Do NOT accept:

```text
original build says VALID
```

as proof input.

## REUSE

Reuse:

```text
docs/selfhost-bootstrap/07-hol4-independent-replay-kernel.md
docs/selfhost-bootstrap/10-recursive-machine-self-replay.md
docs/selfhost-bootstrap/12-final-audit-and-publication-gate.md
```

This milestone adds only the NEW portable-capsule-to-fresh-HOL4 reconstruction layer.

## 1. Define the Independent-Verifier Threat Model

The second verifier MUST distrust:

```text
original CI status
original JSON status fields
original shell exit codes
original "verified=true" booleans
original stdout claims
prebuilt Peregrine success
prebuilt MetaRocq success
standalone CakeML compiler output
```

It MAY trust only the explicitly selected foundation:

```text
pinned HOL4 kernel/source build
pinned CakeML formal theories
explicit approved assumptions
cryptographic identity checks as artifact binding, NOT semantic proof
```

Everything else is input data to be reconstructed/rechecked.

## 2. Create a Dedicated Fresh-Replay Driver

Create:

```text
tools/peregrine-selfhost-revalidate.sh
```

Its normal invocation SHOULD be:

```bash
./tools/peregrine-selfhost-revalidate.sh \
  --machine generated/peregrine-selfhost/release/<artifact> \
  --fresh-root .aegis/revalidate
```

The driver must use a separate:

```text
.aegis/revalidate/hol4/
.aegis/revalidate/cakeml/
.aegis/revalidate/work/
```

rather than reusing the original theorem database/build directory.

The point is independent replay, not incremental build reuse.

## 3. Verify the Exact Machine Artifact BEFORE Reading Its Claims

Record:

```text
machine/container bytes
theorem-bound code-region bytes, if distinct
packaging format identity
capsule extraction path
```

If Level A is used and the theorem covers a machine-code representation rather than a final ELF, make the verifier start from that theorem-covered representation or explicitly apply the proved loader/container correspondence.

Do NOT silently begin from a post-linked file outside the theorem boundary.

## 4. Extract the Capsule Through a Theorem-Bound Mechanism

Preferred Level-A path:

```text
execute exact theorem-bound command:
  ExposeCertificate
```

whose CakeML/machine semantics theorem proves the returned bytes equal `exact_capsule_bytes`.

Alternative:

```text
extract capsule data from a proved container projection
```

Do NOT use a heuristic binary scanner and then identify the found bytes with the formal capsule.

Save:

```text
generated/peregrine-selfhost/revalidation/extracted-capsule.bin
generated/peregrine-selfhost/revalidation/extraction-evidence.txt
```

## 5. Parse the Capsule WITHOUT Trusting Its `status` Fields

The capsule contains data such as:

```text
pins
source/corpus identities
assumption ledger
OpenTheory article(s)
CakeML program identity
compiler configuration
expected theorem statement
```

The fresh verifier must treat fields like:

```text
accepted
valid
verified
proof_ok
```

as ordinary untrusted data if they exist at all.

The verifier derives validity only by reconstructing theorem objects.

## 6. Reconstruct the Exact HOL4/CakeML Environment

From the capsule manifest, checkout/build exactly:

```text
HOL4:
40dd5b03de658f4bd9e3f4225fb0f1602ac90467

CakeML:
e1650fc504837c0fbd3931cc5066914ffdc9d877
```

or the exact future reviewed pins stored in the release capsule.

Then rebuild/import:

```text
required CakeML theories
required local Peregrine selfhost HOL4 theories
OpenTheory name maps/base package dependencies
approved assumption policy
```

The verifier MUST fail if a required dependency cannot be reconstructed exactly.

## 7. Replay the Embedded OpenTheory Article with HOL4's Official Reader

Use the official interface:

```sml
OpenTheoryIO.article_to_thm
```

or the lower-level:

```sml
OpenTheoryReader.raw_read_article
```

when you need explicit reader policy/audit control.

The resulting object MUST be a HOL4 `thm`.

Immediately inspect:

```sml
Thm.hyp th
Tag.dest_tag (Thm.tag th)
Thm.concl th
```

and compare them against the explicit expected theorem/assumption policy from the capsule.

Do NOT accept an article that imports only because an unexpected theorem/axiom happens to exist in a dirty global HOL4 database.

## 8. Reconstruct the Exact CakeML Program from the Capsule

The fresh verifier needs the exact program `K` that the embedded core theorem refers to.

Use ONE canonical path:

```text
embedded canonical CakeML serialization
   -> CakeML verified/in-logic parser
   -> exact HOL CakeML value K
```

or:

```text
embedded generated HOL definition source
   -> rebuild exact theory
   -> K
```

Prove/check:

```text
K identity in replayed core theorem
=
K reconstructed by the fresh verifier
```

A SHA-256 equality MAY support the audit but MUST NOT replace the theorem-level identity.

## 9. Re-run `eval_cake_compile_x64` in the FRESH HOL4 Instance

Invoke the same official theorem-producing compiler evaluator on reconstructed `K`:

```sml
val fresh_compiled =
  eval_cake_compile_x64
    ""
    reconstructed_peregrine_prog_def
    fresh_output_asm
  |> check_thm;
```

This produces a fresh theorem for the exact compilation result.

Compare the theorem-bound machine representation with the code identity extracted from the release artifact.

If they differ:

```text
REVALIDATION = FAIL
```

Do NOT fall back to comparing only emitted assembly text.

## 10. Re-specialize CakeML Compiler Correctness

Follow the SAME official CakeML proof pattern as Milestone 06:

```text
fresh core theorem
+
fresh eval_cake_compile_x64 theorem
+
compile_correct
+
x64_backend_config_ok
+
x64_machine_config_ok
+
x64_init_ok
        v
fresh outer machine theorem
```

The fresh verifier should construct a theorem equivalent to:

```text
FreshPeregrineSelfHostE2E
```

whose conclusion is alpha-equivalent/definitionally equivalent to the release theorem statement, instantiated for the same exact artifact identities.

## 11. Prove the "Binary Refines the Proof of Its Validation Process" Statement Precisely

Do NOT use an informal self-reference claim.

The precise theorem architecture is:

```text
C contains a kernel-checkable proof of Core(K,C)

HOL4 proves:
  Compile(K) = M

HOL4 proves:
  MachineSemantics(M) refines CakeMLSemantics(K)

Core(K,C) includes:
  complete retained proof replay
  exact source/LambdaBox relation
  exact LambdaBox/CakeML relation
  exact capsule correspondence
```

Therefore the outer theorem proves:

```text
MachineSemantics(M)
  refines
PeregrineSelfHostSpec(C)
```

where `C` includes the replayable proof of the validation process itself.

That is the non-circular formal meaning of:

```text
"the binary refines the HOL4 proofs of this validation process itself E2E"
```

The theorem does NOT need the final byte string to be an axiom inside its own proof object.

## 12. Compare Fresh and Original Theorem Artifacts

Record both:

```text
original theorem conclusion
fresh theorem conclusion
original theorem assumptions/tags
fresh theorem assumptions/tags
original exact artifact record
fresh exact artifact record
```

Require:

```text
same logical theorem statement
same approved assumption policy
same source/proof/LambdaBox/CakeML identities
same theorem-bound machine identity
```

The raw serialized internal HOL4 theorem object bytes do NOT need to be identical unless you separately prove deterministic theorem serialization.

Logical identity + exact artifact identity is the primary target.

## 13. Run the Fresh Verifier in a Clean Network-Isolated Environment

After all immutable source archives are available, prefer:

```bash
unshare -n -- \
  ./tools/peregrine-selfhost-revalidate.sh \
  --machine <artifact> \
  --fresh-root .aegis/revalidate
```

This demonstrates the verification does not secretly fetch a new theorem/source revision during replay.

Network isolation is a reproducibility hardening measure.

It is not itself proof evidence.

## 14. Add Independent-Replay Mutation Tests

Every mutation below MUST prevent `FreshPeregrineSelfHostE2E` from being produced:

1. alter one embedded OpenTheory opcode/byte;
2. alter the expected theorem statement;
3. remove one dependency theory from the capsule manifest;
4. change HOL4 commit;
5. change CakeML commit;
6. alter the reconstructed CakeML AST;
7. mutate one theorem-bound machine-code byte;
8. use an unexpected HOL4 DB axiom;
9. change one approved assumption into an unapproved one;
10. substitute a capsule from another build;
11. use a different `ExposeCertificate` implementation;
12. feed a stale machine manifest while leaving the binary unchanged.

## 15. Emit an Independent Revalidation Bundle

Create:

```text
generated/peregrine-selfhost/revalidation/
  machine-identity.json
  extracted-capsule.bin
  capsule-manifest.json
  imported-core-theorem.txt
  imported-core-theorem-tags.txt
  fresh-compile-theorem.txt
  fresh-machine-theorem.txt
  fresh-e2e-theorem.txt
  assumptions.txt
  dependencies.txt
  comparison.json
  SHA256SUMS
```

This bundle is audit evidence.

The authoritative semantic result remains the newly constructed HOL4 theorem.

## Completion Gate

This milestone is complete only when:

- a fresh independent HOL4 build can extract/read the theorem-bound capsule;
- the embedded proof is reconstructed as a real HOL4 theorem through official proof-reading/rebuilding machinery;
- exact dependencies/assumptions are reconstructed and audited;
- the exact CakeML program is reconstructed;
- `eval_cake_compile_x64` is rerun in the fresh HOL4 instance;
- the fresh compiler result matches the theorem-bound machine representation;
- CakeML compiler correctness is re-specialized;
- a fresh `PeregrineSelfHostE2E` theorem is produced;
- every semantically relevant capsule/program/machine mutation blocks revalidation.

## References

### MetaRocq

- MetaRocq architecture, verified SafeChecker, quotation and erasure: https://github.com/MetaRocq/metarocq/blob/9.1/README.md
- MetaRocq package/install structure: https://github.com/MetaRocq/metarocq/blob/9.1/INSTALL.md

### Peregrine

- Exact Peregrine pipeline used by the selfhost artifact: https://github.com/peregrine-project/peregrine-tool/blob/d768b83ffa7dab35b8d72241f0570b5bb6aedae9/theories/Pipeline.v
- Official CakeML backend project: https://github.com/peregrine-project/cakeml-backend
- Exact verified compile proof baseline: https://github.com/peregrine-project/cakeml-backend/blob/5baed0b21618480b30711eb9df87e9bf00537372/theories/Backend/CompileCorrect.v

### CakeML

- Exact theorem-producing compiler evaluator API: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/cv_translator/eval_cake_compileLib.sig
- Exact x64 compiler wrapper: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/cv_translator/eval_cake_compile_x64Lib.sml
- Official program-specific machine proof composition example: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/examples/compilation/x64/proofs/helloProofScript.sml

### HOL4

- Official theorem/article transport API: https://github.com/HOL-Theorem-Prover/HOL/blob/40dd5b03de658f4bd9e3f4225fb0f1602ac90467/src/opentheory/postbool/OpenTheoryIO.sig
- Official implementation of article import/export: https://github.com/HOL-Theorem-Prover/HOL/blob/40dd5b03de658f4bd9e3f4225fb0f1602ac90467/src/opentheory/postbool/OpenTheoryIO.sml
- Official OpenTheory reader contract: https://github.com/HOL-Theorem-Prover/HOL/blob/40dd5b03de658f4bd9e3f4225fb0f1602ac90467/src/opentheory/reader/OpenTheoryReader.sig
