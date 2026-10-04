#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
RUN_DIR="${1:?run directory required}"
BRANCH="${2:-${GITHUB_REF_NAME:-}}"
[[ -n "$BRANCH" ]] || { echo 'cannot determine branch for o11y persistence' >&2; exit 2; }
mkdir -p "$RUN_DIR"
RUN_DIR="$(realpath "$RUN_DIR")"
RUN_REL="$(realpath --relative-to="$ROOT" "$RUN_DIR")"
case "$RUN_REL" in
  .o11y/runs/*) ;;
  *) echo "refusing to persist non-run path: $RUN_REL" >&2; exit 2 ;;
esac

git config user.name 'github-actions[bot]'
git config user.email '41898282+github-actions[bot]@users.noreply.github.com'
git fetch origin "$BRANCH"
ORIGIN_BEFORE="$(git rev-parse "origin/$BRANCH")"

# A run key may be written once.  Reruns get a new GITHUB_RUN_ATTEMPT and thus
# a different directory.  This prevents the workflow itself from overwriting a
# previously published trace directory.
if git cat-file -e "origin/$BRANCH:$RUN_REL" 2>/dev/null; then
  echo "append-only collision: $RUN_REL already exists on origin/$BRANCH" >&2
  exit 73
fi

{
  echo "persist_started_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "branch=$BRANCH"
  echo "origin_head_before=$ORIGIN_BEFORE"
  echo "workflow_run_id=${GITHUB_RUN_ID:-local}"
  echo "workflow_run_attempt=${GITHUB_RUN_ATTEMPT:-local}"
  echo "workflow_sha=${GITHUB_SHA:-$(git rev-parse HEAD)}"
  echo "force_push=false"
  echo "append_only=true"
} >> "$RUN_DIR/persistence.txt"

# Tamper-evident content inventory.  Git history supplies the outer tree/commit
# identity; this manifest makes the run directory independently hashable.
(
  cd "$RUN_DIR"
  find . -type f ! -name manifest.sha256 -print0 \
    | LC_ALL=C sort -z \
    | xargs -0 -r sha256sum
) > "$RUN_DIR/manifest.sha256"

git add -f "$RUN_REL"
if git diff --cached --quiet; then
  echo 'no new trace files to persist'
  exit 0
fi

git commit -m "o11y: persist unified E2E run ${GITHUB_RUN_ID:-local}/${GITHUB_RUN_ATTEMPT:-local}"

for attempt in 1 2 3 4 5 6 7 8; do
  git fetch origin "$BRANCH"
  if git cat-file -e "origin/$BRANCH:$RUN_REL" 2>/dev/null; then
    echo "append-only collision appeared while pushing: $RUN_REL" >&2
    exit 73
  fi
  if ! git rebase "origin/$BRANCH"; then
    git rebase --abort || true
    echo "trace rebase failed on attempt $attempt" >&2
    sleep "$attempt"
    continue
  fi
  if git push origin "HEAD:$BRANCH"; then
    echo "trace persistence push succeeded on attempt $attempt"
    exit 0
  fi
  echo "trace persistence push raced on attempt $attempt" >&2
  sleep "$attempt"
done

echo 'unable to persist .o11y trace commit without force-push' >&2
exit 1
