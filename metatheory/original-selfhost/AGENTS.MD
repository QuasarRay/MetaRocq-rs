# Original MetaRocq self-hosting experiment

This directory inherits the repository project goals and adds the following local rules.

1. This work is an isolated Original-MetaRocq self-verification experiment. It does not select or replace the canonical Rust-native MetaRocq-rs MetaTheory or Rust-native PCUIC. GPT-6 Astra remains the only agent authorized to choose the canonical Rust-native formalization.

2. Keep the trusted execution path in MetaRocq/Rocq source. GitHub Actions, shell, Python, and external build scripts may install pinned dependencies, invoke the extracted executable, archive evidence, and fail closed, but they must not implement proof-search, proof translation, theorem selection, or proof acceptance policy.

3. The final intended executable is a single program obtained from a MetaRocq-defined lambda-box program and lowered to CakeML with Peregrine. The executable must contain the self-verification pipeline as program data/code rather than depending on a live Rocq plugin environment.

4. MetaRocq must quote the source/metatheory dependency closure at build time and embed the resulting PCUIC representation into the executable. Never pretend an extracted executable can query Rocq's live environment after extraction.

5. OpenTheory output is accepted only when every source theorem is lowered through an explicit proof-producing transformation. Never replace a missing proof with an OpenTheory axiom, theorem declaration without derivation, proof hole, admitted theorem, opaque trust escape, or unchecked conversion.

6. The Candle boundary is the verified CakeML OpenTheory article checker. Treat the checker/compiler binaries as pinned external trust dependencies and preserve their source/release identity and hashes in evidence.

7. Every transformation that is not yet proved semantics-preserving must return an explicit blocked/unsupported result. The pipeline is fail closed.

8. Reuse MetaRocq quotation, PCUIC metatheory, erasure, verified lambda-box pipeline, Peregrine's existing CakeML backend, and CakeML/Candle's existing OpenTheory checker before implementing new infrastructure.

9. Preserve every successful artifact and proof obligation across stacked branches. New PRs must be based on the preceding PR head and must not duplicate work from earlier layers.

10. Separate three claims in code and documentation:
   - executable architecture exists,
   - a proof translation is mechanically produced,
   - the proof translation is independently checked and semantically justified.
   Never infer the third from the first two.
