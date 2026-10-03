# ADR 0003: Preserve dependency work and distinguish current observations

Status: accepted for bootstrap infrastructure, 2026-10-03. This record follows
ISO/IEC/IEEE 42010 concerns, decisions, rationale and correspondence; it does
not assert certification to the standard.

Stakeholders: the supervising engineer and agents maintaining extraction.
Concerns: merge drift, repeated dependency compilation, misleading artifacts,
and preservation of original contracts across rebased PRs.

Observed failure: PRs 1 and 2 were rebased and merged. Main 4d133642 gained a
duplicate Kontroli reuse sentence in AGENTS.MD; generated instructions stayed
unchanged. Run 37104122593 stopped at preflight. Its artifact 11267800205,
SHA-256 479df30aded121e974cf507b14bd1fda7c7341c86ef807c5e0798980aaf5a7bc,
contains seven historical diagnostic/instruction files, no Rust or typed AST.
The preceding build 37103582530 was cancelled after installing Rocq, before
Peregrine extraction. There are no unmerged files in the current Git tree.

Decision: preserve the canonical goals once, regenerate directory copies, and
continue on current main without rewriting merged history. Use the existing
Aegis extractor. Cache opam installations by original source commits, complete
installation recipe and runner image; always reconcile with opam before use.
Save successful dependencies before generation and partial failed installation
for a diagnosed retry. Queue same-branch builds instead of cancelling useful
compiler work. No automatic blind retry is added. Export the installed switch.

Only this run's evidence is packaged, with checkout SHA, step outcomes and file
hashes. A skipped extraction cannot advertise old Rust as new output. Caches
are performance aids, never proof evidence or authenticated build provenance.
The initial package resolution remains incompletely locked; the exported
switch must be reviewed and pinned before a release.

The old checkpoint's exact-head attestation is historical after the user
rebased the stack. Preserve that receipt and archive the local cycle; start a
new named cycle on the observed merged main. Never change the old receipt to
claim it attests the new commits.

Validation: source/instruction preflight before installing dependencies;
actual cloud extraction and Rust compilation determine the next implementation
step. Full extraction, Kani correspondence, HOL4 semantic refinement and
machine-code correctness remain open release blockers.
