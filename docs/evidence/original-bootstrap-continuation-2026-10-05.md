# Original-source bootstrap continuation, 2026-10-05

This layer is based on PR 52's completed trace commit
`9280a62f5c8713e0d65290aa29a6bdea202015fa`. Its immutable
`.o11y/github-37236283573-1-7a6eaf517048` directory is preserved unchanged.

The cloud run compiled `PCUICModuleManifest.v` and `SelfSnapshot.v`, then
stopped at `EmbeddedPeregrine.v`: `Cannot find module MonadNotation`.
The bootstrap adapters now explicitly import ExtLib's `Monads` and open
the monad scope, instead of relying on a transitive `Require Import` to
re-export the notation module. The corrected files still need a real Rocq
compilation; Python regression tests do not validate Gallina.

The unified workflow again has explicit dispatch, explicit caller, and
owner control-issue triggers only. PR triggers introduced in PR 51 were
inconsistent with the earlier explicit-only requirement and are removed.
Completed toolchain caches and trace capture remain enabled.

The local compiler-library build reached `ml_translatorTheory` and exposed
a grammar mismatch between the two pinned releases. HOL4 commit
`bec0b16a8e4efed5c8aa75afe14797543da0eccd`, dated 2026-02-08, assigns
`MOD` fixity `Infixl 650` in `src/num/theories/arithmeticScript.sml`.
The current pinned HOL4 assigns `Infixl 600`. CakeML's existing expression
`n * p MOD q` must retain its historical parse `n * (p MOD q)`.
The derived CakeML preamble restores that grammar, without modifying the
original statement, the pinned source, or the HOL4 kernel. The exact
compatibility patch and historical revision are recorded in the recipe.

Validation: 19 existing materializer/orchestration regression tests pass;
manual-only YAML assertions, shell syntax, and diff whitespace checks pass.
The resumed real HOL4 compiler-library build is still in progress. There
is no claim of a completed compiler library, complete proof replay, a
qualified Peregrine binary, or a source-to-machine correctness theorem.
