# Unified E2E observability ledger

Every run of `.github/workflows/unified-e2e-cakeml-o11y.yml` allocates a unique `runs/<run-id>-<attempt>-<trigger-sha>/` directory.

The execution worker directly reuses the pinned `CakeML/regression` utility layer and records, per stage, the exact command, instruction source and SHA-256, combined stdout/stderr, `/usr/bin/time` data, and terminal status. On the first fail-closed operational stage, dependent stages become `SKIPPED`; Step 23 still runs so provenance and unresolved formal obligations are recorded even for failed builds.

Before the real run, `failure-model/` injects a failure at each of all 23 positions using the same runner in compact dry-run mode. This checks the complete FAILED/SKIPPED topology rather than testing only the happy path.

The final workflow step persists the run directory to the same branch with normal fetch/rebase/push only. A run key may be created once; collision is an error; force-push is forbidden. `manifest.sha256` plus Git commit/tree identity make later mutation detectable. `.o11y/**` pushes are excluded from workflow triggers to avoid recursion.

This is append-only workflow behavior, not an assertion that GitHub administrators are cryptographically incapable of rewriting repository history.
