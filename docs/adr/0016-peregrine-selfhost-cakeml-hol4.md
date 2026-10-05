# ADR 0016: Peregrine selfhost -> CakeML -> HOL4 recursive certificate

Status: implemented as a fail-closed producer architecture; the final E2E theorem is **not** claimed complete.

## Goal

Produce one executable lineage:

```text
pinned Peregrine Rocq source + complete retained proof corpus
  -> one self-reflective Peregrine LambdaBox artifact
  -> exact CakeML program
  -> CakeML in-logic compilation inside HOL4
  -> exact machine image
```

The final machine image is intended to carry the exact proof/certificate payload needed for another independent HOL4 instance to validate the same theorem statement and artifact identities.

## Implemented in this branch

1. The pinned Peregrine revision is fixed at `d768b83ffa7dab35b8d72241f0570b5bb6aedae9`.
2. Its exact `_CoqProject` contains 56 Rocq modules. The branch records that exact list and fails if it changes.
3. CI performs a recursive-submodule checkout. The pinned revision currently has no `.gitmodules` and no gitlink entries, so the current recursive submodule set is empty.
4. MetaRocq quotes every module and materializes the result as computational PCUIC data.
5. Every proof-bearing constant body is retained separately from every body-less source assumption.
6. The extracted entrypoint directly calls the real `Peregrine.Pipeline.peregrine_pipeline`, so the LambdaBox dependency graph reaches the actual Peregrine implementation.
7. The same entrypoint reaches the retained proof corpus, assumption ledger, and replay-job ledger, so ordinary erasure cannot discard them as irrelevant proofs.
8. The build prefers the existing MetaRocq-rs cached prebuilt Rocq/MetaRocq/Peregrine toolchain and runs that producer to generate the LambdaBox artifact.
9. The prebuilt native `peregrine cakeml` producer translates the exact LambdaBox artifact to an exact CakeML artifact.
10. A HOL4 qualification theory checks the fail-closed contract with `check_thm`.

## Authority model

The final statement is **not** “CakeML certifies that HOL4 is correct.”

The sound formulation is:

1. HOL4 checks the application-specific Peregrine/replay semantics theorem.
2. HOL4 evaluates CakeML compilation for the exact program.
3. HOL4 specializes CakeML compiler correctness to that exact compilation.
4. HOL4 checks the resulting source-to-machine theorem.
5. The compiled program carries a portable certificate/attestation payload.
6. HOL4 additionally proves that the payload in the machine program corresponds to the exact theorem/proof artifact being claimed.

The CakeML-side `CertificateRuntime.sml` is therefore a data carrier/interface, not a second proof authority.

## Why the final theorem remains blocked

The pinned upstream Peregrine CakeML wrapper still contains an admitted final obligation for `cakeml_pipeline` and `trust_coq_kernel`. The pinned separate CakeML backend also contains extraction/preservation trust gaps. This branch records and rejects those as final proof evidence.

Retaining a proof term is also not equivalent to replaying it. Remaining formal work includes constructing a faithful PCUIC dependency environment for every retained Peregrine theorem and proving SafeChecker replay soundness/completeness for the exact corpus.

## Recursive certificate design

The executable should not contain a cryptographic hash of its own complete byte string, because that creates an unnecessary fixed-point problem.

Instead the portable payload commits to:

- source snapshot;
- proof/replay corpus;
- LambdaBox artifact;
- exact CakeML program;
- final HOL4 theorem statement/proof representation.

The final HOL4 theorem then binds the *actual machine image* externally to the program that exposes that payload. A second HOL4 instance can independently replay/import the portable proof representation and check that the machine image exposes the same committed payload.

## Publication rule

No generated LambdaBox file, CakeML file, process exit code, replay Boolean, digest, or CI success is sufficient.

Publication remains blocked until `formal/hol4/PeregrineSelfHostE2EScript.sml` is a real HOL4 proof that composes:

```text
complete source/proof replay
  -> source/LambdaBox semantic refinement
  -> LambdaBox/CakeML semantic refinement
  -> exact CakeML program semantics
  -> eval_cake_compile_x64 theorem
  -> compile_correct + x64 obligations
  -> exact machine image
  -> embedded certificate correspondence
  -> independent replay claim
```
