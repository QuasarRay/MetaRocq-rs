# Direct Peregrine bootstrap imports, 2026-10-05

The explicit GitHub run [37253329442](https://github.com/QuasarRay/MetaRocq-rs/actions/runs/37253329442)
completed the pinned Rocq/MetaRocq/Peregrine installation and compiled
`PCUICModuleManifest.v` and `SelfSnapshot.v`. It passed the previous
`MonadNotation` lookup failure, then stopped at `EmbeddedPeregrine.v`, line 21:
`The reference result' was not found in the current environment.`

The pinned Peregrine source defines `result'` in `theories/Utils.v`, not in
MetaRocq's `ResultMonad.v`. The bootstrap overlays now import that module
directly. The related interfaces also name the bytestring input type and the
standard Rocq string used by CakeML's output AST explicitly. No source theorem,
proof body, backend trust assumption, or semantic acceptance gate is changed.

The completed trace commit `f2c91d7f0aa4d802a0a4e1c9910600614b5ad331`
is merged into this layer. Its
`.o11y/github-37253329442-1-7c902b87ee7d` subtree remains byte-identical, including
the captured producer checkpoint and the failing compilation log. It is
failure evidence, not a certificate of an executable or source specification.

Validation: the existing Peregrine source/provenance contract passes and
`bootstrap.py sources` reports `SOURCES_MATCH`; the diff whitespace check
passes. These checks do not validate Gallina. Real Rocq compilation of the
corrected overlays and generation of the retained three-project LambdaBox
remain pending. The HOL4 compiler-library build is independent of this import
fix; no completed source-to-machine proof is claimed.
