# Generated API wrapper pipeline

Inputs:
- pinned HOL4 source and public SML signatures;
- machine-readable canonical API contracts;
- generated source-digest manifest.

Outputs:
- complete canonical API inventory;
- CakeML facade source;
- Standard ML adapter source;
- HOL4 wrapper-contract theory input;
- coverage and compatibility reports.

The generator is separated from public-API extraction. Extraction may be
implemented by an untrusted host tool because publication depends on source
hashes, complete declaration accounting, deterministic regeneration and HOL4
checking of the generated contract.

The stable runtime boundary is bytes plus typed opaque handles. No native
Poly/ML object is shared with CakeML.

Run `tools/run_generated_api_wrapper_pipeline.sh` after materialising the exact
pinned HOL4 and CakeML revisions. The pipeline is fail-closed and does not
claim qualification merely because code generation succeeds.
