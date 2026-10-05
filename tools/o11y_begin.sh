#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

branch="${GITHUB_REF_NAME:-$(git branch --show-current)}"
[[ -n "$branch" ]] || { echo "cannot determine trace branch" >&2; exit 1; }

# In Actions, run from the newest remote tip so all previously pushed trace
# commits are present locally before this run begins.
git fetch --prune origin "$branch"
if [[ "${GITHUB_ACTIONS:-}" == "true" ]]; then
  git switch -C "$branch" "origin/$branch" >/dev/null
fi

origin_head="$(git rev-parse "origin/$branch")"
repo_head="$(git rev-parse HEAD)"
short="${repo_head:0:12}"

if [[ -n "${GITHUB_RUN_ID:-}" ]]; then
  run_id="github-${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT:-1}-$short"
else
  run_id="local-$(date -u +%Y%m%dT%H%M%SZ)-$$-$short"
fi
[[ "$run_id" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "unsafe run id: $run_id" >&2; exit 1; }

trace=".o11y/$run_id"
if [[ -e "$trace" ]] || git cat-file -e "origin/$branch:$trace" 2>/dev/null; then
  echo "refusing to reuse existing trace directory: $trace" >&2
  exit 1
fi

mkdir -p "$trace/preflight" "$trace/stages"
{
  echo "run_id=$run_id"
  echo "branch=$branch"
  echo "origin_before_run=$origin_head"
  echo "repository_head=$repo_head"
  echo "dispatch_sha=${GITHUB_SHA:-}"
  echo "workflow_run_id=${GITHUB_RUN_ID:-}"
  echo "workflow_run_attempt=${GITHUB_RUN_ATTEMPT:-}"
  echo "started_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$trace/run.env"

git status --porcelain=v1 > "$trace/preflight/git-status-before.txt"
git log -1 --format=fuller > "$trace/preflight/repository-head.txt"
printf '%s\n' "$trace"
