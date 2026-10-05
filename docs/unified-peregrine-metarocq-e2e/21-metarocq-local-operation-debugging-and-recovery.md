# 21 — Milestone 11 — Operate, Debug, Cache, and Recover the Entire Pipeline Locally

> **UNIFIED SEQUENCE STEP 21 OF 22 — METAROCQ SOURCE/SPECIFICATION -> MACHINE REFINEMENT.**  
> Reused from `docs/selfhost-bootstrap/11-local-operation-debugging-and-recovery.md` on `docs/selfhost-bootstrap-04-runtime-audit`. The original manual remains preserved. This unified copy is downstream of the verified Peregrine foundation from Steps 01–10.

## Objective

Make the entire proof/compilation chain reproducible and debuggable on one laptop without weakening any proof gate when an intermediate stage fails.

The local workflow MUST use the same source pins, proof definitions, and driver commands later used by CI.

Do not maintain one “developer shortcut” pipeline and a different “formal release” pipeline. Shortcuts may skip expensive stages only when they are clearly marked non-publishable and cannot produce the final E2E acceptance artifact.

## 1. Use one local driver with explicit stages

Create:

```text
tools/selfhost-e2e.sh
```

or an equivalent deterministic driver.

It SHOULD expose:

```text
pins
snapshot
lambdabox
erasure
peregrine
hol4-replay
cakeml
machine
e2e
replay-machine
audit
clean
prove
```

Recommended meaning:

```text
pins            verify immutable repository/toolchain identities
snapshot        regenerate exact source/proof/assumption snapshot
lambdabox       build the exact retained self-reflective LambdaBox artifact
erasure         instantiate/check source->LambdaBox theorem
peregrine       translate to exact CakeML and check semantic theorem
hol4-replay     reconstruct/check complete source proof replay in HOL4
cakeml          materialize exact CakeML HOL definition/semantics theorem
machine         compile CakeML in HOL4 and build exact machine theorem
e2e             compose MetaRocqE2E theorem
replay-machine  execute exact final image and compare theorem-bound replay state
audit           inspect assumptions/oracles/artifact identities
clean           remove generated products without deleting source/tool pins
prove           run every mandatory publication stage in dependency order
```

The `prove` command MUST fail on the first incomplete mandatory stage.

## 2. Use strict shell behavior

For Bash:

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

Quote paths and variables.

For user-facing commands on fish, document the fish-specific environment setup separately instead of copying Bash syntax into fish.

Example:

```fish
set -x OPAMROOT "$PWD/.aegis/opam-root"
opam env --switch .aegis/opam --shell=fish | source
set -x HOLDIR "$PWD/.aegis/hol4"
fish_add_path "$HOLDIR/bin"
```

The proof driver itself may remain Bash if that avoids two implementations of the same control logic.

## 3. Separate immutable inputs from generated outputs

Use:

```text
.aegis/references/        immutable pinned upstream source checkouts
.aegis/opam-root/        opam metadata/cache
.aegis/opam/             isolated Rocq/MetaRocq/Peregrine switch
.aegis/hol4/             pinned HOL4 source/build
.aegis/cakeml/           pinned CakeML source
generated/original-selfhost/
generated/hol4-selfhost/
generated/e2e/
```

Never write generated theorem evidence back into an upstream source checkout.

Never modify `.aegis/references/*` to “fix” a proof without first creating/pinning a reviewed fork/commit.

## 4. Cache only with complete dependency keys

Caching is allowed to accelerate builds. It must not authorize theorem reuse across incompatible inputs.

At minimum, cache keys for a proof-producing stage SHOULD include the identities of all inputs that can change its theorem:

```text
MetaRocq commit
Peregrine commit
Peregrine CakeML backend commit
CakeML commit
HOL4 commit
scope-manifest digest
source snapshot digest
proof-corpus digest
assumption-ledger digest
relevant build-script digest
target configuration digest
```

Do NOT cache “final theorem succeeded” under a key containing only branch name.

When uncertain, rebuild.

## 5. Prefer immutable theorem dependencies over opaque binary caches

Good cache:

