# Milestone 10 — Make the Final Machine Image Replay Its Own Retained Proof State

## Objective

Make the exact final MetaRocq machine image execute the same self-reflective proof-replay contract that HOL4 certified during the build.

The result MUST distinguish two different facts:

1. **Foundational build-time fact** — HOL4 has already checked the theorem that the exact machine program refines the exact self-reflective MetaRocq specification and complete retained proof state.
2. **Recursive runtime fact** — when the resulting machine program is executed, it can enumerate and replay its own retained certificate/assumption state and produce the expected checked report.

Runtime self-replay is NOT allowed to become circular justification for itself. HOL4 remains the authority that proves the runtime replay implementation means what the project claims it means.

The intended structure is:

```text
exact source + complete proof corpus
              |
              | HOL4-checked source-to-machine theorem
              v
        exact machine image M
              |
              | execute M
              v
        self-replay report R
              |
              | theorem-bound observation
              v
same source/corpus/replay state certified during build
```

## 1. Put the complete retained state inside the executable semantics

The CakeML program used in Milestones 08–09 MUST contain or have theorem-bound access to:

```text
exact source snapshot identity
complete retained certificate corpus
complete assumption ledger
replay-job descriptions
self-CI/replay implementation
expected artifact identities
```

Do not load an arbitrary external proof corpus at runtime and then identify it with the build-time corpus merely by filename.

If external files are required because embedding is impractical, the machine theorem MUST model the file/FFI input and require the exact content digest/bytes as a precondition.

## 2. Add one deterministic machine-visible replay command

Extend the selfhost entrypoint with a command conceptually equivalent to:

```text
VerifyAllRetainedProofs
```

Its result SHOULD contain a deterministic record:

```text
source_snapshot_digest
certificate_corpus_digest
assumption_ledger_digest
number_of_certificates
number_of_assumptions
per-certificate replay status or aggregate proof-bound report
overall result
architecture/build identity
```

Do not permit “overall = true” without enough identity information to demonstrate which exact state was checked.

## 3. Cover the runtime command with the CakeML semantics theorem

The CakeML application semantics theorem from Milestone 08 MUST include the behavior of the replay command.

Conceptually prove:

```text
cakeml_selfhost_semantics
  exact_runtime_state
  VerifyAllRetainedProofs

= expected_replay_result
```

or the corresponding trace/refinement formulation used by the pinned CakeML development.

The result MUST connect to the same complete-corpus validity theorem used in the build-time HOL4 proof.

Do not implement the runtime replay command after the program-level semantics theorem has already been frozen without re-proving/rebuilding the downstream machine theorem.

## 4. Compile the replay command into the same exact machine image

Re-run the in-logic CakeML compilation after the replay feature is part of the exact CakeML program.

The theorem must bind:

```text
metarocq_selfhost_prog_def
       |
       | includes VerifyAllRetainedProofs
       v
eval_cake_compile_x64
       |
       v
exact machine program M
```

Do not ship a second unverified helper executable for proof replay.

If diagnostic tooling is separate, it may be used for observability only; it cannot substitute for the verified replay path inside M.

## 5. Prove the runtime report corresponds to the build-time report

Define an observation relation such as:

```text
same_replay_state
  build_time_report
  runtime_report
```

It SHOULD require equality of at least:

```text
source snapshot identity
certificate corpus identity
assumption ledger identity
certificate count/ordering identity
replay specification/version identity
result classification
```

Then derive a theorem equivalent to:

```text
MachineExec M VerifyAllRetainedProofs ==> runtime_report = R
/\
same_replay_state build_time_report R
```

under the explicit target/FFI premises of the CakeML machine model.

This theorem is stronger than comparing printed strings after execution.

## 6. Decide whether recursive identity means replay identity or rebuild identity

There are two different recursive goals. Do NOT conflate them.

### Level A — self-replay identity

The final image replays the same retained proof state and reports the same certified claims.

Required for this manual.

```text
M
  -> replay exact retained state
  -> same checked report
```

### Level B — reproducible self-rebuild identity

The final image can rebuild itself and reproduce the exact same machine image:

```text
M + exact source/toolchain state
  -> rebuild
  -> M'
  -> bytes(M') = bytes(M)
```

This is a useful stronger reproducibility property but is NOT automatically implied by Level A.

