# CakeML certificate runtime

`CertificateRuntime.sml` defines only the runtime representation of the portable HOL4 attestation that the final machine program is intended to expose.

It intentionally does **not** validate HOL4 by itself. The final HOL4 theorem must prove that:

1. the exact CakeML program contains this payload;
2. the payload corresponds to the exact proof/theorem object checked by HOL4;
3. the exact machine code refines the CakeML program that exposes it.

Until those theorems exist, this directory is an interface contract, not certification evidence.
