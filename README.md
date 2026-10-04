# MetaRocq-rs: metatheory-first bootstrap

Aegis is embedded under `.agents` and pinned by `spec/aegis-deployment.json`.
The new sequential roadmap and append-only PostgreSQL context pipeline are in
`.agents/roadmaps`, `.agents/pipelines`, and `.agents/database`.

**The metatheory bootstrap is unfinished; implementation remains gated.**
See `docs/STATUS.md` and `docs/adr/0005-sequential-metatheory-bootstrap.md`.
The historical extraction workflow and evidence below are preserved.

# MetaRocq-rs

Goal: a Rust-native MetaRocq implementation, certified metaprogramming and independently
checkable proof-carrying macro expansions. The original MetaRocq mathematical sources
are the shared contract. This checkpoint establishes the supervised bootstrap.

The current checkpoint pins Aegis PR #17 and preserves the previous PR history and
the actual isApp extraction artifact. See `docs/STATUS.md` and ADR 0004.

**Current status: bootstrap infrastructure only. No Rust checker, verified macro
system or machine-code correctness proof exists at this checkpoint.**

`generated/pcuic_isapp.rs` and its typed AST are unchanged outputs from the earlier
successful Peregrine generation. A small syn/quote build transformation repairs
two observed printer errors, so this candidate now compiles. The original generated
application predicate passes a two-case runtime regression. This is not full refinement.

The new additive `Retention.v`/`Retained.v` driver quotes an original opaque PCUIC
proof and its dependency environment into AST data in Type. It asserts that the
opaque root body exists, then extracts the entire data structure. Execution of this
new extraction is being qualified separately; retaining syntax does not transfer a
theorem to Rust semantics or prove ownership correctness.

## Reproduce

Python 3.11+ and Git are sufficient to inspect the initial contract:

```sh
python -B tools/bootstrap.py sources
python -B tools/sync_instructions.py --check
python -B tools/bootstrap.py check
python -B tools/bootstrap.py bind
# With the pinned-compatible Rocq/Peregrine installation active:
python -B tools/bootstrap.py extract --timeout 600
cargo +1.98.1 test --workspace --locked
# After successful retained-proof generation:
cargo +1.98.1 test --workspace --locked --features retained
```

The extraction CI workflow builds the pinned source packages, runs this same driver,
and preserves generated files and diagnostics as artifacts. Its result must be
inspected before calling this slice usable. It is not a formal-equivalence job.
After implementing the API-specific harness, `python -B tools/bootstrap.py verify`
runs the declared Kani obligation. Missing source, harnesses or tools fail closed.

Commit the work and recorded evidence, push a branch, open a PR, then run:

```sh
python -B tools/bootstrap.py checkpoint --pr NUMBER
```

Each subsequent managed cycle must preserve its previous PR and stack on it.
The pinned external Aegis checkout is the actual controller used by these commands.

## Contract and proof status

- `AGENTS.MD` is canonical; `AGENTS.md` copies are generated in every tracked directory.
- `spec/upstream.lock.json` preserves original Rocq source identities.
- `spec/toolchain.lock.json` pins Aegis, MetaRocq, Peregrine and Kontroli.
- `.metarocq/plan.json` binds the first contract, reuse decision and intended Kani gate.
- `.metarocq/evidence/` preserves observed outcomes, including blocked attempts.
- `spec/obligations.json` and ADR 0001 list the remaining proof boundaries.

Peregrine's Rust backend/printer are unverified. HOL4 cannot directly consume these
Rocq .v specifications, and Z3_TAC does not automatically establish PCUIC metatheory,
Rust semantics, certified macros or compiler correctness. Those are explicit goals
requiring a proved semantic bridge and independently replayed certificates.

## Existing Kontroli infrastructure

The pinned Kontroli source contains the Aeneas/HOL4 interface discovery tool. After
obtaining real generated HOL4, reuse it without copying or relicensing its code:

```sh
python -B tools/bootstrap.py manifest --generated PATH_TO_GENERATED_HOL4
```

The resulting manifest is an index, not a refinement proof. Its GPL license remains
with that checkout. Original MetaRocq/Peregrine sources are MIT; LICENSE.MD is unchanged.


## Unified CakeML Peregrine + MetaRocq E2E pipeline

The unified E2E pipeline is implemented as a 23-stage CakeML controller in
`cakeml/unified-e2e/UnifiedE2EPipeline.cml`.  The exact instruction corpus is
preserved under `docs/unified-peregrine-metarocq-e2e/`; each CakeML stage maps
to the correspondingly numbered instruction file.

The pipeline is intentionally fail-closed.  Producer success, generated
LambdaBox/CakeML files, or a green workflow are not substitutes for the
required theorem-bound evidence.  Missing formal bridges remain blockers.

All repository workflows on this stack are manual-only.  The unified workflow
has `workflow_dispatch` and no `pull_request`, `push`, or schedule trigger.

