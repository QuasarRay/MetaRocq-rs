# Milestone 08 — Compile the Exact CakeML Selfhost Program Inside HOL4 to Exact Machine Code

## Objective

Use CakeML's existing theorem-producing in-logic compiler evaluation so that the exact CakeML selfhost/replay program from Milestone 06 is compiled **inside HOL4**, and the exact compiled machine program is connected to CakeML semantics by CakeML's verified compiler theorem.

Do NOT invoke a standalone CakeML compiler executable and then ask HOL4 to trust the output.

The required path is:

```text
exact CakeML program definition
        |
        | eval_cake_compile_x64 inside HOL4
        v
HOL4 theorem describing the exact compilation result
        |
        | compile_correct + target configuration theorems
        v
HOL4 machine-level correctness theorem
```

## 1. Use CakeML's theorem-producing compiler evaluator

CakeML exposes:

```sml
val eval_cake_compile :
  arch_thms -> string -> thm -> string -> thm
```

and architecture-specific wrappers such as `eval_cake_compile_x64`.

The upstream concrete pattern is:

```sml
Theorem hello_compiled =
  eval_cake_compile_x64 "" hello_prog_def "hello.S";
```

Follow this pattern for the exact MetaRocq CakeML program.

## 2. Define the exact program as a HOL4 definition

The exact CakeML artifact from Milestone 06 MUST become a deterministic HOL4 definition, for example:

```text
metarocq_selfhost_prog_def
```

The definition must be generated from the exact proved Peregrine/CakeML result, not reconstructed independently by a different parser/printer.

Preferred path:

```text
proved Peregrine CakeML AST
     -> mechanically imported/generated HOL4 CakeML value
     -> metarocq_selfhost_prog_def
```

If text/S-expression serialization is unavoidable, prove the serializer/parser round trip and bind the parsed result to the theorem.

## 3. Compile in HOL4

In:

```text
formal/hol4/selfhost/MetaRocqMachineScript.sml
```

use the same architecture library as CakeML's x64 examples.

Conceptual script:

```sml
Theory MetaRocqMachine
Ancestors
  MetaRocqCakeML
  backendProof
  x64_configProof
Libs
  preamble
  eval_cake_compile_x64Lib

Theorem metarocq_selfhost_compiled =
  eval_cake_compile_x64
    ""
    metarocq_selfhost_prog_def
    "generated/e2e/metarocq-selfhost.S";
```

Adapt theory names and include paths to the pinned CakeML revision.

The returned object MUST be a HOL4 theorem.

## 4. Prove the CakeML program semantics before composing compiler correctness

The compiler theorem transports the semantics you have proved for the CakeML program. It does not invent the application specification.

Before applying `compile_correct`, prove a theorem equivalent to:

```text
metarocq_selfhost_semantics:
  semantics metarocq_selfhost_prog
  satisfies
  SelfReflectiveMetaRocqSpecification
```

The specification MUST include:

- the exact source/proof corpus identity;
- complete proof replay behavior;
- assumption-ledger behavior;
- self-CI behavior needed by the final claim;
- the exact Peregrine/LambdaBox refinement facts.

This theorem is where the earlier source→LambdaBox→Peregrine chain enters CakeML semantics.

## 5. Compose with CakeML's verified compiler theorem

Reuse the upstream CakeML proof pattern rather than designing a new compiler proof.

CakeML's x64 hello proof does conceptually:

```sml
val compile_correct_applied =
  MATCH_MP compile_correct (cj 1 hello_compiled)
  ...
```

and finishes with:

```sml
Theorem hello_compiled_thm =
  CONJ compile_correct_applied hello_output
  |> DISCH_ALL
  |> check_thm
```

Create the analogous MetaRocq theorem.

The final program-specific theorem SHOULD connect:

```text
machine execution of exact compiled program
        refines
CakeML semantics of exact MetaRocq selfhost program
```

under the explicit x64 machine/FFI/configuration premises required by the pinned CakeML proof.

## 6. Bind the exact target configuration

Record and prove the exact:

```text
architecture = x86-64
CakeML backend configuration
FFI configuration
startup state assumptions
memory/model assumptions
endianness
word size
entrypoint
```

Use CakeML's existing:

```text
x64_backend_config_ok
x64_machine_config_ok
x64_init_ok
```

or the exact equivalents at the pinned CakeML revision.

Do not silently change target flags between theorem generation and binary production.

## 7. Distinguish verified machine-code representation from executable packaging

CakeML's compiler proof reaches the target machine-code semantics represented in the HOL development.

