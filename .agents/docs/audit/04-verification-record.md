# Verification record

## Local execution

- `python3 -B scripts/selftest.py`: 37 tests ran; 35 passed, 2 host-specific skips.
- `python3 -O -B -m unittest discover -s infra/tests -q`: same result; enforcement does
  not depend on Python assert statements being enabled.
- `python3 scripts/generate.py --check`: no generated instruction/template drift.
- Original Candle commit `5b1888b9a0c1da7ca0ef2e80526b726f2e27df9d` and CakeML commit
  `bef5e6194c41e356441399d4344b965794dc0d1b` inspected from fresh checkouts. All eight
  seed byte hashes were checked before publishing the runtime; selected-theory checks
  were repeated after generalizing the original-source binding.
- Internal import scan found no missing relative imports. Every tracked source
  directory had AGENTS.md. Retired TDD commands and previous-model strings were absent.

The lifecycle and error-path tests use fixtures/mocks where they isolate state-machine
behavior. They are not live Kani, Verus, GitHub or HOL4 proofs. The following execution
records cover the separate live boundaries.

## Real Kani and Verus execution

Qualified versions: Kani 0.67.0 and Verus 0.2026.09.20.aef82ed. Verus archive SHA-256
`7b870fa12bc589015c2fab60a8b3d9f07c7b1adb3444eb0fadffcbf7f0447b33` was checked by CI.
The installation recipe reuses the project's previously qualified NVIDIA-lab toolchain
pins; no new verifier implementation was written.

First run [36315096513](https://github.com/QuasarRay/Aegis/actions/runs/36315096513)
correctly failed qualification because Aegis rejected a successful Kani log. The actual
log identified the solver/property-status confusion; the defect was corrected.

Corrected run [36315329725](https://github.com/QuasarRay/Aegis/actions/runs/36315329725)
at commit `82afa955e495d5c040a3c07fdf51931d97e96d2d` passed all four adapter controls:

| Tool | Obligation | Expected observation | Result |
| --- | --- | --- | --- |
| Kani | wrapping increment/decrement on symbolic u8 | one exact successful harness | PASS |
| Kani | negation of that identity | actual verification failure | PASS |
| Verus | integer reflexivity | one verified proof function | PASS |
| Verus | its negation | actual verification error | PASS |

Artifact: `candle-verifier-qualification`, ID `10930830680`, archive SHA-256
`9aa5d7b81011e87b1be031a2ce28beadacd3ec9fe0fca19d360505285f83aee6`.
These fixtures qualify adapters. They are not original Candle obligations and prove
nothing about a nonexistent Rust Candle kernel.

## Final stack head

The final audit PR additionally pins Actions to the exact PR head and exercises the
live checkpoint API. Its actual run identities and final source digest will be recorded
in `validation.json` after CI completes. No pending run is counted as successful here.

## Reproduction

Checkout the relevant PR head, run the local commands above, and use the pinned
installation recipe in `.github/workflows/candle-verifiers.yml` before running
`python3 -B scripts/check_verifiers.py`. Inspect the emitted `.aegis/verifier-qualification.json`.
Read `docs/SUPERVISION.md` before interpreting any result. Do not rerun expensive
unrelated campaigns or optimize optional performance/readability as part of acceptance.
