#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
trace="${E2E_TRACE_DIR:?E2E_TRACE_DIR is required}"
[[ "$trace" == .o11y/* && -d "$trace" ]] || { echo "invalid trace directory: $trace" >&2; exit 1; }
[[ -f "$trace/FINALIZED" && -s "$trace/SHA256SUMS" ]] || { echo "trace not finalized" >&2; exit 1; }

branch="${E2E_TARGET_REF:-${GITHUB_REF_NAME:-$(git branch --show-current)}}"
branch="${branch#refs/heads/}"
[[ -n "$branch" ]] || { echo "cannot determine branch" >&2; exit 1; }
git check-ref-format "refs/heads/$branch" >/dev/null 2>&1 || {
  echo "invalid trace branch: $branch" >&2
  exit 1
}
run_id="$(basename "$trace")"

git fetch --prune origin "$branch"
if git cat-file -e "origin/$branch:$trace" 2>/dev/null; then
  echo "refusing to overwrite origin trace: $trace" >&2
  exit 1
fi

git add -- "$trace"
changes="$(git diff --cached --name-status -- "$trace")"
[[ -n "$changes" ]] || { echo "no new trace files to synchronize" >&2; exit 1; }
if printf '%s\n' "$changes" | awk '$1 != "A" {bad=1} END{exit bad}'; then :; else
  echo "append-only violation: trace sync contains non-additions" >&2
  printf '%s\n' "$changes" >&2
  exit 1
fi

git -c user.name='MetaRocq E2E Trace Bot' \
    -c user.email='actions@users.noreply.github.com' \
    commit -m "o11y: append $run_id"

for attempt in 1 2 3 4 5; do
  if git push origin "HEAD:$branch"; then
    echo "synchronized $trace to origin/$branch"
    exit 0
  fi
  echo "push raced with origin; rebasing append-only trace (attempt $attempt)" >&2
  git fetch origin "$branch"
  git rebase "origin/$branch"
  if git cat-file -e "origin/$branch:$trace" 2>/dev/null; then
    echo "origin acquired duplicate run id during retry: $trace" >&2
    exit 1
  fi
done

echo "failed to synchronize trace after retries" >&2
exit 1
