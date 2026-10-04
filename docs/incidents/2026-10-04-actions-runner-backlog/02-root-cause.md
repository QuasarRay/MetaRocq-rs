# Root-cause analysis

## Primary cause: hosted-runner backlog

Many unrelated workflows with no shared concurrency key remained `queued` before starting their first step. Some runs had a job object with `steps: null`, which means execution had not begun.

Changing the recovery workflow from `ubuntu-24.04` to `ubuntu-22.04` did not cause it to start, so the incident is not explained by the 24.04 image alone.

## Amplifier: branch concurrency preserved obsolete runs

Several expensive experimental workflows used a pattern equivalent to:

```yaml
concurrency:
  group: <workflow>-${{ github.ref }}
  cancel-in-progress: false
```

Observed result:

```text
old commit -> queued job owns concurrency generation
newer commit -> pending, no jobs materialized
newer pending generations -> replaced/cancelled
latest useful commit -> still pending
```

This policy is appropriate for final evidence publication, but inefficient for fast-moving experimental branches.

## Amplifier: broad PR preflight fan-out

Every open experimental PR also generated a Supervision preflight, creating additional runner pressure independent of each branch-specific proof/build workflow.

## Not the primary cause

- No evidence of a repository-wide logical/proof deadlock.
- No single global workflow concurrency key serialized all branches.
- The queue persisted across multiple workflow families.
- The recovery attempt on a second Ubuntu image queued as well.

## Operational limitation during recovery

The connected GitHub toolset had read/rerun/write-repository capabilities but no cancel/force-cancel or workflow-dispatch operation. No authenticated GitHub CLI token was available in the execution environment. This prevented direct cancellation of the existing Actions backlog from the assistant session.
