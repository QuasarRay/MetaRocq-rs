#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

branch="${E2E_TARGET_REF:-${GITHUB_REF_NAME:-$(git branch --show-current)}}"
branch="${branch#refs/heads/}"
[[ -n "$branch" ]] || { echo "cannot determine trace branch" >&2; exit 1; }
git check-ref-format "refs/heads/$branch" >/dev/null 2>&1 || {
  echo "invalid trace branch: $branch" >&2
  exit 1
}

repo_before="$(git rev-parse HEAD)"
short="${repo_before:0:12}"
if [[ -n "${GITHUB_RUN_ID:-}" ]]; then
  run_id="github-${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT:-1}-$short"
else
  run_id="local-$(date -u +%Y%m%dT%H%M%SZ)-$$-$short"
fi
[[ "$run_id" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "unsafe run id: $run_id" >&2; exit 1; }

trace=".o11y/$run_id"
[[ ! -e "$trace" ]] || { echo "refusing to reuse local trace directory: $trace" >&2; exit 1; }
mkdir -p "$trace/preflight" "$trace/stages"

# Publish the path before any network operation. If origin synchronization
# itself fails, later always() workflow steps can still finalize and attempt to
# persist the failure trace.
if [[ -n "${GITHUB_ENV:-}" ]]; then
  printf 'E2E_TRACE_DIR=%s\n' "$trace" >> "$GITHUB_ENV"
fi

{
  echo "run_id=$run_id"
  echo "branch=$branch"
  echo "repository_head_before_sync=$repo_before"
  echo "dispatch_sha=${GITHUB_SHA:-}"
  echo "workflow_run_id=${GITHUB_RUN_ID:-}"
  echo "workflow_run_attempt=${GITHUB_RUN_ATTEMPT:-}"
  echo "started_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$trace/run.env"

set +e
git fetch --prune origin "$branch" >"$trace/preflight/origin-sync-before.log" 2>&1
fetch_rc=$?
set -e
if [[ "$fetch_rc" -ne 0 ]]; then
  printf 'FAILED: origin fetch exit=%s\n' "$fetch_rc" > "$trace/preflight/origin-sync-before.result"
  cat "$trace/preflight/origin-sync-before.log" >&2
  printf '%s\n' "$trace"
  exit "$fetch_rc"
fi

if git cat-file -e "origin/$branch:$trace" 2>/dev/null; then
  printf 'FAILED: origin already contains %s\n' "$trace" > "$trace/preflight/origin-sync-before.result"
  printf '%s\n' "$trace"
  exit 1
fi

if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
  set +e
  git switch -C "$branch" "origin/$branch" >>"$trace/preflight/origin-sync-before.log" 2>&1
  switch_rc=$?
  set -e
  if [[ "$switch_rc" -ne 0 ]]; then
    printf 'FAILED: origin synchronization switch exit=%s\n' "$switch_rc" > "$trace/preflight/origin-sync-before.result"
    printf '%s\n' "$trace"
    exit "$switch_rc"
  fi
fi

origin_head="$(git rev-parse "origin/$branch")"
repo_after="$(git rev-parse HEAD)"
{
  echo "origin_before_run=$origin_head"
  echo "repository_head_after_sync=$repo_after"
} >> "$trace/run.env"
printf 'SUCCESS\n' > "$trace/preflight/origin-sync-before.result"

git status --porcelain=v1 > "$trace/preflight/git-status-before.txt"
git log -1 --format=fuller > "$trace/preflight/repository-head.txt"
printf '%s\n' "$trace"
