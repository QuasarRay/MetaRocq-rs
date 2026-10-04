# 02 — Clone, Pin, and Audit Peregrine + Every Dependency Required by the Self-Hosting Chain

> **UNIFIED SEQUENCE STEP 02 OF 22 — PEREGRINE TRUST FOUNDATION.**  
> Reused from `docs/peregrine-selfhost-certificate/01-clone-pin-and-audit-peregrine.md` on `docs/peregrine-selfhost-03-independent-replay`. The original manual remains preserved. This copy reorders and connects the existing instructions into the unified Peregrine -> MetaRocq E2E sequence. Execute this file completely before continuing to the next numbered file.

## Objective

Create a completely separate, immutable Peregrine source checkout for the self-hosting experiment.

The checkout MUST be suitable for answering all of these questions later:

```text
Which exact Peregrine source was quoted?
Which exact proof files were in scope?
Which exact LambdaBox pipeline was extracted?
Which exact external repositories supplied the CakeML path?
Which exact source revisions generated the final machine artifact?
```

Do NOT develop directly inside a floating clone of `master`.

## REUSE

Reuse the host/toolchain layout from:

```text
docs/selfhost-bootstrap/02-laptop-pinned-toolchain.md
docs/selfhost-bootstrap/11-local-operation-debugging-and-recovery.md
```

Continue using:

```text
.aegis/references/
generated/e2e/
```

Do NOT create another unrelated dependency cache.

## 1. Freeze the Peregrine Commit

The audited Peregrine revision used by the existing MetaRocq-rs toolchain is:

```text
repository:
https://github.com/peregrine-project/peregrine-tool.git

commit:
d768b83ffa7dab35b8d72241f0570b5bb6aedae9
```

Use that revision as the initial self-hosting baseline unless a later PR deliberately updates the pin.

Record it in a dedicated manifest, for example:

```text
spec/peregrine-selfhost.lock.json
```

with at least:

```json
{
  "peregrine": {
    "repository": "https://github.com/peregrine-project/peregrine-tool.git",
    "commit": "d768b83ffa7dab35b8d72241f0570b5bb6aedae9"
  }
}
```

## 2. Clone Using Recursive-Submodule Semantics

Even though the audited revision currently contains NO `.gitmodules`, use the future-proof command:

```bash
rm -rf .aegis/references/peregrine-selfhost

git clone \
  --recurse-submodules \
  --jobs "$(nproc)" \
  https://github.com/peregrine-project/peregrine-tool.git \
  .aegis/references/peregrine-selfhost
```

Then pin it:

```bash
git -C .aegis/references/peregrine-selfhost \
  checkout --detach d768b83ffa7dab35b8d72241f0570b5bb6aedae9
```

Synchronize/update recursively anyway:

```bash
git -C .aegis/references/peregrine-selfhost \
  submodule sync --recursive

git -C .aegis/references/peregrine-selfhost \
  submodule update --init --recursive
```

## 3. Mechanically Verify the Current Submodule Set

Run:

```bash
if test -f .aegis/references/peregrine-selfhost/.gitmodules; then
  cat .aegis/references/peregrine-selfhost/.gitmodules
else
  printf '%s\n' 'NO .gitmodules AT PINNED PEREGRINE REVISION'
fi

git -C .aegis/references/peregrine-selfhost \
  submodule status --recursive \
  | tee generated/e2e/peregrine-submodules.txt
```

At the audited revision, an empty `submodule status` result is EXPECTED.

Do NOT invent synthetic “submodules” just because the project has external dependencies.

A Git dependency and a Git submodule are not the same thing.

## 4. Verify the Exact Peregrine Repository Identity

Run:

```bash
test "$(
  git -C .aegis/references/peregrine-selfhost rev-parse HEAD
)" = "d768b83ffa7dab35b8d72241f0570b5bb6aedae9"

git -C .aegis/references/peregrine-selfhost diff --exit-code
```

Record:

