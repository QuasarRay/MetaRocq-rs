# CakeML historical MOD grammar in theory contexts

The PR 53 preamble adjustment did not survive HOL4's ancestor grammar loading.
The real `ml_translatorTheory` build still parsed `n * p MOD q` as
`(n * p) MOD q` and failed `MOD_COMMON_FACTOR_ANY`. That failure is preserved
in `.o11y/local-hol4-mod-qualification-20261005/preamble-setting-failure.log`.

The adapter now restores the historical `Infixl 650` grammar immediately
after the complete header of each pinned CakeML theory script containing
`MOD`. The original statement and proof bodies remain byte-identical.
There are 93 affected scripts in the pinned revision. Every modified file,
its before/after hash, and the complete patch are in the recipe. The
recipe address includes all adapted files, so previous worktrees and proof
objects are preserved. Unexpected headers and edited progress are rejected.
Compiler preparation also binds every affected file's physical hash.

The real pinned HOL4 kernel compiled `MODContextQualificationTheory`.
The qualification checks that the parsed term equals `n * (p MOD q)`, proves
the historical common-factor statement, and rejects open hypotheses or
unexpected theorem tags. Exact script, library, kernel log, theorem object,
failure log, and compatibility recipe are preserved in the immutable
qualification checkpoint. This proves the arithmetic/grammar qualification;
it does not prove application replay or source-to-machine correctness.

Seven worktree/grammar regression cases and six exact-compiler orchestration
cases pass. The full in-logic compiler-library build has been restarted with
this recipe and is still in progress. Its successful completion must be
recorded separately; it cannot be inferred from the small qualification.

The completed cloud bootstrap saved the extraction cache under
`metarocq-extraction-Linux-badb0b3c39b84b3f5613694f083161c29fc3cae656b6e91aeb9d0100ab9f8868`.
The updated branch workflow uses that namespace. The control-issue dispatch
currently loads the workflow definition from `main`, whose older cache
namespace differs. A direct explicit branch workflow dispatch is needed to
exercise the updated cache restoration before these workflow changes merge.
No cache hit is claimed for the ongoing control-issue run.
