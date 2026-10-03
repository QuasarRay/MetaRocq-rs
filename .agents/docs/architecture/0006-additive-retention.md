# ADR 0006: supervise additive reflection without conflating it with refinement

Status: accepted for candidate generation. Full proof transport remains OPEN.

Stakeholders: the supervising engineer and untrusted implementation agents.
Concerns: retain previous work, bound retries, preserve original specifications,
and distinguish proof syntax from a theorem about a Rust implementation.

Decision: continue PR #16 and its entire ancestor stack. Add a bounded declarative
extraction recipe to the existing recorder. Preserve the legacy isApp adapter and
artifact inspector. Compile support modules in the declared order, require fresh
ASTs, and publish all outputs through the existing transaction only after success.
Every output needs an explicit obligation; driver, support and recipe hashes are
bound to generation, retry eligibility, reuse and artifact inspection.

Observed at target run 37116424210: quotation, its kernel check and typed erasure
completed, then the Rust backend exhausted a 3 GiB virtual-memory budget. Preserve
each fresh typed AST as a content-addressed evidence checkpoint before invoking the
backend. Bind it to the same source and executable identities, limit it to 32 MiB,
and validate its bytes on inspection and reuse. It remains an intermediate even
when the backend fails; successful Rust publication still requires all outputs.
The checkpoint is not automatically re-executed or accepted as a semantic proof.

Target run 37119274257 generated 122,955,310 bytes of unchanged Rust after the
operator explicitly increased the backend virtual-memory bound to 6 GiB. The ZIP
contains 177,490,347 expanded bytes including duplicate frontend checkpoints.
Keep the default inspection budget at 64 MiB; expose `--max-expanded-mib` with a
hard ceiling of 256 MiB for this measured case. The operator supplies the budget,
never the archive. Report expanded size and budget in the result, retaining every
digest, source, path and observation check. This budget increase does not turn
the observed compilation failure into a success.

MetaRocq tmQuoteRecTransp with true can capture opaque dependency bodies as AST
data in Type. tmQuoteModule and tmQuoteConstant with true enable additive module
snapshots. A snapshot is not automatically dependency closed. A quoted proof
continues to express its original proposition; erasure does not turn it into a
Rust ownership or execution theorem. Those claims require checked refinement and
proof transport. Z3_TAC qualification remains tool qualification, not that bridge.

The target uses syn/quote for a narrow generated Rust printer repair; its raw
Peregrine output is retained. The repair is an additional unverified translation
boundary. Compilation, bounded Kani checks, and a nonempty proof AST cannot
discharge the Rust/HOL4 source, self-hosting or machine-code obligations.

Validation: adverse recipes, undeclared outputs, changed support and partial
frontend failure must fail closed. Existing budgets, artifacts, original source
bindings, and HOL4/MCP/TacticToe paths remain inherited from the prior stack.

Rejected: rewriting original MetaRocq, silently dropping unsupported plugin/Ltac
sources, renaming Gallina terms as Rust semantics, and rebuilding dependencies
before inspecting the existing artifact.
