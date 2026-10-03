# ADR 0007: finish the metatheory bootstrap before implementation

Status: accepted planning boundary; metatheory verification remains BLOCKED.

## Stakeholders, concerns and scope

The supervising engineer needs independently replayable evidence for untrusted agent work.
The runtime consumes `roadmaps/metarocq-bootstrap.json`; it must not hard-code its tasks.
This decision preserves all existing extraction, retention and PR-stack work.
It specifies required results, not a claim that the formalization is finished.

## Decision and correspondence

The twelve-task DAG starts with a runnable source audit, then requires the original
checker bootstrap, faithful retained proof data through untyped erasure and CakeML,
shared canonical syntax/semantics, a Rust-aware model, proof transport and equivalence.
The `metatheory-verified` task is the implementation gate. Only afterward may the
verified specification be transformed into a detailed implementation roadmap.
Later implementation entries state required scope; they must be expanded at that gate.
All paths in task inputs/outputs are relative to the MetaRocq-rs working tree.
Future theorem names identify required obligations; they are not existing theorems.

Original MetaRocq mathematics is the contract. JSON metadata is not that formal
specification. Its shared encoding needs a grammar, semantics, decoding proofs and
an explicit PCUIC-to-HOL4 interpretation. Rust modeling must include ownership,
borrowing, types, operations, failures and every original source inventory item.
Reuse existing MetaRocq, Peregrine, CakeML and qualified Charon/Aeneas developments.

## Verification and current blockers

Only `source-audit` currently has an executable command. Null commands are BLOCKED.
An independent replay adapter must check actual theorem statements, assumptions and
proof objects against exact bound sources/artifacts; process exits, hashes, status
fields, JSON assertions and bounded regression evidence cannot establish completion.
Until qualified adapters exist, proof tasks and the implementation gate stay closed.

At MetaRocq `7197056adbb9c15288b4c8d43407bf25786f723e`,
`safechecker-plugin/theories/Extraction.v:36-48` assumes guard correctness;
`safechecker/theories/PCUICSafeChecker.v:2494` exposes normalization hypotheses.
Target `extraction/RetainedQuote.v` checks a concrete opaque body and sharing equality;
these checks do not prove general dependency closure or Rust semantic transport.
At Peregrine `d768b83ffa7dab35b8d72241f0570b5bb6aedae9`,
`theories/backends/CakeMLBackend.v:44-50` admits a wrapper obligation and `:57`
assumes `trust_coq_kernel` for all inputs. Discharge or avoid these assumptions and
instantiate upstream backend proofs; this finding does not invalidate those proofs.
`doc/backends.md:13,47` specifies untyped CakeML and the flags
`--sexp=true --exclude_prelude=true --skip_type_inference=true`; its Rust backend
and printer are unverified. Exact compiler/runtime/linker/ISA trust remains required.

## Supervision and persistence

One dedicated worker runs at a time, reading all task contexts and writing only its
own. The host attests model and maximum effort; self-reported flags are insufficient.
GPT-6 Astra authors roadmaps and executes formalization. Automatic host hooks persist
all exposed context, actions and tool results with no additional model calls, logging
prompts or generated summaries. Mechanical metadata indexes supply highlights.
Existing explicit decisions/summaries may be recorded; private chain-of-thought is
not available for capture and must not be requested or stored. PostgreSQL events are
append-only for application roles, with every logical write mirrored to Git and
durable replication watermarks; outstanding replication blocks advancement.
Separate database code, event content, roadmaps and pipelines in directory trees.
Administrators can rewrite PostgreSQL or Git: independent replicas are necessary,
and no absolute irreversibility claim is made. No proof or implementation completion
is established by this ADR or its roadmap.
