# ADR 0013: Checked EAst -> CakeML candidate slice

Status: implemented as a fail-closed executable checker; full semantic
preservation remains open.

## Purpose

PR #22 embedded the pure `Compile.compile_program` function but correctly did
not claim that the function is semantics preserving. This layer adds the first
proved slice around that compiler rather than broadening the architecture.

## EAst source gate

`EAstSupportedFragment.v` mirrors the actual failure behavior of the pinned
compiler.

A program is rejected when it contains a form that the compiler maps to a
backend exception, or when compilation would otherwise rely on a default:

- de Bruijn relatives after the named transformation;
- evars;
- projections;
- cofixpoints;
- primitive values;
- lazy/force;
- boxes;
- missing constants;
- missing constructors;
- out-of-range constructor indices;
- case branch/count mismatch;
- out-of-range fixpoint indices;
- non-lambda fixpoint bodies.

The global-environment checker follows the same tail-environment order used by
`Compile.compile_env`.

## Generated CakeML gate

`CakeMLNoRaise.v` recursively checks the complete generated environment and
main expression. Any `Raise` node anywhere in the candidate CakeML AST blocks
acceptance.

This is intentionally stricter than distinguishing backend-generated raises
from source-language exceptions: the current EAst source language has no
exception constructor that the compiler is required to preserve.

## Proved postconditions

`CheckedCandidateCakeML.v` proves two facts about every successful result:

1. there exists an EAst program produced by the exact pinned
   `PAst_to_EAst` conversion such that the EAst supported-fragment checker
   returned `true`, and the returned AST is exactly
   `Compile.compile_program ep`;
2. the complete returned CakeML AST satisfies the recursive no-`Raise`
   checker.

These theorems do **not** substitute for the missing semantic-preservation
proof. They establish that the runtime gate itself cannot report success for a
candidate that bypassed either syntactic check.

## Remaining semantic theorem

The next proof obligation remains:

```
EAst evaluation of a checked program
  -> CakeML evaluation of Compile.compile_program
  -> corresponding observable result
```

That theorem can now assume the explicit `east_program_supported = true`
precondition rather than trying to cover unsupported EAst forms.
