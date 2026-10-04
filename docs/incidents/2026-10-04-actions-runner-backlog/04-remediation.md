# Remediation and prevention

## Immediate cleanup

1. Cancel every non-completed Actions run except the single run selected for authoritative validation.
2. Confirm the queue is empty.
3. Execute exactly one workflow for the newest reflective branch.
4. Preserve completed evidence and artifacts.

Direct cancellation requires GitHub UI/API Actions-write access, unavailable to the recovery session.

## Experimental workflow policy

Use:
```yaml
concurrency:
  group: <workflow>-${{ github.ref }}
  cancel-in-progress: true
```
for fast-moving experimental proof/build branches.

Reserve `cancel-in-progress: false` for final evidence/release workflows.

## Trigger reduction

- Narrow paths aggressively.
- Prefer workflow_dispatch for expensive proof/extraction runs after a source layer is ready.
- Avoid generic preflight fan-out for documentation-only commits.
- Use `[skip ci]` for incident documentation.

## Stack discipline

Only the current reflective stack head should consume expensive CI by default. Superseded stack layers should preserve source/evidence without continuously competing for hosted runners.

## Success criterion

Recovery is complete only when the selected latest workflow receives a runner, installs exact pins, compiles its full Rocq module list, creates a non-empty `reconciled-selfhost.ast`, uploads evidence, and concludes `success`.
