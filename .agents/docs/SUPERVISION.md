# Independent supervision and proof limits

A supervisor should independently fetch the pinned original repositories, compare the
original HOL4 definition and the paper, inspect the Rust correspondence statement,
then rerun the exact invocation from the evidence at the PR head. Check licenses and
reuse decisions, all `assume`/external-body/stub boundaries, Kani unwind/assumption scope,
Verus trusted specifications, parser correspondence, compiler and runtime assumptions.
Read changed contracts before accepting new evidence. Source proofs, machine-code
soundness and observable compatibility are separate review questions.

Aegis rejects stale, missing, duplicate, vacuous/unknown-output and failed results. It
requires exact declared Kani harness identity and a positive Verus verification count.
It does not understand mathematical statements, prove the Rust/HOL4 semantic bridge,
or determine whether an assertion is strong enough. Such claims remain human-reviewed
obligations. The eight seed anchors are starting references, not full import closure. Additional
HOL4 theories under the declared original-source roots are bound directly to Git
objects from the same pinned CakeML commit. Symbol lookup is a navigation check,
not a HOL4 parser or interpreter.

The controller and selected verifier binaries are hashed; transitive compiler/solver,
HOL4, package registry and host dependencies are not thereby fully attested. A real
release needs a reproducible pinned toolchain/environment and the import closure. A
verified Rust source claim still does not establish the original compiler theorem for
rustc, its runtime, or the host operating system.

The working tree snapshot includes tracked and untracked nonignored files except runtime
state and evidence. Build outputs and ignored/external dependencies are outside it.
Verification must not silently rely on ignored input. Use a clean isolated checkout and
pin dependencies; inspect Cargo metadata/configuration and generated source. The
controller is not a sandbox for hostile Cargo build scripts or verifier executables.

Evidence and local state are unsigned files. A same-user adversary can forge them or
modify the control plane. Hashing is change detection, not independent attestation.
CI plus human re-execution at the exact GitHub head is the supervision boundary. PR
checkpointing checks a live GitHub response and Git ref; it does not claim branch
protection is enabled or guarantee that nobody will later delete the branch.

Network failures block checkpointing. Local commits still preserve work locally. Publish
small PRs during development, including unresolved work, before expensive verification.
This branch does not grant itself permission to merge PRs or overwrite global settings.

An abandoned runtime lock fails closed. Stop competing control processes, inspect
the recorded process/host identity, preserve state, and remove only that abandoned
lock during exclusive recovery. Automatic stale-lock deletion was removed because
concurrent recovery can otherwise delete a newly acquired lock.
