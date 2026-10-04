#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/generated/cakeml-unified-e2e"
CACHE="$ROOT/.aegis/cakeml-controller"
VERSION="v3479"
ARCHIVE="cake-x64-64.tar.gz"
URL="https://github.com/CakeML/cakeml/releases/download/$VERSION/$ARCHIVE"
SHA256="e110bfcba19d6524ee4748608a67a275647445a048928cf623c2c9a973e31c9a"

mkdir -p "$OUT" "$CACHE"

if [[ -n "${CAKEML_RELEASE_DIR:-}" ]]; then
  RELEASE="$CAKEML_RELEASE_DIR"
else
  ARCHIVE_PATH="$CACHE/$ARCHIVE"
  if [[ ! -s "$ARCHIVE_PATH" ]]; then
    curl --fail --location --retry 4 --output "$ARCHIVE_PATH" "$URL"
  fi
  printf '%s  %s\n' "$SHA256" "$ARCHIVE_PATH" | sha256sum --check -
  RELEASE="$CACHE/release"
  rm -rf "$RELEASE"
  mkdir -p "$RELEASE"
  tar -xzf "$ARCHIVE_PATH" -C "$RELEASE" --strip-components=1
fi

for f in Makefile basis_ffi.c cake.S; do
  [[ -s "$RELEASE/$f" ]] || { echo "missing CakeML release file: $RELEASE/$f" >&2; exit 1; }
done

BUILD="$CACHE/build"
rm -rf "$BUILD"
mkdir -p "$BUILD"
cp "$RELEASE/Makefile" "$RELEASE/basis_ffi.c" "$RELEASE/cake.S" "$BUILD/"
cp "$ROOT/cakeml/unified-e2e/UnifiedE2EPipeline.cml" "$BUILD/unified_e2e.cml"
cat "$ROOT/cakeml/unified-e2e/e2e_ffi.c" >> "$BUILD/basis_ffi.c"

(
  cd "$BUILD"
  make unified_e2e.cake
)

install -m 0755 "$BUILD/unified_e2e.cake" "$OUT/unified_e2e.cake"
sha256sum "$OUT/unified_e2e.cake" > "$OUT/unified_e2e.cake.sha256"
printf '%s\n' "$VERSION" > "$OUT/controller-cakeml-release.txt"
