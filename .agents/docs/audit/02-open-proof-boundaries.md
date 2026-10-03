# Open formal and semantic boundaries

## P01 — High: the Rust/HOL4 correspondence is not established

Original source identity and a symbol name do not prove that a Rust harness encodes the
same relation, quantifiers or assumptions. `validate_plan` checks the binding's shape;
`verify_references` confirms original bytes and finds a declaration. Neither is a HOL4
parser, theorem checker or semantics-preserving translator. The Rust implementation
and its bridge remain work for Candle-rs. This is a release blocker for any claim of
full equivalence, not a reason to substitute test examples for the shared contract.

Required closure: reuse original HOL4 files without translation; build/replay their
actual HOL4 environment; state and verify the representation/refinement relation;
independently review or verify generated adapters. If a generated Rust/Verus model is
used, prove its connection to the same original files rather than calling it the oracle.

## P02 — High: whole-system soundness does not transfer to Rust automatically

The paper's original implementation theorem is not a theorem about rustc output. Kernel
abstraction, state/context extension, theorem-export channel, parser, REPL, runtime and
compiler assumptions need distinct Rust obligations. Ordinary stdout or a unit example
must not be confused with the original trusted theorem-export channel. Kani bounds
must not be extrapolated to all terms or executions. Verus external bodies, axioms and
assumptions must remain in the human-readable trusted base.

Required closure: an explicit end-to-end argument or a narrower released claim. Do not
label a complete set of scoped CHECKED records as universal soundness.

## P03 — High: imported theory and transitive toolchain closure remain incomplete

The whole CakeML Git revision is pinned, with initial anchor byte hashes. Additional
selected HOL4 files are bound to objects from that revision. Imported HOL4 theories,
the HOL4 build environment, transitive solver/compiler binaries, OS and hardware are
not fully attested by this controller. Qualified Kani/Verus versions and executable
hashes improve provenance but are not a hermetic build certificate.

Required closure: reproducible dependency/toolchain manifests and independently replayed
HOL4 import closure for the selected release. The source pins were current at inspection;
they are not represented as the exact historical 2022 paper artifact. Record and resolve
material version discrepancies rather than silently overriding the paper.

## P04 — High under a hostile-agent threat model: receipts are not attestations

Runtime state and JSON evidence are writable by the same account as the implementer.
An agent capable of arbitrary shell writes can alter records, binaries or Aegis itself.
A SHA-256 is integrity relative to a stored expectation; it does not authenticate who
produced that expectation. Text output parsing also trusts the selected tool execution.

Required closure: a separately controlled verifier/CI environment, immutable reviewed
contract inputs and independent human replay. Aegis's audit deliberately reports
SCOPED_CHECKS_RECORDED and calls out human review; it does not assert independent approval.

## P05 — High if hidden inputs are used: workspace hashing is not build tracing

Tracked and nonignored source files are hashed. Runtime/evidence output, ignored files,
external dependencies and host configuration are not complete build-input closure.
A proof that includes ignored source or reads evidence as input could escape freshness
checks. The controller is not a filesystem sandbox for build scripts.

Required closure: an isolated reproducible build with declared dependencies, dependency
tracing or a constrained runner. Until then, forbid such hidden inputs in supervised
work and treat source freshness as conditional, not universal.

## P06 — Medium: reuse economics and specification adequacy need judgment

A nonempty reuse decision is reviewable but cannot prove that all reusable code was
searched, that the chosen license is compatible, or that handwriting is cheapest.
Likewise, a cited paper section cannot prove the adequacy of an obligation. Check these
once per bounded work item; do not add repetitive generic reviews or optional polish.
