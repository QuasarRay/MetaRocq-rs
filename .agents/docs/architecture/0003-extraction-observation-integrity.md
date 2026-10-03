# ADR 0003: revalidate extraction before proof or checkpoint claims

Status: accepted. Stakeholder: the independent supervising engineer.
Concern: a stored extraction-path/digest pair is insufficient if generated output,
the driver, the original-source binding or the recorded observation later changes.

Decision: reuse the existing source hashes, confined paths and frozen cycle identity
to recheck extraction observations before invoking verification and when checkpointing.
Require exact output inventory and current content hashes for GENERATED. FAILED and
BLOCKED observations must advertise no successful outputs. Preserve their explicit
status in the remote checkpoint. A generation plan cannot verify handwritten output
after a failed extraction by invoking a verifier directly.

Validation checks observation tampering, output substitution, changed drivers and
blocked-to-verified promotion. The first target bootstrap snapshot remains preserved
in its PR; downstream work repins this controller explicitly.

Only actual generation inputs/output and semantic-plan identities are rebound here.
Unrelated documentation edits do not require rerunning expensive extraction. This
still does not authenticate installed Rocq libraries or prove compiler correctness.
