# Pinned three-project MetaRocq source bundle

`tools/materialize_original_source_bundle.py` creates an independent, pinned
MetaRocq source worktree. Its `vendor/rocq`, `vendor/peregrine`, and
`vendor/rocq-stdlib` directories contain the complete corresponding source
worktrees, including their licenses and tracked symbolic links. Existing
reference checkouts, edited files, previous bundle recipes, and earlier traces
are preserved. The separate standard library matches the existing
`rocq-stdlib.9.0.0` bootstrap requirement.

The actual local materialization indexed every tracked file and compared its
physical bytes with the pinned Git blob. This is source identity evidence.

| Project | Tracked files | Gallina files | Mapped modules | Unmapped Gallina files |
|---|---:|---:|---:|---:|
| MetaRocq | 755 | 596 | 594 | 2 |
| Rocq 9.1.1 | 5,244 | 2,608 | 103 | 2,505 |
| Peregrine | 184 | 66 | 66 | 0 |
| Rocq Stdlib 9.0.0 | 1,098 | 845 | 564 | 281 |
| Total | 7,281 | 4,115 | 1,327 | 2,788 |

Module names come from the pinned build load paths. Unmapped sources include
regressions and plugin examples; they are preserved and listed, rather than
counted as successfully replayed. Rocq's `kernel/typeops.ml` is production
OCaml. The Gallina checker and PCUIC metatheory used here are MetaRocq's
`safechecker/theories/PCUICSafeChecker.v` and `pcuic/theories`.

The Peregrine inventory emitter now reuses `DeclarationReplayInventory.v`.
The larger bundle uses that same Rocq `tmQuoteModule` enumeration, with an
additional `tmQuoteConstant ... true` distinction between retained bodies and
source assumptions. Python materializes every emitted reference and checks
module completion, root counts, classification consistency, and truncation;
it does not select or accept theorems.

`UnifiedRetainedReplay.v` quotes one dependency-closed all-declaration root
with opacity bypass. It retains the quoted environment and proof bodies as
Type-valued AST data, checks emitted body/inductive/assumption coverage, and
uses the standard map implementation for declaration lookup. The extraction
root explicitly carries unresolved replay and refinement obligations. It is
a retained candidate image, not an executing verified checker or a certified
machine-code image. Ltac and plugin source bytes are preserved; this layer
does not implement an extracted tactic interpreter.

Run the candidate producer explicitly:

```sh
bash tools/build_original_three_project_lambdabox.sh
```

It materializes the source bundle, copies the Gallina overlay inside MetaRocq,
loads every mapped module, compiles the Rocq-emitted root inventory and
retention checks, and attempts one LambdaBox extraction and Peregrine CakeML
lowering. Missing module artifacts fail compilation. It never drops a module
to obtain a successful candidate. The existing unified controller also
collects the complete source inventory in stage 02.

The real local candidate attempt stopped with exit 69 because the pinned
Rocq/MetaRocq/Peregrine installation is unavailable in this workspace. No
three-project LambdaBox, CakeML candidate, replay result, or HOL4
source-to-machine theorem was produced. The new Gallina overlay therefore
remains uncompiled. An explicitly requested cloud bootstrap of PR 53 is
running separately; its completion cannot be inferred from this receipt.

Validation: seven source-bundle regression cases and eleven declaration-root
renderer cases pass, including preservation of edited progress, complete
tracked-file transport, namespace collisions, source assumptions, truncated
inventories, and rejected source injection. The existing source/provenance
contract, pinned-source bootstrap check, shell syntax, and whitespace checks
pass. These checks do not certify proof replay.

Full certification remains blocked by unmapped source declarations, the
closed verified Gallina guard implementation, replay-to-HOL4 refinement,
Peregrine's admitted/vacuous backend obligations, and the missing exact
source-specification-to-machine-code theorem. Compilation alone does not
discharge those obligations.