If Level B is required, model and prove every extra input needed for deterministic rebuilding: filesystem ordering, timestamps, paths, compiler configuration, generated labels/symbols, packaging, and FFI behavior.

Do not mark Level B complete because Level A succeeds.

## 7. Implement the local runtime-replay command

Add:

```bash
./tools/selfhost-e2e.sh replay-machine
```

The command SHOULD:

1. verify the exact final machine image digest;
2. execute the theorem-bound entrypoint;
3. capture stdout/stderr/exit status only as transport evidence;
4. parse the deterministic replay report;
5. compare report identities with the exact final manifest;
6. invoke the HOL4 theorem/build check that establishes the semantic correspondence;
7. emit `generated/e2e/runtime-replay/`.

Recommended output:

```text
generated/e2e/runtime-replay/
  machine.sha256
  replay-report.json
  stdout.sha256
  stderr.sha256
  correspondence-theorem.txt
  assumptions.txt
```

The shell comparison is not the proof. It is a consistency/audit layer around the theorem.

## 8. Treat FFI and operating-system interaction explicitly

The machine replay may require:

```text
stdin/stdout
filesystem
arguments
environment variables
clock
randomness
process exit
```

Prefer a deterministic replay path that minimizes all of them.

For every required FFI behavior:

- identify the CakeML FFI model;
- include the exact premise in the machine theorem;
- avoid ambient environment dependence;
- record the concrete runtime input bytes where possible.

Do not use current time, random UUIDs, network data, or uncontrolled directory enumeration as part of the certified replay result.

## 9. Verify machine identity before execution

Before the runtime test:

```bash
sha256sum -c generated/e2e/final/machine.sha256
```

If the verified target is a raw CakeML machine-code representation rather than a packaged ELF, distinguish:

```text
theorem-bound machine code digest
packaged executable digest
```

and do not assert equality unless the packaging step is proved.

## 10. Add recursive mutation tests

All of these MUST cause the runtime correspondence gate or final theorem rebuild to fail:

- modify one embedded certificate;
- modify one assumption;
- replace the replay report with an older report;
- run a different machine image;
- alter one FFI input expected by the theorem;
- remove the runtime replay command;
- compile a diagnostic wrapper that is not the theorem-bound entrypoint;
- change the certificate order if ordering is part of the canonical corpus.

## 11. Preserve build-time authority

The final trust logic MUST remain:

```text
HOL4 proves machine semantics
        |
        v
machine executes self-replay
        |
        v
runtime result confirms the theorem-bound self state
```

It MUST NOT become:

```text
machine says "I am valid"
        |
        v
therefore machine is valid
```

The second structure is circular and provides no independent foundation.

## Completion gate

Milestone 10 is complete only when:

- the exact machine program contains the complete retained proof/replay state or theorem-bound access to it;
- the replay command is included in the program semantics theorem;
- the exact machine compilation theorem covers that program;
- runtime output is theorem-related to the build-time replay state;
- all required FFI premises are explicit;
- self-replay identity is separated from the stronger optional self-rebuild identity;
- changing the machine image or retained corpus invalidates the correspondence.

## References

### MetaRocq

- MetaRocq overview, including quotation, SafeChecker, erasure and self-erasure: https://github.com/MetaRocq/metarocq/blob/9.1/README.md
- MetaRocq self-erasure test: https://github.com/MetaRocq/metarocq/blob/9.1/test-suite/self_erasure.v
- MetaRocq quotation package description: https://github.com/MetaRocq/metarocq/blob/9.1/INSTALL.md

### CakeML

- CakeML repository: https://github.com/CakeML/cakeml
- Verified CakeML Compiler Backend: https://cakeml.org/jfp19.pdf
- Concrete in-logic x64 compilation: https://github.com/CakeML/cakeml/blob/master/examples/compilation/x64/helloCompileScript.sml
- Concrete machine-level correctness proof composition: https://github.com/CakeML/cakeml/blob/master/examples/compilation/x64/proofs/helloProofScript.sml
- CakeML basis/FFI proof helper interface: https://github.com/CakeML/cakeml/blob/master/basis/basis_ffiLib.sig

### HOL4

- HOL4 official documentation: https://hol-theorem-prover.org/docs/trindemossen-2/
- HOL4 logic description: https://hol-theorem-prover.org/docs/trindemossen-2/Description/
- HOL4 developer/kernel documentation: https://hol-theorem-prover.org/docs/trindemossen-2/Developers/
