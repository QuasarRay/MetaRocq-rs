#!/usr/bin/env bash
set -euo pipefail

name="${1:-}"
shift || true
[[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "invalid observation name" >&2; exit 64; }
[[ "$#" -gt 0 ]] || { echo "no command supplied" >&2; exit 64; }

trace="${E2E_TRACE_DIR:?E2E_TRACE_DIR is required}"
dir="$trace/preflight/$name"
mkdir -p "$dir"
[[ ! -e "$dir/complete" ]] || { echo "observation already completed: $name" >&2; exit 1; }

printf '%q ' "$@" > "$dir/command.txt"
printf '\n' >> "$dir/command.txt"
printf 'started_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$dir/status.txt"

set +e
/usr/bin/time -v -o "$dir/time-memory.txt" "$@" >"$dir/stdout-stderr.log" 2>&1
rc=$?
set -e

{
  echo "exit=$rc"
  echo "finished_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} >> "$dir/status.txt"

cat "$dir/stdout-stderr.log"
if [[ "$rc" -eq 0 ]]; then
  printf 'SUCCESS\n' > "$dir/complete"
else
  printf 'FAILED: %s exit=%s\n' "$name" "$rc" > "$dir/complete"
fi
exit "$rc"
