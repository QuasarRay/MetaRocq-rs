#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
trace="${E2E_TRACE_DIR:?E2E_TRACE_DIR is required}"
[[ "$trace" == .o11y/* && -d "$trace" ]] || { echo "invalid trace directory: $trace" >&2; exit 1; }

{
  echo "finished_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "repository_head_at_finalize=$(git rev-parse HEAD)"
  if [[ -s "$trace/controller.success" ]]; then
    echo "result=SUCCESS"
  else
    echo "result=FAIL_CLOSED"
  fi
  failed="$(find "$trace" -type f \( -name 'failure.txt' -o -name 'regression-result.txt' -o -name complete -o -name '*.result' \) -print | sort | xargs -r grep -l '^FAILED' || true)"
  if [[ -n "$failed" ]]; then
    echo "failure_files_begin"
    printf '%s\n' "$failed"
    echo "failure_files_end"
  fi
} > "$trace/manifest.txt"

{
  uname -a || true
  git --version || true
  bash --version | head -1 || true
  [[ -x /usr/bin/time ]] && /usr/bin/time --version | head -1 || true
  command -v rocq >/dev/null && rocq -v || true
  command -v peregrine >/dev/null && peregrine --help 2>&1 | head -20 || true
  if [[ -n "${CAKEML_REGRESSION_DIR:-}" && -d "$CAKEML_REGRESSION_DIR/.git" ]]; then
    echo "cakeml_regression_commit=$(git -C "$CAKEML_REGRESSION_DIR" rev-parse HEAD)"
    git -C "$CAKEML_REGRESSION_DIR" status --porcelain=v1
  fi
} > "$trace/toolchain-and-host.txt" 2>&1

# FINALIZED is part of the hashed payload.  SHA256SUMS intentionally excludes
# itself because a finite file cannot contain its own cryptographic digest.
touch "$trace/FINALIZED"
(
  cd "$trace"
  rm -f SHA256SUMS
  find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS
)
