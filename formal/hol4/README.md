# HOL4 / Z3 adapter qualification

MetaRocqBootstrapScript.sml proves a small integer identity using HolSmtLib.Z3_TAC,
then inspects its oracle tags and hypotheses. This is not a PCUIC or Rust theorem.
It has not been executed locally because HOL4/Z3 are unavailable.

Use the HOL4 and hol4-mcp pins from the locked Aegis contracts/toolchain.json.
Build HolSmt and integer theories, set HOLDIR to that checkout, and configure Z3 as
required by the pinned HOL4 HolSmt documentation. Then run bootstrap.py hol4-smoke.
MCP and TacticToe aid search only; they do not authorize a proof-completion claim.
Do not substitute Z3_ORACLE_TAC or an exit-status check for theorem inspection.
