# ADR 0005: embed Aegis and finish the metatheory bootstrap first

Status: controller integrated; metatheory verification remains blocked.

This checkpoint descends from the complete open PR 4 history. Original generated
Rust, retained quotation, source inventory, failed Kani evidence, frontend artifacts
and dependency-build recipes remain intact. Aegis PR 18 descends from PR 17 and
preserves its HOL4/MCP/TacticToe and extraction supervision stack.

Deploy the exact Aegis source tree under `.agents`; bind every deployed source file
to `spec/aegis-deployment.json` and the existing toolchain lock. The former external
controller wrapper now loads this verified local deployment. Mutable event contents
live in `.agents/data`, separate from `.agents/database`, `.agents/roadmaps` and
`.agents/pipelines`. Repository snapshots contain both code and logical database data.

The new runtime roadmap starts with a source audit of the actual pinned MetaRocq
and Peregrine trees. All 755 upstream tracked files must match the inventory. The
audit records actual assumption locations and missing tools. Its success means the
audit ran; it does not finish Bootstrapping_MetaRocq-rs_MetaTheory.

The user's requested end state includes executable proof replay inside the generated
LambdaBox/CakeML program as well as retained proof objects. That replay must check
the intended theorem statements, source/environment bindings, universes and explicit
assumptions. Existing quotation of proof syntax is preserved as a building block.
The replay program, retained-data transformation and exact compiler/runtime chain
still require checked preservation and soundness evidence. The pinned CakeML wrapper
unconditionally uses `trust_coq_kernel`; retained data alone does not discharge its
precondition or the admitted wrapper obligation. No independent replay executable
or full Rust-aware metatheory equivalence proof is fabricated in this checkpoint.

The implementation gate rejects progress without a qualified semantic replay
adapter. Existing extraction/verification commands and expensive candidate CI are
gated accordingly; their source code and cached-build mechanisms are retained.
The deterministic source audit is bootstrap work, not implementation-roadmap execution.

PostgreSQL enforces read-all/write-own event access and forbids destructive worker
operations. Automatic code captures exposed inputs and process outputs, renders
Markdown journals and exports every logical database row. Logging invokes no model;
private internal reasoning is inaccessible. Exact Git publication is an advancement
barrier. Offline database recovery and independent protected replicas remain required
for outages or administrators; no absolute irreversibility claim is made.

The full architecture is not production-ready: authenticated agent-provider dispatch,
independent semantic replay and the mathematical/compiler obligations remain open.
