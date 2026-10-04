# Impact

## Formal-development impact

- The reflective MetaRocq stack advanced through multiple branches faster than GitHub Actions could validate them.
- Newer proof layers were therefore written on top of source-level predecessor work whose CI validation was still queued.
- This does **not** imply the Rocq theorems are false; it means the intended independent CI evidence had not yet been produced.

## Evidence impact

Completed historical runs remain preserved. No completed artifacts were deleted.

Queued runs with no steps had produced no proof evidence. Pending runs had not materialized jobs.

A small number of older checker runs had genuine execution progress and should be distinguished from zero-progress queued work when manually cleaning the backlog.

## Engineering impact

The Actions page became difficult to interpret because it mixed:

- obsolete branch generations,
- latest branch generations,
- PR supervision,
- proof-specific workflows,
- migration experiments,
- and long-running original-checker replays.

This obscured which workflow represented the newest reflective state.

## Latest authoritative source state

At recovery time, the newest reconciled reflective branch was:

`experiment/original-metarocq-selfhost-08-pcuic-certificate-reconciled`

Its intended output is:

`generated/original-selfhost/reconciled-selfhost.ast`.
