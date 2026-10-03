# Generated candidates

`pcuic_isapp.ast` and `pcuic_isapp.rs` are the unchanged original outputs recovered
from GitHub run 37106552663. Their origin and hashes are recorded under
`.metarocq/evidence/historical-isapp/`. The generated licenses are preserved here.

`build.rs` uses syn/quote to normalize the raw Rust into Cargo's output directory.
It repairs diagnosed printer errors; it does not replace the generated predicate.
The normalizer's regression compares every recovered function body before and
after transformation. This is a syntax check, not semantic refinement.

The current extraction recipe requests `retained.ast` and `retained.rs` for an
original opaque proof quoted into Type-level AST data. Aegis publishes the complete
output set only after the real Rocq/Peregrine processes succeed. See `docs/STATUS.md`
for observed qualification outcomes. Never label handwritten code as extracted.