```text
built pinned HOL4 tree keyed by HOL4 commit + Poly/ML environment
isolated opam switch keyed by lock files + installer digest
compiled unchanged HOL theories keyed by exact source dependencies
```

Bad cache:

```text
a previously successful final theorem copied into a changed source tree
an old machine image reused after changing the proof corpus
a CakeML output reused after changing Peregrine
```

## 6. Produce a stage manifest after every successful stage

Under:

```text
generated/e2e/stages/
```

create:

```text
01-pins.json
02-snapshot.json
03-lambdabox.json
04-erasure.json
05-peregrine.json
06-hol4-replay.json
07-cakeml.json
08-machine.json
09-e2e.json
10-runtime-replay.json
```

Each manifest SHOULD contain:

```json
{
  "stage": "...",
  "inputs": {"name": "sha256-or-commit"},
  "outputs": {"name": "sha256"},
  "theorems": ["..."],
  "assumptions": ["..."],
  "status": "CHECKED"
}
```

The manifests are audit/provenance data.

They are NOT allowed to create theorem facts merely by saying `"status": "CHECKED"`.

## 7. Keep complete stage logs

Write:

```text
generated/e2e/logs/
  pins.log
  snapshot.log
  lambdabox.log
  erasure.log
  peregrine.log
  hol4-replay.log
  cakeml.log
  machine.log
  e2e.log
  replay-machine.log
  audit.log
```

Run commands through a logging helper that preserves the real exit status.

Example:

```bash
run_logged() {
  local name="$1"
  shift
  mkdir -p generated/e2e/logs
  "$@" 2>&1 | tee "generated/e2e/logs/$name.log"
}
```

With `pipefail`, a failing command remains failing even through `tee`.

## 8. Debug in dependency order

When `prove` fails, do NOT begin by changing downstream theorem code.

Use this failure order:

```text
A. pin/provenance failure
B. source snapshot/completeness failure
C. retained LambdaBox/extraction failure
D. erasure theorem/assumption failure
E. Peregrine/CakeML semantic-boundary failure
F. HOL4 complete-replay failure
G. CakeML application-semantics failure
H. in-logic compiler-evaluation failure
I. target machine/configuration proof failure
J. final theorem-composition failure
K. runtime self-replay correspondence failure
L. final audit/reproducibility failure
```

Fix the earliest failing layer first.

A downstream proof failure caused by an upstream identity mismatch SHOULD disappear after the upstream theorem/artifact is regenerated.

## 9. Use fast preflight checks without confusing them with proofs

Before an expensive build, run:

```text
syntax/parse checks
revision checks
source scans
file existence
hash verification
small unit tests
supported-fragment checks
```

These can save substantial laptop time.

But a preflight result MUST NOT set final theorem evidence fields.

Structure:

```text
fast preflight
    |
    +-- fail -> stop early
    |
    +-- pass -> run actual proof-producing stage
```

not:

```text
fast preflight passed
    |
    v
declare proof complete
```

## 10. Use incremental HOL4 builds correctly

Use `Holmake` so unchanged checked theories are rebuilt only when their dependencies require it.

Example:

```bash
export HOLDIR="$PWD/.aegis/hol4"
export PATH="$HOLDIR/bin:$PATH"

cd formal/hol4/selfhost
Holmake
```

When debugging a theory:

```bash
Holmake MetaRocqReplayTheory
Holmake MetaRocqCakeMLTheory
Holmake MetaRocqMachineTheory
Holmake MetaRocqE2ETheory
```

Use the actual theory target names generated by the final files.

If dependency information may be stale, clean the HOL build products for the affected theories and rebuild. Do not delete the source/toolchain pins.

## 11. Bound parallelism on the laptop

Large opam/Rocq/HOL builds can exhaust memory before CPU.

Start with:

```bash
export OPAMJOBS=4
export MAKEFLAGS="-j4"
```

Increase only after observing memory headroom.

For proof debugging, lower parallelism can make logs deterministic and reduce noise.

The theorem result must not depend on job count.

## 12. Make the final run as hermetic as practical

After all pinned repositories and package sources are materialized, perform a clean proof run without fetching new source.

Recommended sequence:

