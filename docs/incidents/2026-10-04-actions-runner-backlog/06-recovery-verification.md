# Recovery verification record

## Actions performed

- Enumerated active workflow runs and job states.
- Confirmed zero-step queued jobs.
- Confirmed pending generations behind branch concurrency.
- Re-resolved the authoritative branch as newer Selfhost layers appeared.
- Tested an alternate Ubuntu hosted-runner image.
- Added latest-commit-wins concurrency to recovery workflows.
- Re-targeted recovery to Selfhost-8 after it superseded Selfhost-7.

## Result

Replacement runs also entered `queued` before executing a step.

Therefore runner-image selection was insufficient and the hosted-runner backlog remained unresolved.

## Cancellation capability audit

Available:
- Actions/run inspection;
- job/artifact inspection;
- rerun operations;
- repository/branch/file writes.

Unavailable:
- cancel workflow run;
- force-cancel workflow run;
- workflow dispatch.

The local runtime also lacked authenticated `gh` and direct github.com access.

## Required follow-up

Use GitHub Actions UI or another client with Actions write permission to cancel outstanding runs. Once the queue is empty, execute only the newest authoritative reflective workflow and append its final run ID, artifact digest, and conclusion here.
