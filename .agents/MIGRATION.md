# Branch migration

This is an intentional incompatible Candle-specific redesign. Legacy `init`, task/TDD,
law, policy-pack, subagent, install and release commands are removed. They do not silently
fall through to a weaker profile. Keep old deployments on their old commit if needed.
The old distribution and its verification receipt no longer describe this branch.

Preserve old `.aegis` state as historical evidence; do not relabel RED/GREEN results as
Candle refinement proofs. Install this controller from a separate pinned checkout.
Start a new Candle plan under the original-source authority. Framework or authority
updates invalidate local bindings; preserve them and bind again in a fresh worktree.
Do not delete uncommitted work or overwrite user configuration to migrate.

AGENTS.md routing is generated for every tracked source directory. External upstream
checkouts keep their own instructions and their original bytes. The target Candle-rs
repository's provided AGENTS.MD remains an input, not something this Aegis change edits.
