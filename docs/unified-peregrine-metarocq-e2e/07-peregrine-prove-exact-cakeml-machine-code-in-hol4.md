# 07 — Make CakeML/HOL4 Produce the Exact Machine-Code Refinement Theorem for the Self-Hosted Peregrine Program

> **UNIFIED SEQUENCE STEP 07 OF 22 — PEREGRINE TRUST FOUNDATION.**  
> Reused from `docs/peregrine-selfhost-certificate/06-cakeml-hol4-exact-machine-attestation.md` on `docs/peregrine-selfhost-03-independent-replay`. The original manual remains preserved. This copy reorders and connects the existing instructions into the unified Peregrine -> MetaRocq E2E sequence. Execute this file completely before continuing to the next numbered file.

## Objective

Take the exact proved CakeML AST:

```text
K
```

from Milestone 05 and compile it INSIDE HOL4 using CakeML's theorem-producing compiler evaluation.

Produce a HOL4 theorem whose exact machine-code object refines the complete self-hosted Peregrine specification:

```text
Peregrine source
+ complete Peregrine proof replay corpus
+ assumptions
+ exact LambdaBox
+ exact CakeML AST
        |
        | HOL4 + CakeML verified compiler
        v
exact machine code M

HOL4 proves:
  MachineSemantics(M)
    refines
  PeregrineSelfHostSpec(...)
```

Do NOT trust a standalone CakeML compiler executable as the source of this theorem.

## REUSE

Reuse literally:

```text
docs/selfhost-bootstrap/07-hol4-independent-replay-kernel.md
docs/selfhost-bootstrap/08-cakeml-in-logic-machine-compilation.md
docs/selfhost-bootstrap/09-unified-e2e-hol4-theorem.md
```

This file adds only the exact Peregrine-specific theorem composition and proof-artifact outputs needed for the embedded-certificate step.

## 1. Pin CakeML to the Revision Used by the Peregrine Proof Model

Use:

```text
CakeML commit:
e1650fc504837c0fbd3931cc5066914ffdc9d877
```

unless Milestone 05 proves compatibility with another revision.

Materialize:

```bash
rm -rf .aegis/cakeml-peregrine

git clone \
  https://github.com/CakeML/cakeml.git \
  .aegis/cakeml-peregrine

git -C .aegis/cakeml-peregrine \
  checkout --detach e1650fc504837c0fbd3931cc5066914ffdc9d877

git -C .aegis/cakeml-peregrine diff --exit-code
```

Record its digest/commit in the exact E2E manifest.

## 2. Keep HOL4 Pinned to the Existing Manual's Trust Root

Continue using:

```text
HOL4 commit:
40dd5b03de658f4bd9e3f4225fb0f1602ac90467
```

Do NOT switch HOL4 revisions merely because another local installation is available.

Build all final theorem objects with:

```text
.aegis/hol4/bin/hol
.aegis/hol4/bin/Holmake
```

## 3. Construct ONE Exact CakeML HOL4 Program Definition

The theorem-producing CakeML compiler requires a HOL4 theorem defining the exact CakeML program.

Create:

```text
formal/hol4/peregrine-selfhost/
  PeregrineCakeMLScript.sml
```

whose exported program theorem is conceptually:

```text
peregrine_selfhost_prog_def
```

The value MUST correspond to the exact CakeML AST `K` proved in Milestone 05.

Allowed path:

```text
proved CakeML AST K
   -> proved serializer/deserializer bridge
   -> HOL4 CakeML value
   -> peregrine_selfhost_prog_def
```

Forbidden path:

```text
candidate .cml
   -> unrelated unverified parser
   -> trust parsed program
```

## 4. Include the Complete Selfhost Application Semantics

Before compiler correctness, prove the exact program semantics.

Create:

```text
formal/hol4/peregrine-selfhost/
  PeregrineSemanticsScript.sml
```

The theorem should mean:

```text
semantics peregrine_selfhost_prog
  satisfies
PeregrineSelfHostSpec
  exact_peregrine_source
  exact_proof_corpus
  exact_assumptions
  exact_lambdabox
  exact_cakeml_program
```

This theorem MUST include:

- ordinary Peregrine pipeline behavior;
- validation behavior;
- retained proof replay behavior;
- exact certificate-corpus identity;
- exact assumption-ledger identity;
- proof-capsule behavior added in Milestone 07.

The CakeML compiler cannot create this application specification for you.

It can only preserve the semantics theorem you supply.

