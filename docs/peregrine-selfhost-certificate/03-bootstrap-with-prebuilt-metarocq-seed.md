# 03 — Execute the Peregrine Selfhost Pipeline Using an Independent PREBUILT MetaRocq Seed

## Objective

Materialize:

```text
generated/peregrine-selfhost/peregrine-selfhost.ast
```

by executing the MetaRocq/Peregrine extraction driver using a PRE-EXISTING bootstrap seed.

The seed MUST exist before the new Peregrine selfhost LambdaBox artifact exists.

The build MUST record exactly which seed executed the pipeline.

## REUSE

Reuse the isolated opam/bootstrap environment from:

```text
docs/selfhost-bootstrap/02-laptop-pinned-toolchain.md
```

Reuse the provenance/fail-closed rules from:

```text
docs/selfhost-bootstrap/11-local-operation-debugging-and-recovery.md
docs/selfhost-bootstrap/12-final-audit-and-publication-gate.md
```

Do NOT let a seed produced by the current unverified build silently become the authority for itself.

## 1. Understand What “Prebuilt MetaRocq Binary” Actually Means

MetaRocq is primarily distributed as Rocq packages/plugins/libraries.

Therefore the normal executable process is:

```text
prebuilt rocq executable
  + prebuilt rocq-metarocq-* plugin packages
  + .v driver
  => execute MetaRocq commands
```

Do NOT call an opam package a standalone `metarocq` executable if no such executable exists.

The seed-selection logic must distinguish:

```text
A. actual standalone MetaRocq-rs executable artifact
B. prebuilt Rocq executable + MetaRocq plugin/package environment
C. source-built MetaRocq bootstrap environment
```

## 2. Current MetaRocq-rs Artifact Reality

At the audited MetaRocq-rs state, the reconciled selfhost workflow uploads:

```text
generated/original-selfhost/
metatheory/original-selfhost/*.vo
metatheory/original-selfhost/*.vos
metatheory/original-selfhost/*.glob
```

and produces:

```text
generated/original-selfhost/reconciled-selfhost.ast
```

It does NOT currently define a release containing a standalone executable named `metarocq`.

The repository also had no GitHub Release providing such a binary at the audit time.

Therefore:

```text
MetaRocq-rs binary preference = policy for a real future artifact
current expected bootstrap path = prebuilt Rocq + MetaRocq packages
```

Do NOT fake compliance by renaming `rocq` to `metarocq`.

## 3. Define the Seed Priority Order

Implement the seed resolver with this exact priority:

```text
PRIORITY 1
  MetaRocq-rs standalone executable artifact

PRIORITY 2
  prebuilt pinned Rocq + MetaRocq package/plugin switch

PRIORITY 3
  one-time build of exact pinned MetaRocq source
```

The resolver MUST emit one of:

```text
SEED_METAROCQ_RS_BINARY
SEED_PREBUILT_METAROCQ_PLUGIN
SEED_SOURCE_BUILT_METAROCQ
BLOCKED
```

## 4. Requirements for PRIORITY 1 — MetaRocq-rs Binary Artifact

Do NOT use an arbitrary executable merely because its filename contains `metarocq`.

A Priority-1 seed MUST have:

```text
artifact path
SHA-256
source repository commit
MetaRocq upstream commit
build workflow/run identity
target architecture
invocation contract
version/report command
proof/trust status
```

Create a seed manifest:

```text
generated/e2e/bootstrap-seed.json
```

Example schema:

```json
{
  "kind": "SEED_METAROCQ_RS_BINARY",
  "path": "...",
  "sha256": "...",
  "metarocq_rs_commit": "...",
  "metarocq_upstream_commit": "...",
  "invocation_mode": "...",
  "source": "github-actions-artifact"
}
```

### Mandatory invocation rule

A MetaRocq-rs binary is usable only if its artifact documents how to execute the equivalent of the selfhost driver.

If the binary has no supported interface for:

```text
quote exact Peregrine root
materialize retained corpus
run Peregrine Extract
write exact .ast
```

then it is NOT a usable seed for this milestone.

Skip to Priority 2.

Do NOT invent undocumented command-line flags.

## 5. Discover Priority-1 Artifacts Without Trusting Names

If you have downloaded candidate Actions artifacts, inspect them:

```bash
find . \
  -type f \
  -perm -u+x \
  \( -iname '*metarocq*' -o -iname '*selfhost*' \) \
  -print
```

For each candidate:

```bash
file /path/to/candidate
sha256sum /path/to/candidate
```

Then compare against its GitHub Actions artifact metadata/provenance.

If no executable artifact exists, record:

```json
{
  "priority_1": "NOT_AVAILABLE"
}
```

and continue.

Absence is not a failure if Priority 2 is available.

## 6. Use PRIORITY 2 — Prebuilt Rocq + MetaRocq Packages

This is the currently expected path.

The existing MetaRocq-rs installer creates an isolated switch:

```text
.aegis/opam
```

with pinned MetaRocq/Peregrine dependencies.

Activate it:

```bash
export OPAMROOT="$PWD/.aegis/opam-root"

eval "$(opam env --switch .aegis/opam --set-switch)"
```

Verify that the executable and packages are already installed:

```bash
command -v rocq
rocq -v

opam list --switch .aegis/opam \
  | grep -E 'rocq-(core|stdlib|metarocq|peregrine)|metarocq|peregrine'
```

Record:

```bash
{
  command -v rocq
  rocq -v
  opam list --switch .aegis/opam
} > generated/e2e/bootstrap-seed-prebuilt-packages.txt
```

Hash the report:

```bash
sha256sum \
  generated/e2e/bootstrap-seed-prebuilt-packages.txt \
  > generated/e2e/bootstrap-seed-prebuilt-packages.txt.sha256
```

## 7. Make Sure Priority 2 Is Actually PREBUILT for This Run

The seed phase MUST be separated from the selfhost phase.

Recommended sequence:

```text
PHASE S0:
  provision MetaRocq/Rocq/Peregrine packages

FREEZE SEED

PHASE S1:
  build NEW Peregrine selfhost formalization

PHASE S2:
  execute selfhost extraction using frozen S0 seed
```

After S0, record a switch export:

```bash
opam switch export \
  --switch .aegis/opam \
  generated/e2e/bootstrap-seed.opam.export
```

Then do NOT rebuild MetaRocq during S1/S2.

This prevents the new selfhost source from silently changing its own bootstrap authority.

## 8. Use PRIORITY 3 Only When No Prebuilt Seed Exists

If a clean machine has no appropriate prebuilt MetaRocq packages:

1. clone exact pinned MetaRocq source;
2. build/install it ONCE into a dedicated seed switch;
3. freeze that switch;
4. record every source commit/package version;
5. execute the selfhost pipeline afterward.

Use a separate location:

```text
.aegis/metarocq-seed-opam-root/
.aegis/metarocq-seed-opam/
```

Do NOT build the seed inside the same output directory as the selfhost target.

The final proof theorem does not automatically prove the bootstrap seed itself.

The seed is a provenance/trust input whose result is later independently validated by HOL4.

## 9. Execute the Exact Driver with the Frozen Seed

For Priority 2, the actual execution is the prebuilt `rocq` binary loading prebuilt MetaRocq/Peregrine plugins and compiling the NEW driver.

Run:

```bash
export OPAMROOT="$PWD/.aegis/opam-root"
eval "$(opam env --switch .aegis/opam --set-switch)"

mkdir -p generated/peregrine-selfhost

Q='-Q metatheory/peregrine-selfhost MetaRocqRs.PeregrineSelfHost'

rocq compile $Q \
  metatheory/peregrine-selfhost/PeregrineSourceManifest.v

rocq compile $Q \
  metatheory/peregrine-selfhost/PeregrineSnapshot.v

rocq compile $Q \
  metatheory/peregrine-selfhost/PeregrineCertificateIR.v

rocq compile $Q \
  metatheory/peregrine-selfhost/PeregrineReplay.v

rocq compile $Q \
  metatheory/peregrine-selfhost/PeregrineSelfHostRoot.v

rocq compile $Q \
  metatheory/peregrine-selfhost/ExtractPeregrineSelfHost.v
```

The final `ExtractPeregrineSelfHost.v` MUST execute the exact `Peregrine Extract` instruction over:

```text
peregrine_selfhost_entrypoint
```

not a smaller testing root.

## 10. Bind the Seed to the Produced LambdaBox Artifact

Immediately record:

```bash
test -s generated/peregrine-selfhost/peregrine-selfhost.ast

sha256sum \
  generated/peregrine-selfhost/peregrine-selfhost.ast \
  > generated/e2e/peregrine-selfhost-lambdabox.sha256
```

Generate:

```text
generated/e2e/peregrine-selfhost-bootstrap.json
```

containing:

```json
{
  "seed_kind": "...",
  "seed_identity": "...",
  "metarocq_commit": "...",
  "peregrine_commit": "...",
  "source_snapshot_digest": "...",
  "certificate_corpus_digest": "...",
  "assumption_ledger_digest": "...",
  "lambdabox_digest": "..."
}
```

Again: this manifest BINDS identities.

It does NOT prove semantics.

## 11. Immediately Validate the Produced LambdaBox Using a Different Path

Before the LambdaBox artifact is allowed downstream:

1. parse it using Peregrine's prebuilt validator;
2. run all structural wellformedness checks;
3. compare its retained identities with the source snapshot;
4. later replay it through the HOL4 proof chain.

The seed's correctness is therefore NOT trusted merely because it generated the file.

The architecture is:

```text
untrusted/pre-existing seed
       |
       v
candidate LambdaBox L
       |
       +--> structural independent checks
       |
       +--> later semantic HOL4 proof
```

## 12. Detect Accidental Circular Bootstrapping

Fail if:

- seed digest equals an artifact generated during the current S1/S2 build but no prior provenance exists;
- seed path is inside `generated/peregrine-selfhost/`;
- seed manifest was created after the target and cannot prove earlier provenance;
- current target binary is copied into the seed location;
- a stale LambdaBox artifact is reused without exact input-key match.

Add:

```bash
./tools/peregrine-selfhost-e2e.sh seed-audit
```

which MUST fail on those conditions.

## 13. Seed Reproducibility Test

From a clean checkout:

1. restore the same frozen seed;
2. build the same selfhost driver;
3. regenerate `peregrine-selfhost.ast`;
4. compare its exact digest.

If output differs:

```text
BLOCK downstream compilation
```

until the difference is explained.

Deterministic equality is a reproducibility property.

The semantic authority still comes later from HOL4.

## Completion Gate

This milestone is complete only when:

- a bootstrap seed is selected by explicit priority;
- a nonexistent MetaRocq-rs standalone executable is NOT fabricated;
- a real MetaRocq-rs binary is preferred if/when one exists and has an invocation contract;
- otherwise prebuilt Rocq + MetaRocq packages execute the driver;
- the seed predates/is independent from the new target artifact;
- exact seed provenance is recorded;
- the exact selfhost LambdaBox artifact is regenerated from the frozen seed;
- downstream validation does not trust seed success as semantic evidence.

## References

### MetaRocq

- Official MetaRocq package organization and installation: https://github.com/MetaRocq/metarocq/blob/9.1/INSTALL.md
- Official MetaRocq Template-Rocq quotation commands: https://github.com/MetaRocq/metarocq/blob/9.1/README.md
- Template Monad recursive quotation API: https://github.com/MetaRocq/metarocq/blob/9.1/template-rocq/theories/TemplateMonad/Core.v

### Peregrine

- Official Peregrine local build/install instructions: https://github.com/peregrine-project/peregrine-tool/blob/master/doc/dev.md
- Official Rocq frontend extraction interface: https://github.com/peregrine-project/peregrine-tool/blob/master/doc/frontends.md
- Peregrine extraction source showing its executable pipeline roots: https://github.com/peregrine-project/peregrine-tool/blob/d768b83ffa7dab35b8d72241f0570b5bb6aedae9/theories/Extraction.v

### CakeML

- CakeML in-logic compiler evaluation is intentionally distinct from trusting a standalone compiler: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/examples/compilation/x64/helloCompileScript.sml
- CakeML compiler-correctness composition for exact generated code: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/examples/compilation/x64/proofs/helloProofScript.sml

### HOL4

- HOL4 official repository: https://github.com/HOL-Theorem-Prover/HOL
- HOL4 proof export API used to independently transport later theorem evidence: https://github.com/HOL-Theorem-Prover/HOL/blob/40dd5b03de658f4bd9e3f4225fb0f1602ac90467/src/opentheory/postbool/OpenTheoryIO.sml
