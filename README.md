# MetaRocq-rs

Goal: a Rust-native MetaRocq implementation, certified metaprogramming and independently
checkable proof-carrying macro expansions. The original MetaRocq mathematical sources
are the shared contract. This checkpoint establishes the supervised bootstrap.

**Current status: bootstrap infrastructure only. No Rust checker, verified macro
system or machine-code correctness proof exists at this checkpoint.**

The first driver extracts the original `PCUICAst.isApp` through Peregrine's typed
frontend. Actual generation has not succeeded locally because Rocq and Peregrine are
absent. Generated Rust is intentionally absent; `cargo check` requires generation first.
Kani harnesses must bind the observed generated API and cannot yet run.

## Reproduce

Python 3.11+ and Git are sufficient to inspect the initial contract:

```sh
python -B tools/bootstrap.py sources
python -B tools/sync_instructions.py --check
python -B tools/bootstrap.py check
python -B tools/bootstrap.py bind
# With the pinned-compatible Rocq/Peregrine installation active:
python -B tools/bootstrap.py extract --timeout 600
cargo +1.98.1 check
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
