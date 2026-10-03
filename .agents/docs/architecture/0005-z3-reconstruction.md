# ADR 0005: Qualify reconstructing Z3 and inspect theorem objects

Status: qualification implementation; cloud replay result required.
Stakeholders: proof authors and independent reviewers.
Concerns: the previous fixture used simp, the subprocess environment omitted
HOL4_Z3_EXECUTABLE, and a successful Holmake exit was too broadly described.

Decision: reuse pinned HOL4 HolSmtLib.Z3_TAC and its kernel proof replay, never
substitute Z3_ORACLE_TAC. Forward and identify the selected executable; reject
paths unsafe for the upstream shell-based solver launcher. Require HOLDIR's
Git commit to match the lock and tracked source to be unchanged.

Qualification constructs a fresh temporary theory, proves an integer interval
lemma and inspects the theorem before export: exact alpha-equivalent goal,
empty hypotheses, no local axioms and no oracle tags except DISK_THM. HOL4's
pinned src/prekernel/Tag.sml and src/1/Sanity.sml establish that DISK_THM is the
loaded-theory marker, the sole default accepted oracle tag. Loaded foundational
theories remain trusted; this is not a transitive axiom audit. The inspector
must reject a deliberately oracle-tagged object, an assumed goal and a theorem
with a different conclusion. None of those negative controls is exported.

The fixture records script, solver and exported-theory hashes. This is tool
qualification, not an interpretation of PCUIC, a Rust semantics proof or
MetaRocq refinement. Generic holmake output is described only as a process
observation; each future contract must bind and inspect its own theorem.

The source pin and executable hashes do not prove compiler/build provenance.
The current environment and HOL4 foundational libraries remain in the trust
base. CI rebuilds/reconciles the pinned sources and caches the completed build
by source, runner image and architecture before qualification. MCP discovery
is still separate from the direct replay path.

Validation: Python boundary regressions for wrong commits, modified sources,
environment propagation and shell-path handling; real HOL4/Z3 CI is the gate
for the positive and negative theorem-object checks. This architecture record
uses ISO/IEC/IEEE 42010 concerns and correspondence without claiming conformance.

First cloud attempt 37107288124 failed before any theorem: the inherited
`core-theories` sequence starts at compute and omits the kernel bootstrap.
The pinned upstream CI uses `upto-parallel`, which includes both kernel and
core-theories. Reuse that sequence in HOL4 and TacticToe qualification; do not
retry the same incomplete build. No proof was produced by the failed attempt.

The next run 37107485843 built and cached HOL4, then exposed an inherited MCP
SDK mismatch: installed mcp 2.3.0 exposes is_error rather than isError in Python.
Use Pydantic's stable wire aliases and require an explicit false error flag.
Record kernel replay independently before MCP discovery, so an orchestration
failure cannot discard a completed replay observation. Direct HOL4 execution
no longer requires an MCP executable. Overall qualification still requires
both observations to succeed.

Run 37108188058 passed the theorem-object inspection, then failed packaging
because pinned Poly/ML HOL4 exports into `.hol/objs`, as specified by
`tools/Holmake/poly/HFS_NameMunge.sml`. Inspect SML, signature and theory data
there. Always preserve the direct replay log even if packaging or MCP fails.
The same run restored the 194 MiB HOL4 cache but the old unconditional
configure/build invalidated its compilation state. A matching cache now gets
source-pin/cleanliness checks and proceeds to fresh theorem replay. TacticToe
can reuse the same completed build and queues instead of cancelling active
recording work. Cached libraries remain a disclosed trust dependency.
