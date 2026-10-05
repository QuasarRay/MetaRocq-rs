# Original compiler evaluator checkpoint

FINALIZED means this observation is complete, not that an E2E gate passed.

The closed HOL4 compiler probe compiled an empty CakeML program. Its named
code-byte object and assembler export do not certify a project executable.
The assembler text is an export, not a substitute for the HOL byte object.

The exact compiler build products are preserved to avoid losing progress.
They are acceleration/provenance data; source replay and semantic refinement
must still be proved. Decode the complete archive with:

```sh
cat compiler-products.tar.gz.base64.part-* | base64 --decode > compiler-products.tar.gz
```

Verify the archive SHA256 against manifest.json before use. Preserve existing
edited work; this checkpoint does not authorize overwriting another build.
All captured failures remain in the checkpoint alongside the positive probe.
