# Original-source proof automation

This layer adds proof search to the original MetaRocq/Peregrine experiment.
It does not select the Rust-native formalization or claim a verified MetaRocq
binary. It stacks on the checked compiler checkpoint in PR #58.

## Executed HOL4 checks

The original CakeML x64 evaluator produced 67,910 code bytes and 354 data
words for the explicit bootstrap probe. `OriginalCompilerOutputAutomation`
uses reconstructing `HolSmtLib.Z3_TAC` to prove code-address bounds and
code/data offset separation under their stated integer layout assumptions.
These propositions describe an abstract contiguous image; they do not assert
the semantics of a loaded ELF executable or of the project sources.

`CompilerOutputAutomationLib` extracts the exact numeric length clauses from
the compiler theorem and reconstructs those two layout proofs. Its actual
contract build exported four closed theorem objects and rejected seven inputs:
an open theorem, an oracle-backed theorem, an unrelated theorem, two incorrect
image types, and two same-type images absent from the compiler theorem.
Inspection checks the exact conclusions, empty hypotheses, no local axioms,
and only the normal `DISK_THM` loading marker.

TacticToe proved that the emitted code is nonempty, using 1,759 recorded tactic
calls. It prints the synthesized proof script, and HOL4 checks the resulting
closed theorem. The reusable helper prioritizes an ordinary simplifier call
through TacticToe's supported API, restores the previous preference, and uses
a 30-second search budget. The cache is guidance, never proof evidence.

`PeregrineGeneratedCompileScript.sml` invokes both helpers on its own actual
compiler result. This producer integration has not executed yet: the original
source pipeline has not supplied the required Peregrine compiler input.

## Existing .agents facilities

`prepare_original_proof_automation.sh` reuses the clean HOL4/MCP source pins
from `.agents/contracts/toolchain.json`, `agentinfra.hol4.environment`, the
persistent TacticToe cache, executable identities, and the existing
`check_hol4.py` positive/negative qualification. Z3 4.12.2, MCP SDK 2.3.0 and
FastMCP 4.0.11 are pinned separately; the installed MCP Python/TypeScript
sources are compared with the exact pinned checkout. The installed package
versions and executable hashes are retained with the input receipts.
The existing local tool environment was reused. Python 3.11 or newer is
required; an existing environment can be selected with
`ORIGINAL_PROOF_AUTOMATION_VENV`.

The actual `.agents` qualification is `QUALIFIED`, including reconstructed Z3
proofs, negative controls, and the real stdio MCP smoke. The separate
`inspect_original_compiler_mcp.py` successfully loaded and inspected the
compiler theorem, four library theorems and the TacticToe theorem. It treats
SML exceptions as failures even when the MCP response says `isError=false`.
MCP observations do not replace the direct Holmake proof builds. The Aegis
runtime's PostgreSQL prerequisite remains blocked in this workspace; these
tool qualifications do not bypass its canonical publication/formal gates.

Full compiler-ancestry recording remains incomplete. Two Poly/ML child
launches stalled with idle children; their logs, process observations and
cache checkpoints were preserved before interruption. A narrow serial
launcher recipe changes process transport only, rejects private-group use,
and leaves proof search, source hashes, cache validation and publication in
the original HOL4 SML. The unchanged `smlOpen` and recorder structures are
rebound to the adapted launcher. The latest resume exits nonzero on an
abandoned pair lock. A real missing-theory run also exits nonzero despite an
existing cache manifest. No completed full recording is claimed.

## Rocq-side Tactician

The official `coq9.1` Tactician commit
`59ca1a9b1e0d9edd2bf5daf3d46edc6bf470ef89` explicitly supports Coq/Rocq core
9.1. The observer invokes its qualification once after the CakeML controller,
using the existing exact Rocq switch. A chunk-coverage example trains the
learner, `Timeout 30 synth` generates a second proof, and MetaRocq quotes that
proof as Type-valued AST data. The script requires compilation and a closed
assumption report before emitting its qualification receipt. Successful
qualification enables Tactician recording in the new retained-root files.

The local attempt returned 69 because that switch is absent. The qualification
source has not been compiled here, and no synthesized Rocq proof is reported
as produced. The explicit CI producer is the next execution boundary.

## Source-build progress and remaining proof work

The two old `computeLib.the_compset` updates in the CakeML parser and program
translator now use the pinned HOL4 `computeLib.add_funs` API with the same
theorem lists. The parser build advanced to old context-free tactic calls in
`ml_translatorLib`; the exact failure is preserved. Original CakeML and HOL4
tracked source remains unchanged. The source-name failure seen in run
37258752235 is repaired from `Stdlib.String.string` to
`Stdlib.Strings.String.string`.

The distinct three-project loader still requires
`MetaRocq.Erasure.EGlobalFragment`, which is a physical source file absent from
the upstream erasure build manifest. It has not been silently removed from
coverage or treated as compiled. Full source coverage, executable proof
replay, the verified Gallina guard, the Peregrine/CakeML semantic bridge,
and an exact source-specification-to-machine theorem remain open. Z3,
TacticToe and Tactician accelerate proof obligations; their availability
does not prove those missing statements.

The immutable `.o11y/local-original-proof-automation-20261005` checkpoint
contains actual kernel exports, reports, raw successful and failed logs,
cache archives and hashes. The 27 orchestration/mutation boundary cases
passed; those tests are not substitutes for theorem checks. Earlier PR
checkpoints and completed CI trace directories are retained byte-for-byte.
