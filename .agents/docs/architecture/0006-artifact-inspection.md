# ADR 0006: Inspect downloaded generation packets independently

Status: accepted for bootstrap observations, 2026-10-03.
Stakeholders: the engineer inspecting untrusted agent work and later agents.
Concern: a CI artifact was emitted even though extraction never ran. Merely
finding files in a generated directory must not authorize subsequent work.

Decision: reuse source_snapshot, strict JSON parsing and the fixed extraction
output inventory. Add an independent read-only ZIP inspector. The reviewer
supplies GitHub's observed run id, head SHA and ZIP digest from outside the
packet and checks out that head. The inspector checks those identities, a
clean source tree, current step outcomes, complete member hashes, source/plan/
driver correspondence, and the extraction/output binding. It never executes
or unpacks artifact code. Duplicate entries, path traversal, symlinks, size
excesses, missing current manifests, contradictory steps and stale candidate
files are rejected. Successful compilation requires the dependency lock.

Example, using values obtained independently from GitHub:

```sh
python /path/to/Aegis/bin/agentctl.py --root /path/to/MetaRocq-rs \
  inspect-artifact /path/to/run.zip --run RUN_ID --head HEAD_SHA \
  --sha256 GITHUB_ARTIFACT_SHA256
```

CONSISTENT is only a process-packet consistency result. It is not a semantic
proof, independent compiler replay, or authenticated build provenance. The
reviewer still needs to inspect the workflow and independently replay Kani and
HOL4 for the exact contract. An attacker controlling the GitHub workflow can
produce internally consistent false observations; the inspector cannot turn
those claims into proofs. The legacy seven-file artifact is intentionally
rejected rather than upgraded to current extraction evidence.

Validation covers the observed historical-packet mistake, false compilation,
missing outputs, forged run identity, modified files, duplicate and traversing
members, and a dirty checkout. Fixture output is labelled as fixture data.
This record uses ISO/IEC/IEEE 42010 concerns and correspondence without
claiming standards certification.
