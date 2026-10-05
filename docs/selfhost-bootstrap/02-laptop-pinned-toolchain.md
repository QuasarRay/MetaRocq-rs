# Milestone 02 — Reproduce the Entire Pinned Toolchain on CachyOS

## Objective

Build the complete development environment locally on the laptop WITHOUT depending on globally mutable MetaRocq, Peregrine, HOL4, or CakeML installations.

The local environment MUST reproduce the repository pins before any new proof is accepted.

## 1. Install host prerequisites

On CachyOS/Arch, install the host packages required to build the pinned Rocq/OCaml and HOL4/CakeML stacks:

```bash
sudo pacman -Syu --needed \
  base-devel git curl wget jq rsync tar gzip xz unzip diffutils patch \
  make cmake ninja m4 pkgconf gmp opam ocaml dune polyml z3
```

Verify that the tools resolve from PATH:

```bash
git --version
opam --version
ocamlc -version
poly --version
z3 --version
```

Do not treat host package versions as proof identities. They are bootstrap dependencies. All proof-producing source repositories MUST be pinned by commit.

## 2. Clone MetaRocq-rs and preserve the existing branch stack

Use a dedicated checkout:

```bash
mkdir -p ~/src
cd ~/src
git clone https://github.com/QuasarRay/MetaRocq-rs.git
cd MetaRocq-rs

git fetch --all --tags --prune
git checkout experiment/original-metarocq-selfhost-08-pcuic-certificate-reconciled
git status --short
```

The documentation stack was created from:

```text
85e161cf735423130049905816de0980ee45256c
```

Do not reset a newer branch back to this commit. Instead, record the current branch head and confirm that the pinned source manifests remain unchanged or were updated by an explicit reviewable PR.

Recommended:

```bash
mkdir -p generated/e2e
git rev-parse HEAD | tee generated/e2e/metarocq-rs-head.txt
git diff --exit-code
```

## 3. Materialize the repository-pinned upstream sources

The repository already contains bootstrap logic for MetaRocq and Peregrine.

Run:

```bash
python3 tools/bootstrap.py sources
```

Verify the exact revisions:

```bash
git -C .aegis/references/metarocq rev-parse HEAD
git -C .aegis/references/peregrine rev-parse HEAD
```

Expected baseline identities:

```text
MetaRocq
7197056adbb9c15288b4c8d43407bf25786f723e

Peregrine
d768b83ffa7dab35b8d72241f0570b5bb6aedae9
```

If either differs, STOP and inspect `spec/toolchain.lock.json` and `spec/upstream.lock.json`. Do not silently use the new revision.

## 4. Build the isolated MetaRocq/Peregrine opam switch

Reuse the project installer:

```bash
export OPAMROOT="$PWD/.aegis/opam-root"
export OPAMJOBS="$(nproc)"
bash tools/install_extraction.sh
```

For fish:

```fish
set -x OPAMROOT "$PWD/.aegis/opam-root"
opam env --switch .aegis/opam --shell=fish | source
```

For a bash subshell:

```bash
eval "$(opam env --switch .aegis/opam --set-switch)"
```

Confirm:

```bash
rocq -v
opam list --switch .aegis/opam | grep -E 'rocq|metarocq|peregrine'
```

Archive the successful switch description:

```bash
opam switch export --switch .aegis/opam generated/e2e/opam-switch.export
sha256sum generated/e2e/opam-switch.export > generated/e2e/opam-switch.export.sha256
```

## 5. Build the pinned HOL4 checkout

The current repository pin is:

```text
40dd5b03de658f4bd9e3f4225fb0f1602ac90467
```

Materialize it:

```bash
rm -rf .aegis/hol4
git clone https://github.com/HOL-Theorem-Prover/HOL.git .aegis/hol4
git -C .aegis/hol4 checkout --detach 40dd5b03de658f4bd9e3f4225fb0f1602ac90467
git -C .aegis/hol4 diff --exit-code
```

Configure with Poly/ML and build:

```bash
cd .aegis/hol4
poly < tools/smart-configure.sml
bin/build --no-helpdocs
cd ../..
```

Record the identity:

```bash
git -C .aegis/hol4 rev-parse HEAD > generated/e2e/hol4-head.txt
.aegis/hol4/bin/hol --help >/dev/null
```

Do NOT use a different globally installed HOL binary to produce final evidence.

## 6. Materialize the pinned CakeML source

Use the CakeML source identity already referenced by the current selfhost metatheory contract:

