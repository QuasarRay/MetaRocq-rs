#!/usr/bin/env bash

# HOL's logical filenames differ from the physical Poly/ML output paths.
# Reject ambiguity rather than selecting a potentially stale copy.
hol4_artifact_path() {
  local logical="$1"
  local physical="$(dirname "$logical")/.hol/objs/$(basename "$logical")"
  if [[ -s "$physical" && -s "$logical" ]]; then
    printf 'Ambiguous HOL artifact: %s and %s\n' "$logical" "$physical" >&2
    return 1
  elif [[ -s "$physical" ]]; then
    printf '%s\n' "$physical"
  elif [[ -s "$logical" ]]; then
    printf '%s\n' "$logical"
  else
    printf 'Missing HOL artifact: %s\n' "$logical" >&2
    return 1
  fi
}
