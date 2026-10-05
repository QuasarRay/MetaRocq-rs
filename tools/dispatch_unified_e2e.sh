#!/usr/bin/env bash
set -euo pipefail

repo="${E2E_GITHUB_REPOSITORY:-QuasarRay/MetaRocq-rs}"
workflow="${E2E_GITHUB_WORKFLOW:-unified-cakeml-e2e.yml}"
target_ref="${1:-experiment/cakeml-unified-e2e-03-cachyos-docs}"

case "$target_ref" in
  experiment/cakeml-unified-e2e-*) ;;
  *)
    echo "refusing non-E2E target branch: $target_ref" >&2
    exit 2
    ;;
esac

command -v gh >/dev/null 2>&1 || {
  echo "GitHub CLI (gh) is required" >&2
  exit 127
}

gh auth status >/dev/null

# Dispatch the registered workflow definition from the default branch and pass
# the branch containing the E2E implementation as an explicit input.
gh workflow run "$workflow" \
  --repo "$repo" \
  --ref main \
  --field "target_ref=$target_ref"

echo "dispatched $workflow for $target_ref"
