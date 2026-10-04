# 14 — Milestone 04 — Make Self-Reflection and the Complete Proof State Survive into LambdaBox

> **UNIFIED SEQUENCE STEP 14 OF 22 — METAROCQ SOURCE/SPECIFICATION -> MACHINE REFINEMENT.**  
> Reused from `docs/selfhost-bootstrap/04-self-reflection-and-lambdabox-retention.md` on `docs/selfhost-bootstrap-04-runtime-audit`. The original manual remains preserved. This unified copy is downstream of the verified Peregrine foundation from Steps 01–10.

## Objective

Turn the current self-reflective MetaRocq state into **ordinary executable data** that survives MetaRocq's verified erasure and remains reachable from the LambdaBox entrypoint.

This milestone MUST NOT depend on raw proof terms remaining in `Prop` after erasure. MetaRocq erasure intentionally removes types and proofs. Therefore, before erasure, reify every proof/specification that must be replayed as explicit syntax/data in `Type`.

The intended invariant is:

```text
MetaRocq source declaration/proof
          |
          | recursive quotation
          v
explicit PCUIC syntax + statement + proof-body data
          |
          | retained from an executable root
          v
LambdaBox value
          |
          v
same complete replay corpus is still observable
```

## 1. Reuse the existing retained certificate representation

The reconciled branch already defines a proof-bearing record in:

```text
metatheory/original-selfhost/PCUICCertificateIR.v
```

and retains:

```text
original_pcuic_certificate_corpus
original_pcuic_assumption_ledger
original_pcuic_replay_jobs
```

through:

```text
retained_pcuic_certificates
retained_pcuic_assumptions
retained_certificate_replay_jobs
```

Do NOT replace these with a parallel representation.

Extend the existing representation until each retained proof entry is sufficient to replay/check the exact source theorem without consulting a `.vo` file.

At minimum each retained entry needs:

```text
kernel name
quoted statement
quoted proof/body
required global-environment identity
universe information or environment reference
dependency identities
source declaration digest
```

## 2. Separate logical proof from retained executable certificate data

The source proof itself may live in `Prop`; the replay certificate MUST live in ordinary computational data.

Use a pattern equivalent to:

```coq
Record retained_certificate : Type := {
  cert_name : kername;
  cert_statement : Ast.term;
  cert_proof : Ast.term;
  cert_environment_id : bytestring;
}.
```

The exact types should reuse MetaRocq's existing PCUIC syntax.

Do not serialize the proof to an opaque string before the semantic boundary. Keep a structured PCUIC AST for the checker/replay logic. Serialization is only for audit/export.

## 3. Make the proof corpus reachable from one final entrypoint

The extracted program MUST have one root whose normal evaluation can reach:

- source/proof corpus;
- assumption ledger;
- replay jobs;
- self-CI state;
- exact source snapshot identity;
- later Peregrine/CakeML/HOL4 evidence handles.

The existing:

```text
ReconciledSelfHostEntrypoint.v
ExtractReconciledSelfHost.v
```

are the correct place to continue.

Do not create a second extraction root for the final pipeline. A single root makes it possible to prove that the exact executable state carries the exact corpus used by the final E2E theorem.

## 4. Add completeness-preserving runtime queries

Add commands/responses that permit the extracted LambdaBox program to expose deterministic views of:

```text
certificate count
ordered certificate identities
ordered assumption identities
ordered replay-job identities
source snapshot digest
proof-corpus digest
assumption-ledger digest
```

These are audit observables. They are NOT substitutes for the semantic proof.

The purpose is to detect accidental erasure/dead-code elimination and to bind the later machine execution back to the exact retained state.

## 5. Make the reflective system quote its own replay machinery

The self-reflective source snapshot MUST include the modules/functions implementing:

- proof-corpus construction;
- assumption-ledger construction;
- replay-job construction;
- self-CI interpretation;
- recursive identity evaluation;
- the final retained entrypoint.

Otherwise the system would replay its older metatheory but omit the new self-verification mechanism itself.

Add a fail-closed predicate equivalent to:

```text
reflection_mechanism_in_complete_corpus = true
```

