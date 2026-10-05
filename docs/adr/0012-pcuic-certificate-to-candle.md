# ADR 0012: Preserve PCUIC proof certificates and verify a small checker bridge

Status: experimental, fail closed.

## Decision

Do not translate every dependent MetaRocq proof term directly into a long
sequence of primitive HOL proof commands.

Instead:

1. retain every proof-bearing constant from the baked PCUIC snapshot as the
   exact tuple `(kername, PCUIC statement, PCUIC proof term)`;
2. retain every body-less source constant in a separate assumption ledger;
3. use MetaRocq's existing proof-producing safe checker as the certificate
   engine;
4. deep-embed PCUIC syntax, environments, universes and typing/reduction
   relations into HOL data/relations;
5. prove once that the HOL encoding of the checker is faithful and sound;
6. replay the complete certificate corpus computationally;
7. emit OpenTheory theorems only from those checked derivations;
8. replay the resulting articles in Candle's verified OpenTheory machine image.

This changes the cross-logic burden from translating thousands of dependent
proof derivations to proving a small checker/encoding bridge and replaying a
large amount of data.

## Exact safe-checker source

- repository: `MetaRocq/metarocq`
- revision: `7197056adbb9c15288b4c8d43407bf25786f723e`
- file: `safechecker/theories/PCUICSafeChecker.v`
- Git blob: `8691e1f5d25b8001c7d497f0e67a71c888c6b0db`
- judgement API: `PCUICSafeChecker.check_wf_judgement`

A successful source result carries the PCUIC typing judgement of the proof term
at the requested statement for every related global environment. The API also
keeps normalization and environment assumptions visible.

## Assumptions are not proofs

A source constant whose `cst_body = None` is not inserted into the certificate
corpus. It is inserted into an explicit assumption ledger.

The Candle/OpenTheory target must either discharge that assumption independently
or expose it in the final trusted-theory-base report. No source parameter is
silently converted into a proved HOL theorem.

## HOL prelude boundary

The verified OpenTheory reader supports definitional extension commands such as
`defineConst` and `defineTypeOp` as well as primitive proof commands. The PCUIC
object-language representation will use definitional extensions, not arbitrary
axioms.

The prelude is incomplete until it proves constructor distinction/injectivity,
encoding round-trip, checker execution faithfulness, and checker soundness.

OpenTheory `axiom` is not an implementation mechanism for these obligations.

## Remaining blocker

This layer creates the exact certificate corpus and checker bridge contract,
but publication remains false until the HOL datatype/checker soundness layer is
actually proved.
