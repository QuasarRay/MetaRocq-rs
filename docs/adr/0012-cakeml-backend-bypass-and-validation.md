# ADR 0012: Bypass the unproved CakeML wrapper and validate the pure compiler

Status: experimental and fail closed.

## Exact dependency

Pinned Peregrine depends on `rocq-cakeml-extraction = 0.1.0`.
The exact v0.1.0 tag resolves to:

`cc20d1a2986bd2fec7c6eb0864c8c9a806188b58`.

This removes ambiguity about which CakeML extraction implementation is in the
self-host trust analysis.

## Trust ledger

The trusted path does not use any of the following as proof evidence:

1. Peregrine wrapper `cakeml_pipeline` final `Admitted` obligation.
2. Peregrine wrapper `trust_coq_kernel`.
3. Backend `assume_can_be_extracted`.
4. Backend `compile_to_malfunction` admitted preservation.
5. The same transform's vacuous `post=True`, target-evaluation `True`,
   `obseq=True` contract.
6. Backend `trust_coq_kernel`.
7. The absence of an EAst -> CakeML `compile_program` semantic-preservation
   theorem.

The fourth item could be filled with a trivial witness because the transform
contract is vacuous. That would not establish compiler correctness and is
therefore explicitly rejected as a zero-trust repair.

## Candidate producer path

The extracted MetaRocq image now has an executable path:

```
Peregrine parse / validate / sanitize / transform
  -> PAst_to_EAst
  -> CakeML.Backend.Compile.compile_program
  -> CakeML AST
```

`PAst_to_EAst` is the exact pinned Peregrine implementation at blob
`45306f7c193eaa4e47cfe1b7b0f63e211de948b8`.

`compile_program` is the exact 0.1.0 pure syntax compiler at blob
`b22338bc3113a972bcf793f79be7887bc59153e8`.

No `trust_coq_kernel` or admitted Transform wrapper is needed merely to
compute this candidate CakeML AST.

## Certification remains mandatory

Computation is not certification. Candidate output is publishable only after a
retained certificate binds:

- lambda-box input;
- prepared PAst;
- EAst;
- generated CakeML AST;
- recomputation through the embedded pure compiler;
- supported-fragment proof;
- real EAst -> CakeML semantic preservation;
- Candle `safe_dec` compatibility;
- absence of forbidden backend assumptions;
- independent PCUIC and Candle checks.

The current certificate is deliberately unresolved, so the gateway remains
blocked.

## Reuse of backend proofs

The exact 0.1.0 package ships CakeML big-step/small-step equivalence and helper
proofs. They are reusable supporting lemmas, but they do not prove the
EAst -> CakeML compiler correct. Future proof development should reuse them
instead of recreating CakeML operational-semantics infrastructure.