## 5. Use the Actual CakeML Theorem-Producing Compiler API

At the compatible CakeML revision, the official interface contains:

```sml
val eval_cake_compile :
  arch_thms -> string -> thm -> string -> thm

val eval_cake_compile_explore :
  arch_thms -> string -> thm -> string -> thm

val eval_cake_compile_with_conf :
  arch_thms -> string -> thm -> thm -> string -> thm
```

and the x64 wrapper exposes:

```sml
eval_cake_compile_x64
```

Create:

```text
formal/hol4/peregrine-selfhost/
  PeregrineCompileScript.sml
```

following the official pattern:

```sml
open preamble
     PeregrineCakeMLTheory
     eval_cake_compile_x64Lib

val _ = new_theory "PeregrineCompile";

Theorem peregrine_selfhost_compiled =
  eval_cake_compile_x64
    ""
    peregrine_selfhost_prog_def
    "generated/peregrine-selfhost/machine/peregrine-selfhost.S";

val _ = export_theory ();
```

Adjust only exact local theory names.

Do NOT replace the theorem-producing call with an external compiler subprocess.

## 6. Specialize CakeML's Generic Compiler Correctness Theorem

Follow the official `helloProofScript.sml` structure.

The CakeML example applies:

```sml
MATCH_MP compile_correct (cj 1 hello_compiled)
```

and then discharges:

- application non-failure;
- x64 backend configuration correctness;
- x64 machine configuration;
- x64 initialization assumptions.

Create the Peregrine equivalent:

```text
formal/hol4/peregrine-selfhost/
  PeregrineMachineProofScript.sml
```

with a theorem equivalent to:

```text
peregrine_selfhost_compiled_thm
```

that composes:

```text
peregrine_selfhost_semantics
+
peregrine_selfhost_compiled
+
compile_correct
+
x64_backend_config_ok
+
x64_machine_config_ok
+
x64_init_ok
```

## 7. Expose an Explicit Machine-Code Soundness Theorem

Follow CakeML's verified OpenTheory reader example.

That official proof defines:

```sml
Theorem machine_code_sound:
  ...
  installed_x64 ...
  =>
  machine_sem ...
```

Create:

```text
PeregrineMachineProofTheory.machine_code_sound
```

whose conclusion reaches the exact target-machine semantics.

Its specification side MUST be the exact Peregrine selfhost behavior, not merely:

```text
program terminates successfully
```

The machine theorem must transitively include the complete retained proof replay claim.

## 8. Make the Exact Machine-Code Value Addressable

Define an exact code constant, conceptually:

```sml
Definition peregrine_selfhost_code_def:
  peregrine_selfhost_code = (code, data, info)
End
```

following the CakeML OpenTheory reader example.

Bind:

```text
CakeML program digest
compiler configuration
code
data
FFI names
target architecture
machine setup predicates
```

to the final theorem.

Do NOT leave “which machine code?” outside HOL4 in a JSON file.

## 9. Check the Final HOL4 Theorem Through the Kernel

Apply:

```sml
val chk = machine_code_sound |> check_thm;
```

or the exact equivalent used by the pinned CakeML revision.

Then audit:

```sml
Thm.hyp machine_code_sound
Tag.dest_tag (Thm.tag machine_code_sound)
```

Reject unexpected:

- hypotheses;
- axioms;
- oracle tags;
- stale imported theorems.

## 10. Export the Theorem as a Portable OpenTheory Article

HOL4 provides:

```sml
OpenTheoryIO.thm_to_article
```

with signature:

```sml
val thm_to_article :
  TextIO.outstream ->
  (unit -> Thm.thm) ->
  unit
```

After `machine_code_sound` is checked, export:

```sml
val out =
  TextIO.openOut
    "generated/peregrine-selfhost/proofs/machine_code_sound.art";

val _ =
  OpenTheoryIO.thm_to_article
    out
    (fn () => machine_code_sound);
```

Use the exact required OpenTheory mappings for all constants/types.

If export fails because a type/constant has no OpenTheory name:

```text
DO NOT drop that dependency
```

either:

- provide a reviewed mapping;
- export a smaller explicitly supported theorem interface;
- or classify OpenTheory portability as BLOCKED.

## 11. Independently Re-Import the Exported Article in a Fresh HOL4 Theory

HOL4 also provides:

```sml
OpenTheoryIO.article_to_thm
```

and the lower-level `OpenTheoryReader`.

Create a fresh test theory/process and read the article.

Verify:

