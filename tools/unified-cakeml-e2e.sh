#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MODE="${1:-prove}"
CAKEML_DRIVER="${UNIFIED_E2E_CAKEML_BIN:-$ROOT/.aegis/bin/unified-e2e}"

if [[ ! -x "$CAKEML_DRIVER" ]]; then
  cat >&2 <<MSG
BLOCKED: CakeML unified E2E driver is not executable:
  $CAKEML_DRIVER
Compile pipeline/cakeml/UnifiedE2E.cml with the bootstrapped CakeML compiler and
set UNIFIED_E2E_CAKEML_BIN to the resulting executable.
MSG
  exit 2
fi

plan="$(mktemp)"
trap 'rm -f "$plan"' EXIT

case "$MODE" in
  prove|plan|peregrine|metarocq)
    "$CAKEML_DRIVER" "$MODE" >"$plan"
    ;;
  step)
    [[ $# -eq 2 ]] || { echo "usage: $0 step NN" >&2; exit 64; }
    "$CAKEML_DRIVER" step "$2" >"$plan"
    ;;
  *)
    echo "usage: $0 <prove|plan|peregrine|metarocq|step NN>" >&2
    exit 64
    ;;
esac

if [[ "$MODE" == plan ]]; then
  cat "$plan"
  exit 0
fi

while IFS=$'\t' read -r step manual command; do
  [[ -n "$step" && -n "$manual" && -n "$command" ]] || {
    echo "BLOCKED: malformed CakeML plan line" >&2
    exit 65
  }
  printf '=== unified E2E step %s: %s ===\n' "$step" "$manual"
  UNIFIED_E2E_STEP="$step" \
  UNIFIED_E2E_MANUAL="$manual" \
    bash -euo pipefail -c "$command"
done <"$plan"