If you subsequently use an external:

```text
assembler
linker
ELF writer
loader
libc/runtime
```

that transformation becomes another potential hole.

Preferred publication target:

```text
exact machine-code image/bytes represented by the CakeML theorem
```

If you also create an ELF executable, either:

1. prove the packaging/loader correspondence; or
2. state the final theorem over the verified code image and list the external packaging/loader as an explicit deployment assumption.

Do not call an ordinary linked ELF “fully E2E proved” unless the additional boundary is covered.

## 8. Produce exact machine-code evidence

Write deterministic evidence under:

```text
generated/e2e/machine/
```

including:

```text
compiler theorem name
CakeML program digest
target configuration digest
machine-code representation digest
emitted assembly digest, if emitted
final packaged-image digest, if separately packaged
assumption/dependency report
```

The emitted `.S` file is useful for audit, but the theorem object is authoritative.

## 9. Compare the generated artifact with theorem-bound data

Where CakeML emits external assembly or code files during evaluation, verify that the file corresponds exactly to the compilation theorem result.

Do not trust file output merely because it was written during the same process.

Add a conversion/check whose correctness is either:

- already provided by CakeML;
- proved in HOL4;
- or explicitly recorded as a non-semantic presentation layer not used for the final theorem.

## 10. Build locally

From repository root:

```bash
export HOLDIR="$PWD/.aegis/hol4"
export PATH="$HOLDIR/bin:$PATH"

cd formal/hol4/selfhost
Holmake MetaRocqMachineTheory
cd ../../..
```

Then verify output files:

```bash
test -s generated/e2e/metarocq-selfhost.S
sha256sum generated/e2e/metarocq-selfhost.S \
  > generated/e2e/machine/metarocq-selfhost.S.sha256
```

The exact target names may differ with the pinned CakeML/HOL4 `Holmakefile`; keep the command deterministic.

## 11. The machine theorem must depend on the exact proof-replay semantics

Do not allow this disconnected structure:

```text
Theorem A: MetaRocq proofs replay
Theorem B: unrelated CakeML program compiles correctly
```

Require the CakeML program definition in Theorem B to be the same program whose semantics theorem contains the replay behavior from Theorem A.

That identity is a mandatory premise for Milestone 09.

## 12. Negative tests

All of these MUST invalidate the final machine theorem binding:

- change one CakeML AST node;
- change the compiler target;
- change CakeML source revision;
- use the standalone CakeML compiler output instead of in-logic evaluation;
- mutate emitted assembly;
- change FFI configuration;
- replace the exact MetaRocq program with a wrapper not covered by the semantics theorem;
- package through an unproved linker and silently identify the packaged bytes with the verified machine image.

## Completion gate

Milestone 08 is complete only when:

- the exact MetaRocq CakeML program exists as a HOL4/CakeML definition;
- its self-reflective replay semantics theorem is proved;
- `eval_cake_compile_x64` (or exact target equivalent) compiles that definition inside HOL4;
- CakeML's `compile_correct` is specialized to that exact compilation;
- target configuration assumptions are explicit;
- the theorem is bound to the exact generated machine-code representation;
- any ELF/linker/loader boundary is either proved or explicitly outside the theorem.

## References

### MetaRocq

- MetaRocq architecture and verified extraction context: https://github.com/MetaRocq/metarocq/blob/9.1/README.md
- Correct and Complete Type Checking and Certified Erasure for Coq, in Coq: https://dl.acm.org/doi/10.1145/3706056
- MetaRocq erasure theories: https://github.com/MetaRocq/metarocq/tree/9.1/erasure/theories

### CakeML

- Theorem-producing compiler evaluation API: https://github.com/CakeML/cakeml/blob/master/cv_translator/eval_cake_compileLib.sig
- Concrete x64 in-logic compilation example: https://github.com/CakeML/cakeml/blob/master/examples/compilation/x64/helloCompileScript.sml
- Concrete x64 E2E proof using `compile_correct`: https://github.com/CakeML/cakeml/blob/master/examples/compilation/x64/proofs/helloProofScript.sml
- Verified CakeML Compiler Backend: https://cakeml.org/jfp19.pdf
- CakeML repository: https://github.com/CakeML/cakeml

### HOL4

- HOL4 official documentation: https://hol-theorem-prover.org/docs/trindemossen-2/
- HOL4 developer/build documentation: https://hol-theorem-prover.org/docs/trindemossen-2/Developers/
- HOL4 logic description: https://hol-theorem-prover.org/docs/trindemossen-2/Description/