```bash
{
  git -C .aegis/references/peregrine-selfhost remote -v
  git -C .aegis/references/peregrine-selfhost rev-parse HEAD
  git -C .aegis/references/peregrine-selfhost status --porcelain=v1
  git -C .aegis/references/peregrine-selfhost submodule status --recursive
} > generated/e2e/peregrine-source-identity.txt
```

The final line MUST remain empty unless a future pinned revision genuinely introduces submodules.

## 5. Clone the Separate Official Peregrine CakeML Backend

The CakeML backend proof repository is separate:

```text
https://github.com/peregrine-project/cakeml-backend.git
```

It is NOT a submodule of `peregrine-tool`.

Create:

```bash
rm -rf .aegis/references/peregrine-cakeml-selfhost

git clone \
  https://github.com/peregrine-project/cakeml-backend.git \
  .aegis/references/peregrine-cakeml-selfhost
```

Do NOT immediately decide that `main` is proof-authoritative.

The source audit on 2026-10-04 found:

```text
main head:
a5df761d5032b01ae66fc82965f1a79f313e1bbc

README/_RocqProject CLAIM:
  CompileCorrect.v
  PipelineCorrect.v
  verified_cakeml_pipeline_theorem

actual tree at that commit:
  Compile.v
  FFI.v
  Pipeline.v
  Serialize.v

missing:
  CompileCorrect.v
  PipelineCorrect.v
```

A separate branch:

```text
verified-compile-correct
```

contained `CompileCorrect.v`, but the audited branch still did NOT contain `PipelineCorrect.v`.

Therefore pin TWO identities if necessary:

```text
candidate backend source revision
proof-development revision
```

until one reviewed upstream commit contains the entire proof path.

## 6. Record the CakeML Backend Availability Matrix

Generate a deterministic audit:

```bash
for ref in \
  main \
  verified-compile-correct \
  rocq-9.1
do
  printf '=== %s ===\n' "$ref"

  git -C .aegis/references/peregrine-cakeml-selfhost     ls-tree -r --name-only "$ref" \
    | grep -E '^theories/Backend/(Compile|CompileCorrect|Pipeline|PipelineCorrect|Serialize)\.v$' \
    || true
done | tee generated/e2e/peregrine-cakeml-proof-files.txt
```

The publication driver MUST later reject a proof revision if any mandatory proof file is absent.

## 7. Freeze the CakeML Semantic Revision Used by the Peregrine Backend

The official backend README states that its CakeML formalization mirrors:

```text
CakeML commit:
e1650fc504837c0fbd3931cc5066914ffdc9d877
```

For this Peregrine-specific selfhost stack, prefer aligning the downstream CakeML/HOL4 compilation stage to this revision.

Record:

```json
{
  "cakeml_semantics_required_by_peregrine_backend":
    "e1650fc504837c0fbd3931cc5066914ffdc9d877"
}
```

Do NOT silently reuse another CakeML commit merely because the AST looks similar.

If you intentionally retain the older MetaRocq-rs CakeML pin, the compatibility theorem described in the previous manual becomes mandatory.

## 8. Enumerate the Peregrine Formal Source Roots

The source of the formally extractable Peregrine core is under:

```text
theories/
```

The host CLI and generated support code are in:

```text
bin/
src/
plugin/
hs-lib/
```

For the self-hosted LambdaBox program, distinguish:

### Formal program roots

```text
theories/Pipeline.v
theories/PAst.v
theories/Config.v
theories/ConfigUtils.v
theories/Transforms.v
theories/Erasure.v
theories/CheckWf.v
theories/NameSanitize.v
theories/backends/*.v
theories/serialization/*.v
```

plus their transitive Rocq dependencies.

### Host/bootstrap wrappers

```text
bin/
src/
plugin/
```

These MAY execute the bootstrap.

They MUST NOT automatically be identified with the formally extracted Peregrine core.

## 9. Freeze the Executable Peregrine Root

The official core pipeline source defines:

```coq
Definition peregrine_pipeline
  (c : string + config')
  (attrs : list string)
  (p : string)
  (f : string)
  : extraction_result := ...
```

and:

```coq
Definition peregrine_validate
  (c : string + config')
  (attrs : list string)
  (p : string)
  : result' unit := ...
```

These are the correct initial formal executable roots.

Create a selfhost manifest containing exact kernel names for:

```text
Peregrine.Pipeline.peregrine_pipeline
Peregrine.Pipeline.peregrine_validate
```

plus the NEW proof-replay entrypoint that will be added in the next milestone.

## 10. Audit the Existing CakeML Backend for Forbidden Proof Shortcuts

At the pinned Peregrine revision, inspect:

```text
theories/backends/CakeMLBackend.v
```

The audited source includes:

```coq
Final Obligation.
Admitted.
```

and:

```coq
Axiom trust_coq_kernel : forall p, pre cakeml_pipeline p.
```

Therefore define policy:

```text
ordinary Peregrine CakeML backend execution:
  ALLOWED AS CANDIDATE GENERATOR

ordinary Peregrine CakeML backend's trust_coq_kernel:
  FORBIDDEN AS FINAL PROOF EVIDENCE
```

Add these exact names to the assumption-denylist.

## 11. Verify No Local Changes Before Every Proof Run

Use:

```bash
git -C .aegis/references/peregrine-selfhost diff --exit-code

git -C .aegis/references/peregrine-cakeml-selfhost diff --exit-code
```

If you must patch upstream source to close a proof obligation:

1. create a fork/branch;
2. commit the change;
3. pin that exact commit;
4. document the theorem it closes;
5. never leave proof-producing changes as dirty working-tree modifications.

## Completion Gate

This milestone is complete only when:

- Peregrine is cloned with recursive-submodule semantics;
- the current empty submodule set is explicitly verified, not assumed;
- the exact Peregrine commit is detached and clean;
- the separate CakeML backend repository is cloned and audited;
- proof-file availability is recorded by ref;
- the exact CakeML semantic revision is frozen;
- formal Rocq roots are separated from host wrappers;
- `peregrine_pipeline` and `peregrine_validate` are fixed as core executable roots;
- `Admitted` and `trust_coq_kernel` are explicitly forbidden from final proof evidence.

## References

### MetaRocq

- MetaRocq package/tool architecture used by Peregrine's Rocq frontend: https://github.com/MetaRocq/metarocq/blob/9.1/README.md
- MetaRocq installation/package layout: https://github.com/MetaRocq/metarocq/blob/9.1/INSTALL.md

### Peregrine

- Official source-cloning/build instructions: https://github.com/peregrine-project/peregrine-tool/blob/master/doc/dev.md
- Official project structure: https://github.com/peregrine-project/peregrine-tool/blob/master/doc/dev.md
- Official pipeline source: https://github.com/peregrine-project/peregrine-tool/blob/d768b83ffa7dab35b8d72241f0570b5bb6aedae9/theories/Pipeline.v
- Official CakeML backend source showing the candidate execution path: https://github.com/peregrine-project/peregrine-tool/blob/d768b83ffa7dab35b8d72241f0570b5bb6aedae9/theories/backends/CakeMLBackend.v
- Official separate CakeML backend repository: https://github.com/peregrine-project/cakeml-backend

### CakeML

- CakeML source revision mirrored by the Peregrine CakeML backend: https://github.com/CakeML/cakeml/tree/e1650fc504837c0fbd3931cc5066914ffdc9d877
- CakeML theorem-producing x64 compiler evaluator: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/cv_translator/eval_cake_compile_x64Lib.sml

### HOL4

- Official HOL4 source repository: https://github.com/HOL-Theorem-Prover/HOL
- HOL4 theorem export infrastructure used later for portable proof artifacts: https://github.com/HOL-Theorem-Prover/HOL/blob/40dd5b03de658f4bd9e3f4225fb0f1602ac90467/src/opentheory/postbool/Logging.sig
