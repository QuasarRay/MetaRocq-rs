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
set +e
"$ROOT/tools/o11y_observe.sh" cake-controller "$controller" "$trace"
controller_status=$?
set -e

# The requested proof-search qualification reuses the controller's exact switch.
# Its process and retained proof terms are observed independently of the image.
set +e
"$ROOT/tools/o11y_observe.sh" original-tactician-qualification \
  bash "$ROOT/tools/run_original_tactician_probe.sh"
tactician_status=$?
set -e

# This retained-image root differs from the legacy Peregrine extraction root.
# Attempt it once in the explicitly requested run, even if the controller
# stops earlier. A candidate cannot open the controller's semantic proof gates.
set +e
"$ROOT/tools/o11y_observe.sh" three-project-retained-candidate \
  bash "$ROOT/tools/build_original_three_project_lambdabox.sh"
retained_status=$?
set -e
printf 'controller=%s\ntactician_qualification=%s\nretained_candidate=%s\n' \
  "$controller_status" "$tactician_status" "$retained_status" > "$trace/explicit-producer-statuses.txt"
if [[ "$controller_status" -ne 0 ]]; then
  exit "$controller_status"
fi
if [[ "$tactician_status" -ne 0 ]]; then
  exit "$tactician_status"
fi
exit "$retained_status"