```bash
./tools/selfhost-e2e.sh clean
./tools/selfhost-e2e.sh pins
./tools/selfhost-e2e.sh prove
```

Optionally execute the final proof subprocess in a network namespace after all dependencies are present:

```bash
unshare -n -- ./tools/selfhost-e2e.sh prove
```

Only do this after confirming HOL4/opam/build steps no longer require network access.

Network isolation improves reproducibility; it is not itself a proof.

## 13. Perform a clean-checkout reproduction

Use a separate worktree or clone.

Example:

```bash
git worktree add ../MetaRocq-rs-e2e-clean HEAD
cd ../MetaRocq-rs-e2e-clean
```

Recreate the pinned toolchains from the repository instructions and run:

```bash
./tools/selfhost-e2e.sh prove
```

Compare:

```text
scope manifest digest
source snapshot digest
proof corpus digest
assumption ledger digest
LambdaBox digest
CakeML program digest
machine-program digest
final theorem conclusion
theorem dependency/assumption report
```

If reproducible machine bytes are part of the claim, compare those bytes exactly.

## 14. Recover from a failed stage without discarding progress

Never:

```bash
git reset --hard <old branch>
git push --force
```

as a routine repair method on the documentation/formalization stack.

Instead:

1. identify the earliest failed stage;
2. create a new commit on the current stack branch;
3. preserve the previous failure as history;
4. regenerate only downstream artifacts invalidated by that fix;
5. open/continue a stacked PR;
6. record the incident if the failure exposed a trust-boundary bug.

Do not merge a stale historical branch wholesale merely to recover one useful theorem; port the unique theorem/implementation semantically.

## 15. Keep CI identical to the laptop command

GitHub Actions SHOULD invoke:

```bash
./tools/selfhost-e2e.sh prove
```

and:

```bash
./tools/selfhost-e2e.sh replay-machine
./tools/selfhost-e2e.sh audit
```

rather than duplicating the proof pipeline as YAML shell fragments.

The workflow may install/cache dependencies, but the proof order and gates should live in repository code that you can run identically on the laptop.

## 16. Never debug by weakening a theorem

Forbidden “fixes” include:

```text
Admitted
Axiom
Parameter used as missing proof
mk_oracle_thm
changing an equality to a Boolean flag
removing a completeness premise
dropping a failed source module from scope
removing an assumption from the ledger
replacing semantic preservation with hash equality
using a different executable because the verified one is difficult to run
```

If the theorem is false under the current design, change the implementation/specification explicitly and re-run the complete downstream chain.

## Completion gate

Milestone 11 is complete only when:

- one laptop command can execute the same proof pipeline as CI;
- each stage has deterministic inputs, outputs, logs, and manifests;
- caches are keyed by semantic/proof dependencies;
- failures are diagnosed in dependency order;
- clean-checkout reproduction is documented and works;
- no recovery procedure destroys historical progress;
- fast preflight checks cannot authorize the final proof;
- final theorem construction remains the only publication authority.

## References

### MetaRocq

- Official installation/build instructions: https://github.com/MetaRocq/metarocq/blob/9.1/INSTALL.md
- MetaRocq architecture, checker, erasure and examples: https://github.com/MetaRocq/metarocq/blob/9.1/README.md
- Correct and Complete Type Checking and Certified Erasure for Coq, in Coq: https://dl.acm.org/doi/10.1145/3706056

### CakeML

- CakeML source repository: https://github.com/CakeML/cakeml
- Theorem-producing compiler evaluation API: https://github.com/CakeML/cakeml/blob/master/cv_translator/eval_cake_compileLib.sig
- Concrete in-logic compilation example: https://github.com/CakeML/cakeml/blob/master/examples/compilation/x64/helloCompileScript.sml
- Verified CakeML Compiler Backend: https://cakeml.org/jfp19.pdf

### HOL4

- HOL4 installation instructions: https://hol-theorem-prover.org/install
- HOL4 developer/build documentation: https://hol-theorem-prover.org/docs/trindemossen-2/Developers/
- HOL4 official documentation index: https://hol-theorem-prover.org/docs/trindemossen-2/
