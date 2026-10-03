# Corrected defects and policy conflicts

| ID | Severity | Finding and correction | Evidence |
| --- | --- | --- | --- |
| F01 | High | TDD remained executable in policy compilation, mutation authority and final audit. Replaced the entire generic controller; removed retired commands, packs and release mirrors. | `candle.py`; `test_retired_test_order_commands_are_not_reachable`; Git diff against baseline |
| F02 | High | Framework lacked an authoritative original Candle contract. Added the ITP 2022 authority, pinned original repositories, exact HOL4 byte/blob checks, original-symbol navigation and evidence bindings. Additional theories use the same pinned repository objects. | `contracts.py`; `contracts/authority.json`; real original-checkout validation |
| F03 | Medium | Model/role and quality machinery forced the prior model, maximal effort and unrelated engineering work. Requested GPT 6 Astra; removed role and optional-quality mandates. | `framework.toml`; `modules/codex/config/managed.toml`; tracked-source searches |
| F04 | Medium | Incremental remote preservation was prose, not a lifecycle gate. A new managed cycle now requires its predecessor's live PR/head and correct stacked base. Dirty work or mismatching remote heads cannot be checkpointed. | `checkpoint`, `freeze`, `attest`; lifecycle and PR mismatch checks |
| F05 | High | Exit status alone can masquerade as a proof. Adapters now require exact harness/count/status output, qualified versions, nontruncated execution and source stability. Results remain scoped observations. | Adapter negative fixtures and real Kani/Verus positive/false obligations |
| F06 | Medium | First live Kani qualification exposed a false rejection: an UNSAT solver diagnostic was confused with an unsuccessful cover property. Parse property-status fields and the exact one-harness summary instead. | Failed run 36315096513; corrected successful run 36315329725; parser regression |
| F07 | Medium | Inherited POSIX process cleanup returned early after the parent exited, leaving descendants holding capture pipes. Terminate the process group even after its leader exits. | `process.py`; parent-exit/descendant-capture regression |
| F08 | Medium | Inherited automatic abandoned-lock deletion had a check/unlink race: a recovery worker could delete a newly acquired lock. Refuse automatic reclamation and require exclusive inspected recovery. | `locks.py`; dead-owner regression confirms bytes remain unchanged |
| F09 | Medium | Case-sensitive guards protected AGENTS.md but not the actual target's AGENTS.MD. Recognize instruction filenames case-insensitively. | `governance.py`; uppercase-instruction write rejection |
| F10 | Medium | API redirect handling checked destination after following it; a credential could have followed a redirect. Disable redirects before transmission. | `checkpoints.py:NoRedirect`; fixed GitHub API origin |
| F11 | Medium | A PR response or local HEAD could change during checkpointing. Validate PR number, repository/base/head, Git ref and final local cleanliness. | `checkpoints.py:attest`; exact-head CI qualification |
| F12 | Medium | Framework evidence omitted governing root/model configuration identity. Include root AGENTS.md, framework/version and model configuration in the digest. | `contracts.py:framework_digest` |
| F13 | Low | Retained package metadata advertised an installed CLI although authority assets resolve relative to a source checkout. Retired the unsupported package metadata and documented source-checkout execution. | Deleted `infra/pyproject.toml`; README |
| F14 | Medium | Default Actions checkout tested a synthetic merge commit. Pin CI to the PR's exact head; disable persisted checkout credentials. | Both Candle workflows |
| F15 | Medium | A generated template could be bound without resolving its semantic, license or reuse placeholders. Reject unresolved REPLACE fields. | Schema negative fixture; `validate_plan` |

F05 is not a claim that log parsing proves semantic correspondence. It blocks common
misclassification and stale/empty results; the open trust boundaries are documented
separately. Old tests for deleted behavior were retired with that behavior. Remaining
checks protect the new contract and reused primitives, without imposing test-first order.
