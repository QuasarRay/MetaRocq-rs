# Original-source bootstrap continuation

The original Peregrine and MetaRocq source bootstrap is authorized independently
of the restriction that only Astra may formalize the canonical Rust-native
MetaRocq-rs implementation. This continuation does not modify that Rust-native
formalization or its roadmaps.

The requested end state is still **not established**. No Peregrine or MetaRocq
binary is qualified here as satisfying every original source specification.

1. PR #46 reuses six existing quotation fixes from the earlier Peregrine branch.
   The original commits and historical branches remain preserved.
2. PR #47 replaces the compiler-function-only replay root with references to
   every declaration emitted by MetaRocq for the pinned 56-module manifest.
   Shared roots are materialized once. A nonempty, opaque-body coverage check
   must compile in Rocq before extraction.
3. This layer archives discovered generated ASTs, CakeML candidates, compilation
   observations, Rocq objects, and HOL4 artifacts inside the unique run trace.
   Hashes bind captured bytes; archives are split into 64 MiB parts for Git sync.
4. A failed stage 03 is not automatically executed again by the always-run
   Peregrine machine-code lane. Candidate reuse requires the producer-input
   checksum receipt to match the current source and candidate bytes.

## Verification observations

- Eight root-materialization regression tests pass, including omitted roots,
  truncated inventories, malformed input, deduplication, and chunking.
- A checkpoint byte round-trip passes. Repeated capture and capture into a
  finalized trace are rejected. The failed-stage duplicate-producer control
  returns exit 44 before candidate generation.
- Shell syntax, exact pinned-source/provenance checks, and the existing original
  source inventory check pass.
- That inventory covers 755 tracked files: 596 Rocq modules, 33 OCaml plugin
  files, and 126 other files. File coverage does not establish quoted/replayed
  coverage. The older 105-module PCUIC snapshot is not the full 596-file corpus.
- Run 37227812413 failed at the missing bytestring-scope import, before LambdaBox
  generation. Its finalized trace commit `6a90ea46fa10619810b8d04383b9523948d24e4e`
  is retained by merge ancestry. Its original trace bytes have not been rewritten.
- Run 37231682401 explicitly targets PR #46. Its completion result was pending
  when this checkpoint was written; full Rocq compilation is not claimed.

## Exact in-HOL compilation follow-up

The replay membership match now rejects inductive declarations as well as
missing constants. The compiler build binds reuse to input and output hashes,
not modification times. When the binding changes, prior compiler proof objects
are preserved before regenerating the application theory. HOL4 dependency
theories remain reusable.

The theory reads a stable, materialized input that is also a declared Holmake
dependency. The scripts resolve the pinned Poly/ML layout under `.hol/objs`
and reject conflicting flat and nested artifacts. The legacy workflow uses the
same compilation helper instead of copying a script into an upstream checkout.
The actual parse and compiler-evaluation theorem objects must have no hypotheses
or additional axioms. The permitted tags are empty or HOL4's standard `DISK_THM`
dependency-load marker, matching CakeML's `check_thm`; every other oracle tag is
rejected. Pinned dependency proof objects remain part of the trust boundary.

Six orchestration regressions pass: exact reuse, changed bytes with unchanged
timestamp, modified theory, missing assembler output, failed compiler, and
ambiguous artifact layout. These fixtures test orchestration, not HOL semantics.
Full compiler evaluation and source-to-machine qualification remain pending.

## Executed local kernel qualification

Both `PeregrineSelfHostContractTheory` and `MetaRocqSelfHostKernelTheory` compile
against the pinned HOL4 built locally with Poly/ML 5.7.1. The original Peregrine
contract escaped its HOL conjunction incorrectly, and both scripts referenced
an unavailable `check_thm` helper. Their explicit expected-conclusion, hypothesis,
and tag checks now execute successfully with the stock disk-load policy.

The exact scripts, two emitted theory objects, compilation output, and the
earlier tag-rejection diagnostic are preserved with checksums under
`.o11y/local-kernel-qualification-20261004`. These small qualification theorems
establish neither Peregrine/MetaRocq semantics nor machine-code correctness.

## Remaining mathematical and executable boundaries

The pinned `CakeML.Backend.Pipeline.compile_to_malfunction` has an admitted
obligation and sets `obseq` to `True`. The pinned Peregrine CakeML wrapper also
has an admitted obligation and `trust_coq_kernel`. These are not existing
semantic-preservation proofs available for end-to-end composition.

`MetaRocq.Template.Checker` explicitly describes itself as fuel-bounded and
unverified. Retention and a successful diagnostic replay cannot supply the
missing HOL4 checker-soundness theorem. The verified SafeChecker route still
requires its guard and normalization assumptions to be accounted for.

The requested chain still requires a genuinely checked LambdaBox/EAst-to-CakeML
semantic theorem, a HOL4 theorem about the exact replay program and its source
corpus, exact source-to-machine composition, and independently checked embedded
certificate correspondence. `PeregrineSelfHostE2EScript.sml` remains absent.

Until a first formally qualified Peregrine compiler binary exists, the second
bootstrap cannot use such a binary to compile and qualify original MetaRocq.
Retained source proof terms also do not implement an extracted Ltac interpreter
or port the original OCaml plugins. Those facilities cannot be counted as
replayed merely because their source files occur in the inventory.