### CachyOS prerequisites

On current x86_64 CachyOS/Arch systems, install the host toolchain from the
official repositories:

```sh
sudo pacman -Syu --needed \
  base-devel curl git gmp m4 opam polyml clang time github-cli
```

`polyml`, `opam`, and `github-cli` are available in Arch's Extra
repository.  `base-devel` supplies GCC, make, binutils, pkgconf and the normal
native build toolchain.

### Install the CakeML compiler binary

The orchestration build is pinned to the official CakeML **v3479 x64-64**
release archive.  The expected SHA-256 is:

```
e110bfcba19d6524ee4748608a67a275647445a048928cf623c2c9a973e31c9a
```

Install a local `cake` compiler:

```sh
mkdir -p "$HOME/.local/src" "$HOME/.local/bin"
cd "$HOME/.local/src"

curl --fail --location --retry 4 \
  -o cake-x64-64-v3479.tar.gz \
  https://github.com/CakeML/cakeml/releases/download/v3479/cake-x64-64.tar.gz

printf '%s  %s\n' \
  e110bfcba19d6524ee4748608a67a275647445a048928cf623c2c9a973e31c9a \
  cake-x64-64-v3479.tar.gz | sha256sum --check -

rm -rf cakeml-v3479
mkdir cakeml-v3479
tar -xzf cake-x64-64-v3479.tar.gz -C cakeml-v3479 --strip-components=1
make -C cakeml-v3479 cake
install -m 0755 cakeml-v3479/cake "$HOME/.local/bin/cake"
```

For fish:

```fish
fish_add_path "$HOME/.local/bin"
cake --help
```

For POSIX shells:

```sh
export PATH="$HOME/.local/bin:$PATH"
cake --help
```

The repository controller builder can also manage the verified release archive
without installing `cake` globally:

```sh
bash tools/build_unified_e2e_cakeml.sh
generated/cakeml-unified-e2e/unified_e2e.cake --help || true
```

The v3479 compiler above is used to compile the **orchestration controller**.
It does not replace the theorem-bound CakeML source revision
`c98da7fc904c5d6d0e9a75a18fac1796a9bfb1f9` used by the formal E2E proof
contract.

### Install the pinned MetaRocq and Peregrine toolchain

From this repository root, materialize the exact source pins first:

```sh
python -B tools/bootstrap.py sources
```

Then install the pinned Rocq/MetaRocq/Peregrine packages into the repository
local opam switch:

```sh
export OPAMROOT="$PWD/.aegis/opam-root"
bash tools/install_extraction.sh
eval "$(opam env --switch "$PWD/.aegis/opam" --set-switch)"

command -v rocq
command -v peregrine
rocq -v
peregrine --help
opam list --switch "$PWD/.aegis/opam" | grep '^rocq-metarocq'
```

For fish, activate the same switch with:

```fish
set -gx OPAMROOT "$PWD/.aegis/opam-root"
bash tools/install_extraction.sh
opam env --switch "$PWD/.aegis/opam" --set-switch --shell=fish | source

type -a rocq
type -a peregrine
rocq -v
peregrine --help
opam list --switch "$PWD/.aegis/opam" | grep '^rocq-metarocq'
```

Upstream MetaRocq is installed here as the `rocq-metarocq-*` Rocq plugin
suite, so the stable executable entry point is `rocq`; a standalone command
named `metarocq` is not assumed.  Peregrine installs the `peregrine` CLI.

The self-host producer automatically prefers the repository-local prebuilt
`rocq` and `peregrine` binaries and rebuilds the exact pins only when they
are absent:

```sh
bash tools/peregrine_selfhost_pipeline.sh
```

### Run only by explicit CLI command

Authenticate GitHub CLI once:

```sh
gh auth status
```

Dispatch the unified workflow explicitly:

```sh
gh workflow run unified-cakeml-e2e.yml \
  --ref experiment/cakeml-unified-e2e-03-cachyos-docs
```

There is deliberately no automatic PR/push build.  A completed run appends one
unique trace directory to the same branch under `.o11y/<run-id>/`.  Pull that
trace commit explicitly after the run:

```sh
git fetch origin experiment/cakeml-unified-e2e-03-cachyos-docs
git pull --ff-only origin experiment/cakeml-unified-e2e-03-cachyos-docs
find .o11y -mindepth 1 -maxdepth 1 -type d -print | sort
```

Each trace directory includes combined stdout/stderr, `/usr/bin/time -v`
resource accounting, explicit status/failure files, source/toolchain identity,
controller/stage receipts, and `SHA256SUMS`.  Synchronization rejects an
existing run ID, commits additions only, and never force-pushes.  Repository
administrators can still rewrite ordinary Git history; stronger
irreversibility requires an external GitHub ruleset or immutable archival
replication.
