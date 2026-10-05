# ADR 0018: Generated HOL4-family CakeML API wrappers

## Status

Experimental and fail-closed. Stacked on PR #59.

## Decision

Introduce a generator pipeline that treats the public Standard ML signatures of
HOL4, HolSmtLib/Z3_TAC and TacticToe as source API declarations and produces a
canonical, version-addressed CakeML API mirror.

The pipeline has five trust-separated stages:

1. **Discovery** — read pinned source trees and public `.sig` files.
2. **Canonicalisation** — emit a machine-readable API IR with source hashes,
   symbol provenance and explicit lowering classes.
3. **Generation** — a CakeML program consumes the canonical IR and emits the
   CakeML facade plus corresponding SML adapter declarations.
4. **Proof** — HOL4 checks that generated operations preserve the canonical
   request/result relation and malformed requests fail closed.
5. **Compilation** — CakeML's in-logic compiler produces exact code and HOL4
   compiler artifacts; publication requires `check_thm` on the composed
   wrapper theorem.

## Boundary representation

The generator must never map a Poly/ML heap object directly into CakeML.

- primitive immutable values -> canonical value encoding;
- products/lists/options -> structural encoding;
- `Term.term`, `Thm.thm`, `Context.t`, search trees and neural models ->
  opaque typed handles;
- `'a ref` -> generated get/set operations;
- function/closure values -> opaque callback handles and apply operations;
- exceptions -> explicit `Ok | Error` response values.

This prevents cross-GC pointer aliasing and makes the FFI semantic boundary a
total byte-level protocol.

## Safety theorem scope

"No undefined behaviour" means the generated CakeML wrapper and its exact
CakeML-generated machine code:
- do not dereference or manufacture foreign pointers;
- decode length-delimited values with total bounds checks;
- reject unknown operation, handle and type tags;
- represent foreign failure explicitly;
- invoke only the FFI event declared by the canonical contract.

The theorem is conditional on the foreign HOL4/TacticToe/Z3_TAC implementation
satisfying its generated contract. Correctness of Poly/ML, HOL4, TacticToe,
Z3_TAC and Z3 internals is outside this wrapper theorem.

## Completeness policy

The extractor accounts for every declaration in each selected public
signature. Unsupported declarations are emitted as `unsupported` records and
make the production gate fail. Debug profiles may select a subset, but complete
HOL4 API publication requires zero unclassified public symbols.

## Existing progress reused

PR #59 remains authoritative for Z3 reconstruction, TacticToe qualification,
HOL4 theorem hygiene, MCP inspection and proof-artifact preservation.


## Toolchain reuse

The production wrapper target deliberately reuses the exact CakeML and HOL4
pins already qualified by PR #58/#59. A newer CakeML release is unnecessary:
the pinned CakeML runtime already provides the generic `fficustom` entry and
the language already supports direct `#(api_bridge)` FFI calls.

Each generated wrapper therefore has the uniform shape:

```sml
fun generated_operation buffer =
  let
    val _ = #(custom) "Original.Signature.operation" buffer
  in
    buffer
  end
```

This keeps the foreign ABI to one runtime symbol and exposes the exact original
operation identifier as FFI configuration bytes, which is directly visible to
CakeML's characteristic-formula `xffi` rule.

## Dedicated FFI name

Generated wrappers use only `#(api_bridge)`.  The CakeML compiler turns this into the single native symbol `ffiapi_bridge`.  The native bridge is an explicit foreign-contract premise; it is not silently identified with CakeML's basis FFI implementation.
