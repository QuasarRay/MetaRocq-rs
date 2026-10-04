# Root-cause analysis

## Primary cause: hosted-runner backlog

Many unrelated workflows remained `queued` before executing a first step. Some jobs had `steps: null`, confirming no job execution had begun.

Moving the recovery workflow to `ubuntu-22.04` did not cause it to start, so the incident is not explained by the 24.04 image alone.

## Amplifier: branch concurrency preserved obsolete runs

Several expensive experimental workflows used branch-scoped concurrency with `cancel-in-progress: false`. An old queued run could therefore retain the concurrency generation while newer useful runs remained `pending`.

## Amplifier: broad PR preflight fan-out

Every experimental PR also generated Supervision preflight demand, independent of branch-specific proof/build workflows.

## Not established

There is no evidence that all queued workflows are blocked by a MetaRocq proof deadlock. Queue state is upstream of proof execution for zero-step runs.

## Recovery tooling limitation

The connected GitHub surface exposed inspection, rerun and repository-write actions, but no Actions cancel/force-cancel or workflow-dispatch action. The runtime environment had neither authenticated `gh` nor direct GitHub network access.