but prove it from membership/identity of the exact declarations rather than setting a Boolean manually.

## 6. Generate the LambdaBox artifact from the final retained root

Use the existing extraction installation and root.

From the repository root:

```bash
eval "$(opam env --switch .aegis/opam --set-switch)"

Q='-Q metatheory/original-selfhost MetaRocqRs.OriginalSelfHost'

rocq compile $Q metatheory/original-selfhost/ReconciledSelfHostEntrypoint.v
rocq compile $Q metatheory/original-selfhost/ExtractReconciledSelfHost.v

test -s generated/original-selfhost/reconciled-selfhost.ast
sha256sum generated/original-selfhost/reconciled-selfhost.ast \
  | tee generated/e2e/lambdabox.sha256
```

Treat the `.ast` file as the exact LambdaBox/Peregrine input artifact.

Do not regenerate it with a different checkout for the publication run.

## 7. Add a source-to-LambdaBox retention theorem

The important theorem is not merely:

```text
erasure produced some LambdaBox term
```

It must establish that the relevant observables of the retained proof state are preserved.

Define an observation function over the source-side retained state and another over the LambdaBox-side execution result.

Prove a relation equivalent to:

```text
source_retained_observation source_state
=
lambdabox_retained_observation
  (erase/extract source_state)
```

For the E2E goal, include at least:

- exact certificate identities/order;
- exact assumption identities/order;
- exact replay-job identities/order;
- the source/proof corpus digests if they are part of the runtime state;
- self-CI/replay command availability.

## 8. Do not confuse “proof erasure correctness” with “proof replay retention”

MetaRocq's verified erasure intentionally maps proofs/types to erased representations such as `tBox`.

That is correct behavior for ordinary extraction.

Your additive architecture is different:

```text
logical proof in Prop
      |
      | quotation before erasure
      v
explicit proof AST in Type
      |
      | ordinary computational erasure
      v
retained proof AST in LambdaBox
```

This transformation MUST be visible in the source snapshot and covered by the final theorem chain.

Do not modify MetaRocq erasure to “preserve Prop proof terms” unless a specific theorem requires it. Prefer reification into executable data because it composes with the existing verified erasure architecture.

## 9. Regression tests

Add tests that deliberately break retention and MUST fail.

Examples:

1. remove `retained_pcuic_certificates` from the extraction root;
2. omit one source certificate;
3. reorder certificates while leaving a stale digest;
4. drop an assumption;
5. remove the self-reflection command from the entrypoint.

The test harness must detect all five.

## Completion gate

Milestone 04 is complete only when:

- the exact proof/specification state exists as structured executable PCUIC data;
- every in-scope certificate and assumption is reachable from the one extraction root;
- the reflection/replay implementation itself is in the reflected source scope;
- LambdaBox generation succeeds from that root;
- source-side and LambdaBox-side retained observations are related by a proved theorem;
- intentionally removing one retained item makes the pipeline fail.

## References

### MetaRocq

- MetaRocq overview; recursive quotation, SafeChecker, erasure, quotation, and self-erasure examples: https://github.com/MetaRocq/metarocq/blob/9.1/README.md
- MetaRocq installation/package description; quotation package includes quotation of terms and typing derivations: https://github.com/MetaRocq/metarocq/blob/9.1/INSTALL.md
- MetaRocq erasure theories: https://github.com/MetaRocq/metarocq/tree/9.1/erasure/theories
- MetaRocq self-erasure test: https://github.com/MetaRocq/metarocq/blob/9.1/test-suite/self_erasure.v

### CakeML

- CakeML source repository: https://github.com/CakeML/cakeml
- Verified CakeML Compiler Backend: https://cakeml.org/jfp19.pdf
- In-logic compilation example used later in the chain: https://github.com/CakeML/cakeml/blob/master/examples/compilation/x64/helloCompileScript.sml

### HOL4

- HOL4 official documentation: https://hol-theorem-prover.org/docs/trindemossen-2/
- HOL4 logic description: https://hol-theorem-prover.org/docs/trindemossen-2/Description/
- HOL4 developer/kernel documentation: https://hol-theorem-prover.org/docs/trindemossen-2/Developers/