```text
reimported theorem conclusion
=
expected machine_code_sound conclusion
```

Inspect its hypotheses/tags.

This proves that the serialized proof artifact is not merely a pretty-printed theorem statement.

## 12. Produce the Machine-Proof Artifact Directory

Create:

```text
generated/peregrine-selfhost/proofs/
  peregrine-source-manifest.json
  peregrine-proof-corpus-manifest.json
  assumption-ledger.json
  lambdabox-binding.json
  cakeml-binding.json
  cake-compiler-binding.json
  machine-binding.json
  application-semantics.txt
  compiled-theorem.txt
  machine-code-sound.txt
  machine_code_sound.art
  theorem-tags.txt
  SHA256SUMS
```

These files will form part of the embedded Level-1 proof capsule.

## 13. Distinguish Theorem-Bound Code from External Executable Packaging

CakeML's theorem reaches the machine-code model represented in HOL4.

If you subsequently run:

```text
assembler
linker
ELF writer
objcopy
strip
patchelf
post-link section injection
```

you have introduced another transformation.

At this milestone, the authoritative object is:

```text
peregrine_selfhost_code
```

from the HOL4 theorem.

Physical executable packaging is handled separately in Milestone 07.

## 14. Mutation Tests

The theorem/export stage MUST fail if:

1. one CakeML AST node changes;
2. compiler configuration changes;
3. CakeML revision changes;
4. HOL4 revision changes;
5. proof-corpus digest changes;
6. application semantics theorem no longer contains replay behavior;
7. emitted machine-code theorem is replaced by standalone compiler output;
8. an oracle theorem is inserted;
9. OpenTheory article re-import does not reconstruct the expected conclusion.

## Completion Gate

This milestone is complete only when:

- exact CakeML program is a HOL4 definition;
- exact Peregrine selfhost semantics are proved for that program;
- CakeML compiler evaluation runs inside HOL4;
- `compile_correct` is specialized to the exact program;
- exact x64 machine configuration is discharged;
- `machine_code_sound` reaches exact machine semantics;
- HOL4 kernel checks the theorem;
- the theorem can be exported as a portable proof artifact or portability is explicitly marked blocked;
- exact theorem-bound machine code is distinguished from later file packaging.

## References

### MetaRocq

- MetaRocq verified source/erasure foundation that supplies the earlier source→LambdaBox theorem: https://github.com/MetaRocq/metarocq/blob/9.1/README.md
- MetaRocq erasure correctness: https://github.com/MetaRocq/metarocq/tree/9.1/erasure/theories

### Peregrine

- Peregrine pipeline source whose semantics are being preserved: https://github.com/peregrine-project/peregrine-tool/blob/d768b83ffa7dab35b8d72241f0570b5bb6aedae9/theories/Pipeline.v
- Peregrine CakeML backend documentation: https://github.com/peregrine-project/peregrine-tool/blob/d768b83ffa7dab35b8d72241f0570b5bb6aedae9/doc/backends.md
- Official compile-correct proof branch: https://github.com/peregrine-project/cakeml-backend/tree/5baed0b21618480b30711eb9df87e9bf00537372

### CakeML

- Exact theorem-producing compiler API: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/cv_translator/eval_cake_compileLib.sig
- x64 wrapper: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/cv_translator/eval_cake_compile_x64Lib.sml
- Official in-logic x64 compilation example: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/examples/compilation/x64/helloCompileScript.sml
- Official exact compiler-correctness composition: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/examples/compilation/x64/proofs/helloProofScript.sml
- Verified OpenTheory reader machine-code theorem example: https://github.com/CakeML/cakeml/blob/e1650fc504837c0fbd3931cc5066914ffdc9d877/examples/opentheory/compilation/proofs/readerProgProofScript.sml

### HOL4

- HOL4 theorem→OpenTheory article API: https://github.com/HOL-Theorem-Prover/HOL/blob/40dd5b03de658f4bd9e3f4225fb0f1602ac90467/src/opentheory/postbool/OpenTheoryIO.sml
- HOL4 OpenTheoryIO signature: https://github.com/HOL-Theorem-Prover/HOL/blob/40dd5b03de658f4bd9e3f4225fb0f1602ac90467/src/opentheory/postbool/OpenTheoryIO.sig
- HOL4 OpenTheory reader interface: https://github.com/HOL-Theorem-Prover/HOL/blob/40dd5b03de658f4bd9e3f4225fb0f1602ac90467/src/opentheory/reader/OpenTheoryReader.sig
