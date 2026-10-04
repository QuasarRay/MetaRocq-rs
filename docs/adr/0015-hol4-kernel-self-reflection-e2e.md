# ADR 0015: HOL4 kernel self-reflection and exact CakeML machine refinement

Status: implemented as a fail-closed stacked architecture; end-to-end theorem completion remains blocked.

## Decision

The active Selfhost 9 acceptance path no longer uses Candle as its proof kernel.

PR #24 and all earlier Candle modules are retained unchanged as audit history. This branch adds a new extraction root that reaches only the HOL4-specific acceptance modules and the already-proved checked Peregrine/CakeML candidate path.

The target chain is:

```
pinned MetaRocq source snapshot
  <=> recursively quoted PCUIC/self-reflection data
  <=> exact retained LambdaBox program
   -> embedded Peregrine parse/validate/transform
   -> PAst_to_EAst
   -> checked supported EAst fragment
   -> CakeML.Backend.Compile.compile_program
   -> exact CakeML program definition in HOL4
   -> exact source-semantics theorem
   -> eval_cake_compile_x64
   -> compile_correct / x64_compile_correct
   -> concrete machine bytes + installed image
   -> HOL4 check_thm
   -> installed-image self replay and identity
```

## Why the CakeML compiler theorem is not enough by itself

CakeML's compiler is verified in HOL4, but a generic compiler-correctness theorem does not identify this branch's generated MetaRocq program or its emitted bytes.

The concrete CakeML pattern is to evaluate compilation inside HOL4 for an exact program definition and then compose that compilation theorem with a source-level semantics theorem and compiler correctness. The existing `helloCompileScript.sml` / `helloProofScript.sml` pair is retained only as the reference composition pattern.

Selfhost 9 therefore requires all of the following before publication:

1. exact generated program identity;
2. exact in-logic compilation theorem;
3. exact source-semantics theorem;
4. instantiated compiler and x64 machine obligations;
5. concrete byte/image identity;
6. HOL4 `check_thm` acceptance.

No workflow exit status substitutes for these theorem objects.

## Peregrine integration

The branch reuses the real pinned Peregrine frontend in-process and the exact pinned CakeML AST compiler.

It deliberately does not trust Peregrine's current CakeML backend wrapper because the pinned implementation contains an admitted pipeline obligation and `trust_coq_kernel`; the pinned CakeML backend also contains `assume_can_be_extracted` and an admitted/vacuous final preservation boundary.

The active path remains:

```
prepare_cakeml
-> PAst_to_EAst
-> east_program_supported
-> CakeML.Backend.Compile.compile_program
-> candidate_cakeml_no_raise
```

Existing Selfhost 7 theorems prove that every successful result on this path is the exact pure compiler output for a supported EAst witness and contains no generated `Raise`.

## HOL4 kernel boundary

The pinned HOL4 source revision is part of the contract. A small qualification theory is checked directly by that kernel, but qualification is not the MetaRocq correctness proof.

The final proof gate additionally requires:

- the exact MetaRocq theorem object to pass `check_thm`;
- expected statement identity;
- expected source-assumption ledger;
- no unexpected HOL4 oracle;
- no unexpected HOL4 axiom.

## Source <=> LambdaBox

Extraction itself is not treated as the equivalence theorem.

The source/LambdaBox gate requires a concrete binding from the pinned source snapshot and complete recursive quotation to the exact retained LambdaBox bytes, plus an instantiated MetaRocq erasure/semantic-preservation theorem and a round-trip/identity binding. Until those are supplied, the gate is false.

## Preservation rule

No Candle-era branch, theorem ledger, workflow, or evidence is deleted or rewritten to manufacture the new architecture.

Selfhost 9 is stacked directly on the exact PR #24 head. The legacy line remains independently inspectable, while the new `HOL4SelfHostEntrypoint` is the active Candle-free extraction and acceptance root for this experiment.

## Current blockers

The branch intentionally remains non-publishable until the following genuine proof work exists:

- faithful PCUIC-as-HOL4 representation and checker-soundness bridge;
- complete source <=> LambdaBox semantic refinement;
- EAst -> CakeML observational preservation for the checked fragment;
- exact generated CakeML HOL4 program definition and source semantics theorem;
- exact x64 byte and installed-image binding;
- recursive installed-image self-replay.

These are theorem obligations, not documentation tasks.
