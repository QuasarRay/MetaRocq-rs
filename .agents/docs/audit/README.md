# Candle-rs branch audit — 2026-09-27

This collection audits the Aegis Candle branch redesign, not a completed Rust Candle
prover. The target Candle-rs repository contained AGENTS.MD and LICENSE.MD at the
inspected revision. No claim of Rust/HOL4 equivalence or compiled-code soundness is made.

## Scope and evidence

Baseline: `01060f8d731e0e9082a555bc23f47810aa9eec51` on `QuasarRay/Aegis:candle-rs`.
Durable implementation checkpoints: PR [2](https://github.com/QuasarRay/Aegis/pull/2),
[3](https://github.com/QuasarRay/Aegis/pull/3), [4](https://github.com/QuasarRay/Aegis/pull/4).
This audit and its final corrections form the next PR in that stack.

Reviewed layers: instruction routing; scientific authority; original-source identity;
contract schema and lifecycle; source/evidence freshness; proof-output parsing; process
capture; filesystem writes and locks; GitHub checkpoint identity; generated context;
CI checkout identity; packaging and migration; residual host and semantic trust.
Searches covered the tracked source, old enforcement names, model strings, dynamic
execution/import boundaries and placeholder paths. No reviewer subagent was used.
This is an implementation-plus-self-audit, not an independent human acceptance.

## Findings index

| Category | Document | Disposition |
| --- | --- | --- |
| Incorrect or costly enforcement, parser and runtime bugs | [01-fixed-defects.md](01-fixed-defects.md) | Corrected in the stack; regression evidence recorded |
| Formal meaning, proof closure and trust | [02-open-proof-boundaries.md](02-open-proof-boundaries.md) | Explicit limitations; block stronger proof claims |
| Recovery, remote progress and deployment | [03-operations-and-durability.md](03-operations-and-durability.md) | Managed gates implemented; external guarantees remain conditional |
| Reproduction and observed results | [04-verification-record.md](04-verification-record.md) | Actual execution distinguished from fixture coverage |

Severity means consequence for the promised claim, not an invented exploit score.
High findings block full semantic/soundness claims. Medium findings concern operational
loss or misleading acceptance. Low findings concern unsupported surface area. Optional
performance, readability and idiomaticness improvements were deliberately not pursued.

## Acceptance conclusion

Aegis now governs bounded Candle work using original specifications and durable GitHub
checkpoints, without test-order prerequisites. It is suitable for supervised incremental
implementation with explicit assumptions. It is not a certificate of the candidate
prover, a hostile-agent sandbox, or a fully attested mathematical proof checker.