```text
c98da7fc904c5d6d0e9a75a18fac1796a9bfb1f9
```

Materialize it:

```bash
rm -rf .aegis/cakeml
git clone https://github.com/CakeML/cakeml.git .aegis/cakeml
git -C .aegis/cakeml checkout --detach c98da7fc904c5d6d0e9a75a18fac1796a9bfb1f9
git -C .aegis/cakeml diff --exit-code
git -C .aegis/cakeml rev-parse HEAD > generated/e2e/cakeml-head.txt
```

Before the final publication run, move this identity into the single E2E scope manifest from Milestone 01 if it is not already there.

## 7. Run the existing reconciled selfhost build locally

Do this BEFORE modifying the proof architecture. It gives you a baseline failure/success point.

```bash
eval "$(opam env --switch .aegis/opam --set-switch)"

mkdir -p generated/original-selfhost
Q='-Q metatheory/original-selfhost MetaRocqRs.OriginalSelfHost'

for f in \
  PipelineIR.v OpenTheoryIR.v PCUICModuleManifest.v SelfSnapshot.v \
  MaterializeSnapshot.v HOLProofIR.v OpenTheorySerialize.v \
  RuntimeImage.v RetainedPayload.v SelfHostRunner.v ExtractionRoot.v \
  HOL4ReuseManifest.v CandleMachineChain.v CandlePrefixManifest.v \
  PCUICCertificateIR.v PCUICDeepEmbeddingSchema.v SafeCheckerContract.v \
  CertificateReplayIR.v HOL4RoundTripIR.v CandleExportContract.v \
  DeepEmbeddingStatus.v DualProofLedger.v SelfCICD.v \
  SelfCICDInterpreter.v SingleImageContract.v SingleImageEntrypoint.v \
  EmbeddedPeregrine.v MetaRocqSuffixSafety.v CandlePrefixComposition.v \
  CakeMLBackendTrustLedger.v CandidateCakeMLCompiler.v \
  CakeMLTranslationCertificate.v ValidatedCakeMLGateway.v \
  RecursiveSelfIdentity.v SharedImageEntrypoint.v \
  ValidatedSharedImageEntrypoint.v EAstSupportedFragment.v \
  CakeMLNoRaise.v CheckedCandidateCakeML.v \
  CheckedSharedImageEntrypoint.v ReflectiveDualRecursion.v \
  ReconciledSelfHostEntrypoint.v ExtractReconciledSelfHost.v
do
  rocq compile $Q "metatheory/original-selfhost/$f"
done

test -s generated/original-selfhost/reconciled-selfhost.ast
```

Record the output digest:

```bash
sha256sum generated/original-selfhost/reconciled-selfhost.ast \
  | tee generated/e2e/baseline-reconciled-selfhost.ast.sha256
```

## 8. Create a single environment report

Generate:

```text
generated/e2e/environment.txt
```

containing:

```bash
{
  uname -a
  git --version
  opam --version
  ocamlc -version
  poly --version
  z3 --version
  rocq -v
  git -C .aegis/references/metarocq rev-parse HEAD
  git -C .aegis/references/peregrine rev-parse HEAD
  git -C .aegis/hol4 rev-parse HEAD
  git -C .aegis/cakeml rev-parse HEAD
} > generated/e2e/environment.txt
```

Hash it:

```bash
sha256sum generated/e2e/environment.txt > generated/e2e/environment.txt.sha256
```

This report is provenance only. It is NOT a semantic proof.

## Completion gate

Do not continue until:

- the repository is clean;
- all pinned source revisions are exact;
- the isolated opam switch builds;
- HOL4 builds from the pinned source;
- CakeML source is present at the pinned revision;
- the existing reconciled selfhost extraction can be reproduced locally or its exact failure is recorded;
- all baseline identities are written into `generated/e2e/`.

## References

### MetaRocq

- Official MetaRocq installation instructions: https://github.com/MetaRocq/metarocq/blob/9.1/INSTALL.md
- Official MetaRocq overview: https://github.com/MetaRocq/metarocq/blob/9.1/README.md

### CakeML

- CakeML source repository: https://github.com/CakeML/cakeml
- CakeML verified compiler backend: https://cakeml.org/jfp19.pdf

### HOL4

- Official HOL4 installation instructions: https://hol-theorem-prover.org/install
- HOL4 developer build instructions: https://hol-theorem-prover.org/docs/trindemossen-2/Developers/
- HOL4 source repository: https://github.com/HOL-Theorem-Prover/HOL
