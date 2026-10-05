# 05 — Use a PREBUILT Peregrine Executable to Generate the CakeML Candidate from the Self-Hosted Peregrine LambdaBox

> **UNIFIED SEQUENCE STEP 05 OF 22 — PEREGRINE TRUST FOUNDATION.**  
> Reused from `docs/peregrine-selfhost-certificate/04-prebuilt-peregrine-to-cakeml.md` on `docs/peregrine-selfhost-03-independent-replay`. The original manual remains preserved. This copy reorders and connects the existing instructions into the unified Peregrine -> MetaRocq E2E sequence. Execute this file completely before continuing to the next numbered file.

## Objective

Take the exact LambdaBox artifact produced in Milestone 03:

```text
generated/peregrine-selfhost/peregrine-selfhost.ast
```

and use a PRE-EXISTING Peregrine executable to generate the exact CakeML candidate program.

This stage is intentionally split into:

```text
CANDIDATE GENERATION
        !=
PROOF OF TRANSLATION CORRECTNESS
```

The prebuilt Peregrine executable MAY generate the candidate.

It MUST NOT be treated as final proof evidence merely because it returned success.

## REUSE

Reuse:

```text
docs/selfhost-bootstrap/06-peregrine-cakeml-backend.md
```

but apply the stronger current source audit:

- in-tree CakeML backend has an `Admitted` obligation;
- in-tree wrapper has `trust_coq_kernel`;
- separate official CakeML-backend proof repository is incomplete at the audited refs.

Therefore the candidate and proof paths MUST be recorded separately.

## 1. Freeze the Prebuilt Peregrine Executable

Use the Peregrine executable from the frozen bootstrap switch when possible:

```bash
export OPAMROOT="$PWD/.aegis/opam-root"
eval "$(opam env --switch .aegis/opam --set-switch)"

command -v peregrine
peregrine --help
```

Record:

```bash
{
  command -v peregrine
  peregrine --help
  opam list --switch .aegis/opam | grep peregrine
} > generated/e2e/peregrine-prebuilt-seed.txt
```

Also record the executable digest:

```bash
PEREGRINE_BIN="$(command -v peregrine)"

sha256sum "$PEREGRINE_BIN" \
  > generated/e2e/peregrine-prebuilt-seed.sha256
```

Do NOT rebuild Peregrine between producing the LambdaBox input and generating the CakeML candidate unless the new binary gets a new provenance identity.

## 2. Verify the Input Artifact Before Candidate Generation

Run:

```bash
sha256sum -c \
  generated/e2e/peregrine-selfhost-lambdabox.sha256
```

Also verify:

```text
source snapshot digest
certificate corpus digest
assumption ledger digest
LambdaBox digest
```

against the bootstrap manifest from Milestone 03.

A stale `.ast` is not allowed downstream.

## 3. Generate the CakeML Candidate with the Official Peregrine CLI

The official Peregrine backend documentation says:

```text
CakeML backend
input: untyped LambdaBox
output: serialized CakeML AST
CLI writes: .cml
```

Use:

```bash
mkdir -p generated/peregrine-selfhost/cakeml

peregrine cakeml \
  generated/peregrine-selfhost/peregrine-selfhost.ast \
  -o generated/peregrine-selfhost/cakeml/peregrine-selfhost.cml
```

Then:

```bash
test -s \
  generated/peregrine-selfhost/cakeml/peregrine-selfhost.cml

sha256sum \
  generated/peregrine-selfhost/cakeml/peregrine-selfhost.cml \
  > generated/e2e/peregrine-selfhost-cakeml-candidate.sha256
```

If the exact CLI syntax differs at your pinned executable, derive it from:

```bash
peregrine --help
peregrine cakeml --help
```

Do NOT invent unsupported flags.

## 4. Preserve the Official CakeML Compiler Flags as Part of the Candidate Contract

The official Peregrine backend documentation states that the serialized `.cml` AST is intended for CakeML with:

```text
--sexp=true
--exclude_prelude=true
--skip_type_inference=true
```

Record these exact flags in:

```text
generated/e2e/peregrine-cakeml-candidate.json
```

Conceptual record:

```json
{
  "input_lambdabox_digest": "...",
  "peregrine_executable_digest": "...",
  "peregrine_source_commit": "...",
  "backend": "cakeml",
  "output_cml_digest": "...",
  "cakeml_parse_flags": [
    "--sexp=true",
    "--exclude_prelude=true",
    "--skip_type_inference=true"
  ]
}
```

These flags are part of the exact artifact identity.

## 5. Treat the Generated `.cml` as a Candidate, NOT a Certified Program Yet

This is the mandatory trust split:

```text
prebuilt Peregrine executable
  -> candidate .cml
  -> candidate digest
```

At this point you MAY claim:

```text
"Peregrine generated this exact CakeML candidate."
```

You MUST NOT yet claim:

```text
"This CakeML program semantically refines the LambdaBox program."
```

