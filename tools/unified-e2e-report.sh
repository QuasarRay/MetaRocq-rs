#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
out=generated/e2e/unified-reuse-provenance.json
mkdir -p "$(dirname "$out")"

peregrine_status=BLOCKED
metarocq_status=BLOCKED
[[ -s generated/peregrine-selfhost/final/final-e2e-theorem.txt && -s generated/peregrine-selfhost/final/fresh-e2e-theorem.txt ]] && peregrine_status=PROVED
[[ -s generated/e2e/final/final-theorem.txt ]] && metarocq_status=PROVED

cat >"$out" <<JSON
{
  "schema": 1,
  "sequence": "Peregrine -> MetaRocq",
  "peregrine": "$peregrine_status",
  "metarocq": "$metarocq_status",
  "required_handoff": "exact theorem-bound Peregrine LambdaBox -> CakeML bridge",
  "publication": "$([[ "$peregrine_status" == PROVED && "$metarocq_status" == PROVED ]] && echo ELIGIBLE || echo BLOCKED)"
}
JSON
cat "$out"
