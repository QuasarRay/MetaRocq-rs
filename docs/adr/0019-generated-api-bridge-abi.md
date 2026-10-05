# ADR 0019: Bounded API-bridge ABI and polymorphic native handles

## Status

Proof-layer decision. Stacks on the generated wrapper PR.

## Problem

CakeML FFI byte arrays have fixed length. A wrapper cannot safely assume that a
serialized HOL theorem, term, search tree, closure, or arbitrary API result fits
into the request buffer. CakeML's semantics additionally proves that successful
FFI calls preserve byte-array length.

## Decision

Every generated call uses a canonical frame of at least 16 bytes.

- byte 0: status;
- remaining header bytes: protocol/version and opaque result-handle metadata;
- remaining bytes: operation-specific input payload;
- a successful FFI transition preserves the complete frame length;
- large/complex results remain in the native HOL4/PolyML process and return an
  opaque handle in the fixed header;
- malformed or undersized frames are rejected by CakeML before the FFI call.

The exact header field encoding is versioned machine-readable metadata; no proof
depends on Poly/ML pointer layout.

## Polymorphic Standard ML APIs

The pinned HOL4 source already contains `UniversalType` and Poly/ML
`Universal.tag` usage. Native generated adapters may therefore keep
polymorphic values in a type-tagged native registry and expose only opaque
handles. This is an implementation strategy on the trusted foreign side, not a
CakeML runtime representation.

## Proof boundary

The CakeML/HOL4 theorem assumes a foreign transition of the form

`u "api_bridge" operation_id payload state = FFIreturn payload' state'`

with equal input/output lengths and exact operation-id semantics. The theorem
then proves that the generated CakeML wrapper:

1. never invokes the FFI for an undersized frame;
2. invokes exactly `api_bridge` for a well-formed frame;
3. supplies the exact generated operation id;
4. returns the bridge-mutated frame without reinterpreting native objects.

The implementation of HOL4, Z3_TAC, TacticToe and the native bridge remains an
explicit foreign contract. A later Pancake/native-verification layer can
discharge the bridge implementation assumption without changing this API.
