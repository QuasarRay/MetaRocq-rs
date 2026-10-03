# Operational limits and recovery

## O01 — Medium: enforcement applies to managed cycles

`freeze` rejects starting a second cycle before the previous one is checkpointed.
`checkpoint` requires committed work, a matching live PR and remote Git head. Aegis
cannot prevent arbitrary out-of-band editing, local-state deletion, force pushes by
another actor, later branch deletion, or loss of edits before the first publication.
The repository's `candle-rs` branch was unprotected at initial inspection. This task
has not altered branch protection or merged any PR.

Recovery: retain small source/plan/evidence commits and PRs. On a fresh checkout, bind
the original plan and rerun the relevant checks; never infer verified status merely
from a reconstructed local state. An unverified or blocked checkpoint is legitimate
progress and remains labeled as such. Network failures block remote attestation.

## O02 — Medium: exclusive stale-lock recovery is required after some crashes

Automatic lock stealing was removed because its read/unlink sequence was racy. Preserve
state, stop competing Aegis processes, check the recorded host/process identity, then
remove only the abandoned lock under exclusive access. Filesystem identity checks are
not a defense against a malicious same-user process replacing paths concurrently.

## O03 — Medium: operating-system capabilities are conditional

Linux process-group cleanup is covered by a real descendant-process check. Two inherited
host-specific cases are skipped on this Linux host. Windows job assignment, directory
flush semantics, alternate filesystem aliases and escaped child sessions do not acquire
new guarantees from this audit. The original Candle environment and live qualification
used Linux; no optional cross-platform campaign was purchased.

## O04 — Low: source checkout is the supported deployment

The old generic installer, distribution mirror and release receipt were removed because
they described obsolete TDD policy. Invoke Aegis from a pinned source checkout using
its Python API or `bin/agentctl.py`. Do not pip-install the retired metadata or reuse a
historical release receipt as evidence for this branch. Existing deployments are not
automatically overwritten. The requested model fragment is configuration, not a live
model attestation or a modification of the current host's account settings.

## O05 — Medium: preservation and acceptance are different

A stack of PRs protects committed progress; it does not imply that GitHub enforces merge
order or that a reviewer approved a mathematical argument. Merge the dependent PRs in
order and preserve their evidence. The owner controls merging and protection settings.
Aegis does not silently mutate either. Human review should focus on contracts, proof
assumptions and changed trust boundaries, without unrelated readability/performance work.
