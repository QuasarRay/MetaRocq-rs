# Milestone 03 — Capture the Exact MetaRocq Source State and Complete Proof Corpus

## Objective

Materialize a self-contained, content-addressed snapshot of the exact MetaRocq source state that will be certified E2E.

This milestone answers:

> What exact source definitions, proof-bearing declarations, assumptions, environments, universes, and entrypoints are being claimed by the final theorem?

Do not proceed to erasure until the snapshot is complete and auditable.

## 1. Reuse the existing snapshot machinery

The current reconciled branch already contains:

```text
metatheory/original-selfhost/
  PCUICModuleManifest.v
  SelfSnapshot.v
  MaterializeSnapshot.v
  PCUICCertificateIR.v
  SafeCheckerContract.v
  ReconciledSelfHostEntrypoint.v
```

Extend these files rather than creating a parallel snapshot format.

The existing `PCUICCertificateIR.v` separates:

- proof-bearing constants into certificate records;
- body-less declarations into a source-assumption ledger.

Preserve that distinction.

## 2. Define the exact in-scope module set

Create or extend the module manifest so that the snapshot includes every MetaRocq component needed by the final executable and its metatheory.

At minimum review these upstream roots:

```text
common/
utils/
template-rocq/
pcuic/
safechecker/
erasure/
safechecker-plugin/
erasure-plugin/
quotation/
```

Also include the exact local self-reflection/bootstrap modules that become part of the executable architecture.

Do not rely on “all imported modules” as an implicit definition. Materialize the set of roots and the transitive closure that was actually quoted.

## 3. Quote the environment recursively

Use MetaRocq's recursive quotation facilities to materialize the exact declarations consumed by the selfhost entrypoint.

The snapshot MUST preserve at least:

```text
kernel name
declaration kind
universe context
type / statement
optional body / proof term
dependencies
source module identity
```

Prefer kernel identities over source-text names where possible.

For each snapshot run, write deterministic machine-readable output under:

```text
generated/original-selfhost/snapshot/
```

Recommended files:

```text
source-roots.json
declarations.json
proof-corpus.json
assumptions.json
dependency-edges.json
snapshot-manifest.json
```

The existing Rocq data structures should remain the source of truth; JSON is only an audit/export view.

## 4. Prove proof-corpus completeness inside the MetaRocq development

Add a theorem that ties the retained certificate corpus to the exact snapshot.

Do not accept only:

```text
length certificate_corpus = N
```

because two different corpora can have the same length.

Require a property equivalent to:

```text
forall declaration,
  In declaration exact_snapshot ->
  proof_bearing declaration ->
  exists certificate,
    In certificate complete_certificate_corpus /\
    certificate_name = declaration_name /\
    certificate_statement = declaration_type /\
    certificate_proof = declaration_body
```

Also prove the reverse direction:

```text
forall certificate,
  In certificate complete_certificate_corpus ->
  exists declaration,
    In declaration exact_snapshot /\
    certificate exactly represents declaration
```

The final HOL4 build will later independently check the generated proof/replay path. This Rocq-side completeness theorem is still useful because it exposes omissions early and gives the reflective program a precise completeness specification.

## 5. Preserve the complete assumption ledger

For each body-less declaration or external premise, retain:

```text
kernel name
statement
origin
reason it is body-less
whether allowed by policy
whether expected to be discharged later
```

Never merge assumptions into the ordinary certificate corpus.

Create a fail-closed policy:

```text
unknown assumption              -> reject
new assumption                  -> reject until reviewed
Admitted/admit                  -> reject
untracked generated Parameter   -> reject
normalization premise           -> retain explicitly
hardware/FFI premise            -> retain explicitly
```

## 6. Hash source identity and semantic identity separately

Store both:

1. source-file hashes;
2. quoted declaration/proof hashes.

Reason: source text can contain comments/formatting that do not change the quoted program, while different source-generation paths can produce semantically distinct environments.

Recommended manifest fields:

```json
{
  "repository_commit": "...",
  "source_tree_digest": "...",
  "quoted_environment_digest": "...",
  "certificate_corpus_digest": "...",
  "assumption_ledger_digest": "...",
  "entrypoint_kernel_name": "..."
}
```

Do not use these hashes as proof of semantic correctness. They only bind later theorems to exact artifacts.

## 7. Make the snapshot executable data

The self-reflective executable must retain the corpus after proof erasure.

The current branch intentionally exposes:

```text
retained_pcuic_certificates
retained_pcuic_assumptions
retained_certificate_replay_jobs
```

through the extraction root.

Keep them reachable from the final entrypoint. If an optimizer removes them as dead data, the recursive self-replay requirement has failed.

Add a regression theorem/test that the retained runtime response can enumerate:

- every certificate;
- every assumption;
- every replay job.

## 8. Detect omissions before extraction

Add a local command such as:

```bash
./tools/selfhost-e2e.sh snapshot
```

It should:

1. rebuild the exact snapshot;
2. regenerate the audit views;
3. compare source roots with the scope manifest;
4. compare proof-bearing declarations with the certificate corpus;
5. compare body-less declarations with the assumption ledger;
6. reject duplicate kernel names;
7. reject missing bodies for declarations expected to contain proofs;
8. produce deterministic hashes.

The command MUST fail if any in-scope proof-bearing source declaration is omitted.

## 9. Record an immutable checkpoint

After the first complete snapshot:

```bash
sha256sum \
  generated/original-selfhost/snapshot/source-roots.json \
  generated/original-selfhost/snapshot/declarations.json \
  generated/original-selfhost/snapshot/proof-corpus.json \
  generated/original-selfhost/snapshot/assumptions.json \
  generated/original-selfhost/snapshot/snapshot-manifest.json \
  > generated/e2e/snapshot.sha256
```

Commit only source specifications and deterministic generation code unless repository policy explicitly allows generated evidence. Preserve generated evidence as local release artifacts.

## Completion gate

Milestone 03 is complete only when:

- the exact source roots are explicit;
- recursive quotation produces a deterministic snapshot;
- every in-scope proof-bearing declaration maps exactly to one retained certificate;
- every body-less declaration maps to the assumption ledger;
- no source proof is silently erased from the retained executable state;
- the snapshot and corpus identities are content-addressed;
- the snapshot command fails closed on omissions or unexpected assumptions.

## References

### MetaRocq

- MetaRocq overview of Template-Rocq recursive quotation, PCUIC, SafeChecker, erasure, and self-erasure examples: https://github.com/MetaRocq/metarocq/blob/9.1/README.md
- MetaRocq quotation package, including quotation of terms and typing derivations: https://github.com/MetaRocq/metarocq/blob/9.1/INSTALL.md
- PCUIC documentation root: https://github.com/MetaRocq/metarocq/tree/9.1/pcuic/theories
- Quotation documentation root: https://github.com/MetaRocq/metarocq/tree/9.1/quotation/theories

### CakeML

- CakeML repository: https://github.com/CakeML/cakeml
- CakeML verified compiler backend and the need to bind semantics to concrete compiled programs: https://cakeml.org/jfp19.pdf
- CakeML concrete in-logic compilation example: https://github.com/CakeML/cakeml/blob/master/examples/compilation/x64/helloCompileScript.sml

### HOL4

- HOL4 official documentation: https://hol-theorem-prover.org/docs/trindemossen-2/
- HOL4 logic description: https://hol-theorem-prover.org/docs/trindemossen-2/Description/
- HOL4 developer/kernel documentation: https://hol-theorem-prover.org/docs/trindemossen-2/Developers/
