# ADR 0004: retain proof syntax, then prove translation separately

Status: accepted bootstrap architecture; full-source extraction and refinement OPEN.

Stakeholders: the solo supervising engineer and untrusted code-generating agents.
Concerns: reuse all branch progress, retain proofs, minimize handwritten implementation,
make Rust syntax available to generators, and keep proof claims independently checkable.

Decision: retain original MetaRocq files byte for byte and add separate Rocq modules.
Use tmQuoteRecTransp with true for opaque dependency bodies. Quote a theorem's
environment and root into Ast.program in Type before calling Peregrine. Return
that entire data structure, not a digest or source-code string. Also provide a
generic module snapshot using tmQuoteModule, tmQuoteConstant and tmQuoteInductive.
Module snapshots are not dependency-closed programs and must not be presented as such.

The first retained root is original PCUICAstUtils.mkApps_tApp (opaque Qed). A
kernel-checked concrete example must show its body exists before extraction.
This is a retention check, not a Rust correctness theorem. The Rust output still
needs compilation, runtime retention inspection and a proved representation relation.

Reuse the actual isApp output from GitHub run 37106552663, artifact 11269886433,
SHA-256 94f5b605c7f88282f8a1e2e4b31afa8661c9b2e02a0d131bb664018e28a46752.
The independent Aegis inspector accepted the packet at exact source 93387eac.
That run generated real code but failed Rust compilation. Preserve those bytes
and its dependency lock; do not fabricate or manually rewrite the predicate.

A small syn/quote/prettyplease transformation repairs two observed printer errors:
Debug derivation on a function field, and an unused erased type-alias parameter.
An associated-type identity keeps the generic parameter without adding a runtime
value. Build.rs runs the transformation reproducibly; raw Peregrine output remains
unchanged. Visibility is exposed for inspection. This transformation is unverified;
syntax parsing and successful borrow checking are not semantic equivalence proofs.

Continue MetaRocq PR #4 to reuse its completed dependency cache, and pin Aegis PR
#17, which descends from the complete #12-#16 stack. Original and alternative
branches remain intact. The alternative Candle coordinator has an incompatible
state/packet format; its existence is retained in the earlier Aegis ADR, not erased.

Proof transport must relate Gallina/PCUIC evaluation, typed erasure, Rust lowering,
ownership, primitive behavior, allocation failure, and generated macro expansion.
Quotation alone does not retarget a proposition to another implementation.
Charon/Aeneas remain the preferred existing Rust-semantics path; use the pinned
Kontroli HOL4 interface generator once actual translated HOL4 exists. syn/quote
provide Rust syntax, not semantics. Verus, VerusBelt and rustc are reuse candidates,
not newly trusted axioms. proc_macro attribute/derive are compiler facilities,
not separate semantic translators. Avoid adding unrelated parsers or dependencies.

Proof terms can be reified; Ltac programs, OCaml plugins, build tools and foreign
runtime primitives are not Gallina terms automatically handled by that technique.
Inventory them and require explicit implementations/semantics rather than silently
counting them as extracted. Keep an independent bootstrap root: a prover checking
proof data about itself does not by itself establish its own soundness.

Validation: compile real generated source; bound Kani probes explicitly; reject
missing opaque bodies, incomplete output sets, changed support, and stale artifacts.
HOL4/Z3 tool qualification is inherited, but full PCUIC and Rust refinement remain
OPEN, as do the machine-code and self-hosting obligations.
