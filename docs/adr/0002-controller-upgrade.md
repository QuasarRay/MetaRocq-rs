# ADR 0002: preserve the first checkpoint and strengthen extraction evidence

Status: accepted. Stakeholder: the supervising engineer.
Concern: prevent a valid extraction observation from being reused with changed output,
or a failed generation attempt from being followed by verification of substitute code.

The first cycle is preserved in PR #1 at
124951fb16688efcfd2271319820c3f52a83257d. Aegis performed a live checkpoint against
that exact branch/PR head. Its receipt is retained in .metarocq/parent-checkpoint.json.
The local PUBLISHED state was archived before explicitly starting a new controller
cycle. No failed observation was edited into a successful one or silently reinterpreted.

Decision: repin Aegis to PR #13 at 85a4664fed12fd9784ff05a3b067ef6ce0d821f5.
The new controller rechecks observation digest, semantic plan, upstream source,
driver and generated outputs before proof/checkpoint operations. A generation plan
cannot verify until generation is observed to succeed. Receipt hashes remain integrity
checks rather than proof authentication. Installed-library provenance is still OPEN.

The initial cloud run 37103073373 reached dependency resolution but stopped because
the system clang package was absent. The new workflow installs clang explicitly;
it does not disable opam's dependency checks. Extraction and compilation did not run
in the failed attempt. The next CI run must be inspected independently.

Validation: the specialized controller's 48 tests have 46 passes and two platform
skips. Rebind the original contract through the new pinned controller, repeat the
real missing-tool extraction observation, and check that verification is rejected
before Kani is invoked. Preserve this as a PR stacked on the first bootstrap.