That claim belongs to Milestone 05.

## 6. Why the Ordinary In-Tree CakeML Backend Is Not Sufficient Proof Evidence

At the audited Peregrine commit:

```text
d768b83ffa7dab35b8d72241f0570b5bb6aedae9
```

the in-tree:

```text
theories/backends/CakeMLBackend.v
```

contains both:

```coq
Final Obligation.
Admitted.
```

and:

```coq
Axiom trust_coq_kernel : forall p, pre cakeml_pipeline p.
```

Therefore:

```text
the output is useful
the output is NOT independently certified by that wrapper
```

Do NOT convert those assumptions into a JSON `verified=true` field.

## 7. Parse the Candidate into the Exact CakeML AST Used by the Proof Stage

The candidate boundary is only acceptable if the proof stage consumes the exact same semantic program.

You must choose ONE of these paths.

### Preferred — proved serializer/deserializer round trip

Use the CakeML AST serializer/deserializer formalization from the separate Peregrine CakeML backend and prove:

```text
deserialize (serialize K) = K
```

for the exact generated program `K`.

Then prove:

```text
deserialize candidate_cml = exact_proved_cakeml_ast
```

### Alternative — bypass text for the proof path

Run the proof-producing transformation inside Rocq/MetaRocq and expose the internal CakeML AST directly.

Then compare the serialized candidate to a serialization of that exact AST.

This gives:

```text
proof path AST K
        |
        | proved serializer
        v
candidate bytes
```

Do NOT use:

```text
candidate bytes
 -> unverified parser
 -> AST K'
 -> assume K' = K
```

## 8. Enforce Candidate/Proof Identity

Generate a theorem or mechanically checked equality binding:

```text
candidate_cml_bytes
        =
serialize exact_proved_cakeml_ast
```

or:

```text
deserialize candidate_cml_bytes
        =
exact_proved_cakeml_ast
```

The candidate is allowed to proceed to HOL4 only if this identity is closed.

## 9. Record Every Transformation Configuration

Peregrine configuration affects semantics and target output.

Record:

```text
backend config
optimization passes
unsafe transforms
constructor remapping
name sanitization
typed/untyped mode
serialization mode
```

The exact config must be part of the theorem statement or exact input identity later.

Do NOT certify one configuration and execute another.

## 10. Forbid Unsafe Transformation Drift

If a configuration enables a transform that is not covered by the proof-producing pipeline:

```text
BLOCK
```

Do NOT “temporarily” enable an optimization because it produces smaller CakeML.

The publication program must be exactly the proved program.

## 11. Add Candidate Mutation Tests

The proof identity stage MUST reject:

- one changed byte in `.cml`;
- one changed LambdaBox constructor;
- different prebuilt Peregrine executable;
- changed backend config;
- changed serialization flags;
- changed name sanitization;
- a candidate generated from a different source snapshot;
- a stale candidate after proof-corpus changes.

## Completion Gate

This milestone is complete only when:

- the exact prebuilt Peregrine executable is identified;
- the exact selfhost LambdaBox input is verified;
- the prebuilt executable generates one exact CakeML candidate;
- official serialized-AST compiler flags are recorded;
- the candidate is explicitly classified as untrusted output until Milestone 05;
- exact candidate bytes are bound to the exact proof-stage CakeML AST;
- unsafe/unproved transformations cannot silently enter the publication path.

## References

### MetaRocq

- MetaRocq verified erasure architecture underlying Peregrine's LambdaBox input: https://github.com/MetaRocq/metarocq/blob/9.1/README.md
- MetaRocq erasure theories: https://github.com/MetaRocq/metarocq/tree/9.1/erasure/theories

### Peregrine

- Official backend documentation, including CakeML serialized AST output and CakeML flags: https://github.com/peregrine-project/peregrine-tool/blob/d768b83ffa7dab35b8d72241f0570b5bb6aedae9/doc/backends.md
- Official command-line documentation: https://github.com/peregrine-project/peregrine-tool/blob/master/doc/cmds.md
- In-tree CakeML backend source: https://github.com/peregrine-project/peregrine-tool/blob/d768b83ffa7dab35b8d72241f0570b5bb6aedae9/theories/backends/CakeMLBackend.v
- Separate official CakeML backend repository: https://github.com/peregrine-project/cakeml-backend

### CakeML

- CakeML source tree corresponding to the Peregrine backend model: https://github.com/CakeML/cakeml/tree/e1650fc504837c0fbd3931cc5066914ffdc9d877
- CakeML in-logic x64 compiler wrapper: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/cv_translator/eval_cake_compile_x64Lib.sml

### HOL4

- HOL4 official repository: https://github.com/HOL-Theorem-Prover/HOL
- HOL4 theorem/article export will later transport the theorem for independent replay: https://github.com/HOL-Theorem-Prover/HOL/blob/40dd5b03de658f4bd9e3f4225fb0f1602ac90467/src/opentheory/postbool/OpenTheoryIO.sig
