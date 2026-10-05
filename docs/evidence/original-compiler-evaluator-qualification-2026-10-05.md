# Original compiler evaluator qualification, 2026-10-05

The pinned CakeML in-logic x64 evaluator now builds and runs against the
pinned HOL4 kernel. `OriginalBootstrapCompilerProbeScript.sml` evaluates an
empty CakeML declaration list, checks that its compiler theorem has no
hypotheses or extra oracle tags, and retains the exact compiler code object
under `original_bootstrap_probe_machine_code`. The actual positive build log
records `Kernel-checked closed in-logic x64 compiler probe.`

This qualifies the compiler infrastructure only. It does not certify a
Peregrine, MetaRocq, or Rocq executable, nor any of their source specifications.
The assembler export is retained alongside the HOL theory; it is not
substituted for the code-byte object.

The first parallel build stalled before a remaining theory process started.
The original execution session was interrupted with status 130; serial
execution reused its checked products. That attempt exposed a load-time
`asmLib` proof outside a current theory. The derived source now scopes HOL4's
existing legacy context policy to that single call while preserving its
proposition and tactic. Loading the evaluator also exposed a renamed
documentation setting; its current name is used. The original checkouts and
HOL4 kernel sources remain unchanged.

The local resume used the existing derived worktree explicitly. Its updated
receipt binds all 96 audited source adaptations and the actual compiler
library artifacts. All 119 theory data files recorded before the library
repair remain byte-identical. The default build is now serial; an explicit
positive `HOL4_BUILD_JOBS` value can select parallel execution.

The immutable `.o11y/local-original-compiler-probe-20261005` checkpoint retains
the positive theory, full failures, preparation receipts, and compressed
compiler build products. These products preserve progress and accelerate
future builds; they do not replace source replay or semantic refinement.
`FINALIZED` means the observation is complete, not that the E2E gate passed.

Nine compatibility-boundary regressions pass, preparation input hashes check,
and shell syntax and whitespace checks pass. The actual compiler probe was
kernel-checked; fixture tests are not proof evidence.

The earlier probe with `compiler` as an ancestor exposed a separate parser
API incompatibility at `cmlPEGScript.sml`: `computeLib.the_compset` is now a
context accessor rather than a reference. That failure is preserved. The
positive direct-AST probe uses the `ast` ancestor; the full serialized-input
path and the missing source-to-machine refinement remain open.
