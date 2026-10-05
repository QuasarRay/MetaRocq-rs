# Research: generated Standard ML interfaces for CakeML

This note records the design inputs for the generated HOL4 / TacticToe / Z3_TAC
wrapper pipeline. It distinguishes production precedents from features that
still require project-specific proof work.

## Existing CakeML ecosystem mechanisms

### Proof-producing HOL-to-CakeML translator

CakeML's `translator/` translates ML-like HOL functions to CakeML syntax while
constructing HOL4 correctness theorems. The generated program is therefore not
trusted merely because it was generated: the translation attempt must also
produce a kernel-checked certificate.

Relevant upstream:
- https://github.com/CakeML/cakeml/tree/master/translator
- https://cakeml.org/

Reuse decision: copy this proof-producing architecture. The public API
extractor and code emitter are untrusted producers; publication requires
independent HOL4 checks over the generated API manifest, wrapper semantics and
exact CakeML compiler theorem.

### CakeML compiler and FFI semantics

CakeML gives FFI calls an explicit semantics and carries those effects through
verified compilation. Current CakeML also exposes `Runtime.customFFI`.

Relevant upstream:
- https://github.com/CakeML/cakeml
- https://github.com/CakeML/cakeml/blob/master/how-to.md

Reuse decision: generated CakeML wrappers use only byte/string payloads and
opaque numeric handles across the foreign boundary. Native Poly/ML values,
closures, references and theorem objects never cross the boundary.

The proof claim is conditional: the exact CakeML wrapper machine code
implements the canonical API whenever the foreign implementation satisfies the
corresponding generated foreign contract. CakeML compilation does not prove
arbitrary Poly/ML/C code correct.

### Candle API insulation generator

CakeML/Candle contains `candle/insulate.py`, which reads CakeML type output and
machine-generates an OCaml insulation layer. It handles module names, generated
bindings, eta expansion and selected type aliases.

Relevant upstream:
- https://github.com/CakeML/candle/blob/master/candle/insulate.py

Reuse decision: this is the closest ecosystem precedent for bulk interface
generation. The present pipeline generalises the idea to
SML-signature-to-canonical-IR-to-CakeML wrappers and adds proof obligations and
fail-closed coverage accounting.

### Pancake

Pancake reuses the lower verified CakeML compiler stack for C-like systems code
and is relevant if a future version replaces the small external ABI shim with
a separately verified low-level component.

Relevant upstream:
- https://cakeml.org/pancake.html
- https://github.com/CakeML/cakeml/tree/master/pancake

Current decision: do not make Pancake mandatory. Keep the transport contract
byte-oriented so a verified Pancake shim can be substituted later without
changing the CakeML API.

## Gap

No CakeML ecosystem project was found that already:
1. consumes arbitrary HOL4/Standard ML public `.sig` interfaces,
2. classifies the complete API including higher-order values and refs,
3. generates a CakeML-facing mirror plus an SML adapter,
4. proves the mirror correspondence in HOL4, and
5. composes that theorem with exact wrapper machine code.

## Reused MetaRocq-rs work

This branch is stacked on PR #59 and reuses:
- `.agents` HOL4/MCP and reconstructed-Z3 qualification;
- TacticToe persistent cache and recorder handling;
- `CompilerOutputAutomationLib` theorem-cleanliness checks;
- negative-control policy for hypotheses, axioms and oracle tags;
- exact CakeML compiler theorem inspection;
- immutable `.o11y` artifact conventions;
- pinned HOL4/CakeML/Z3 identities.

The new work begins above that substrate: complete public API discovery,
canonical representation, code generation and generic correspondence proofs.
