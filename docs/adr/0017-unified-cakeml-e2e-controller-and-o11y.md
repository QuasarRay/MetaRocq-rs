# ADR 0017: Unified CakeML E2E controller and append-only observability

## Status

Accepted for the implementation stack.  The pipeline has been implemented but
has not been dispatched or executed as part of this change.

## Decision

1. Preserve the exact 23-step unified Peregrine + MetaRocq instruction corpus.
2. Express stage ordering and fail-closed control flow in CakeML.
3. Use one narrow CakeML FFI only for launching the fixed host-stage dispatcher,
   because the relevant CakeML basis does not expose general process spawning.
4. Reuse the existing self-reflective MetaRocq and Peregrine producer work; do
   not regenerate equivalent infrastructure in a parallel implementation.
5. Treat native producer success only as producer evidence.  Proof publication
   requires the theorem-bound artifacts specified by each stage.
6. Adapt CakeML/regression's worker observation model for status, combined
   stdout/stderr, timing/resource usage and explicit failure markers.
7. Persist each explicit run under one new `.o11y/<run-id>/` directory and
   synchronize it to the selected Git branch with a non-force append-only
   commit.
8. Keep every GitHub workflow manual-only.  The unified workflow is triggered
   only through `workflow_dispatch`.

## Trace permanence

Repository code rejects duplicate run IDs, edits and deletions of prior trace
directories, and never force-pushes.  SHA-256 inventories make retained traces
tamper-evident relative to their Git commit.

Git administrators can still rewrite repository history.  Therefore absolute
irreversibility is outside the capability of an ordinary in-repository
workflow and requires an external ruleset/immutable archive.

## Formal completion

This ADR does not claim that all formal obligations already exist.  Missing
Peregrine LambdaBox-to-CakeML correctness, exact HOL4 machine-code
attestations, embedded-capsule correspondence, independent replay, MetaRocq
erasure closure, proof-corpus replay, exact in-logic compilation, unified
source-to-machine composition, and recursive replay remain fail-closed when
their required theorem sources/evidence are absent.

No admitted axiom, process return code, generated-file existence check, or CI
success marker is permitted to discharge those obligations.
