This immutable checkpoint records physical vendoring and an extraction attempt blocked by an unavailable local toolchain. No LambdaBox or machine-code proof was produced.

Decode the exact complete inventory with:

```sh
base64 -d source-inventory.json.gz.b64 | gzip -d > source-inventory.json
```

Validate its decompressed SHA-256 and byte count against manifest.json.
