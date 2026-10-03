#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "usage: $0 THEORY [WORKDIR]" >&2
  exit 64
fi

theory="$1"
workdir="${2:-.}"
if [[ ! "$theory" =~ ^[A-Za-z][A-Za-z0-9_]*$ ]]; then
  echo "invalid HOL4 theory name: $theory" >&2
  exit 64
fi
: "${HOLDIR:?HOLDIR must point at a built HOL4 checkout}"
: "${HOL4_TACTICTOE_CACHE:?HOL4_TACTICTOE_CACHE must be explicit}"

mkdir -p "$HOL4_TACTICTOE_CACHE"
workdir="$(cd "$workdir" && pwd)"
driver="$(mktemp)"
trap 'rm -f "$driver"' EXIT

cat >"$driver" <<EOF
load "tttUnfold";
open tttUnfold;
load "${theory}Theory";
ttt_record_thy "${theory}";
OS.Process.exit OS.Process.success;
EOF

(
  cd "$workdir"
  "$HOLDIR/bin/hol" --zero <"$driver"
)

manifest="$HOL4_TACTICTOE_CACHE/ttt_tacdata/MANIFEST"
if [[ ! -s "$manifest" ]]; then
  echo "TacticToe did not publish a manifest: $manifest" >&2
  exit 1
fi
sha256sum "$manifest"
