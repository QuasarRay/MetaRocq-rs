# GitHub Actions runner-backlog incident — 2026-10-04

## Status

This incident affected the MetaRocq-rs experimental self-host/reflection stack and the HOL4→PCUIC migration branch.

At the evidence snapshot used for this report:

- active/non-completed workflow runs: **39**
- queued: **30**
- pending behind workflow concurrency: **5**
- in progress: **4**

The failure mode was primarily **CI scheduling/backlog amplification**, not a repository-wide proof failure.

The newest reflective line at recovery time was:

`experiment/original-metarocq-selfhost-08-pcuic-certificate-reconciled`

with the workflow:

`Original MetaRocq reconciled certificate selfhost`.

## Key conclusion

Multiple experimental branches generated independent GitHub-hosted runner demand faster than runners were assigned. Several workflows also used branch-scoped concurrency with `cancel-in-progress: false`, causing an old queued run to retain a concurrency slot while newer runs remained `pending`.

The available ChatGPT GitHub integration exposed Actions read/rerun operations but **did not expose cancel/force-cancel or workflow-dispatch**. The runtime environment also had no authenticated `gh` CLI and no direct network access to GitHub. Therefore direct termination of the existing run backlog could not be completed from this session without destructive repository changes. No branches or PRs were deleted/closed to simulate cancellation.

See the numbered documents in this directory for timeline, root cause, impact, remediation, run inventory, and recovery verification.
