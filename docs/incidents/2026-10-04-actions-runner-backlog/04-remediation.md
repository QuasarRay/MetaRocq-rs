# Remediation and prevention

## Immediate cleanup

1. Cancel every non-completed Actions run that is not the one selected for authoritative validation.
2. After cancellation is confirmed, start exactly one workflow for the latest reflective branch.
3. Do not resume parallel stacked-branch Actions until that run completes.
4. Preserve completed historical evidence and artifacts.

Direct cancellation requires GitHub UI/API access with Actions write permission. The assistant environment used for this incident did not expose that endpoint.

## Experimental workflow policy

Use latest-commit-wins concurrency:

```yaml
concurrency:
  group: <workflow>-${{ github.ref }}
  cancel-in-progress: true
```

for fast-moving experimental proof/build branches.

Keep `cancel-in-progress: false` only for final evidence/release workflows where preserving an already-running proof replay is intentional.

## Trigger reduction

- Narrow `paths:` filters aggressively.
- Prefer `workflow_dispatch` for expensive proof/extraction workflows after the source layer is ready.
- Avoid triggering generic Supervision preflight for documentation-only incident commits.
- Use `[skip ci]` for pure incident documentation.

## Stack discipline

Only the current head of the reflective stack should receive expensive CI by default. Earlier stack layers should retain their source history and completed evidence but should not continue consuming runners once superseded.

## Recovery workflow

The newest reflective workflow was hardened to use:

- latest-commit-wins concurrency;
- `ubuntu-22.04` as a diagnostic alternate hosted-runner image.

The alternate image also queued, confirming that image selection alone did not resolve the backlog.

## Success criterion

Recovery is complete only when the selected latest workflow:

1. receives a runner;
2. installs the pinned toolchain;
3. compiles every listed Rocq module;
4. produces a non-empty `reconciled-selfhost.ast`;
5. uploads the generated proof/extraction evidence;
6. concludes `success`.
