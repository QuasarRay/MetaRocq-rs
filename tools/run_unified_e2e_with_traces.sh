#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
trace="${E2E_TRACE_DIR:?E2E_TRACE_DIR is required}"
controller="${UNIFIED_E2E_CONTROLLER:-$ROOT/generated/cakeml-unified-e2e/unified_e2e.cake}"

[[ -x "$controller" ]] || { echo "CakeML controller not executable: $controller" >&2; exit 1; }

if [[ -n "${CAKEML_REGRESSION_DIR:-}" ]]; then
  expected="23cfeba74d0cef77f7274ab41a2e8e87d4032995"
  actual="$(git -C "$CAKEML_REGRESSION_DIR" rev-parse HEAD)"
  [[ "$actual" == "$expected" ]] || { echo "CakeML/regression pin mismatch: $actual" >&2; exit 1; }
  printf 'repository=CakeML/regression\ncommit=%s\nworker_blob=c224f0ac983af7e8b252e232b2ecdb9dc4a74d5a\n'     "$actual" > "$trace/cakeml-regression-source.txt"
fi

export E2E_TRACE_DIR="$trace"
"$ROOT/tools/o11y_observe.sh" cake-controller "$controller" "$trace"
