#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
GEN="$ROOT/generated/peregrine-selfhost"
mkdir -p "$GEN"

export OPAMROOT="${OPAMROOT:-$ROOT/.aegis/opam-root}"
SWITCH="$ROOT/.aegis/opam"

if [[ -x "$SWITCH/_opam/bin/rocq" && -x "$SWITCH/_opam/bin/peregrine" ]]; then
  eval "$(opam env --switch "$SWITCH" --set-switch)"
elif command -v rocq >/dev/null 2>&1 && command -v peregrine >/dev/null 2>&1; then
  :
else
  echo "No matching prebuilt Rocq/MetaRocq/Peregrine toolchain found; rebuilding exact pins." >&2
  bash tools/install_extraction.sh
  eval "$(opam env --switch "$SWITCH" --set-switch)"
fi

command -v rocq
command -v peregrine
rocq -v > "$GEN/rocq-version.txt"
peregrine --help > "$GEN/peregrine-help.txt"

Q0=(-Q metatheory/original-selfhost MetaRocqRs.OriginalSelfHost)
rocq compile "${Q0[@]}" metatheory/original-selfhost/PCUICModuleManifest.v
rocq compile "${Q0[@]}" metatheory/original-selfhost/SelfSnapshot.v

Q=(
  -Q metatheory/original-selfhost MetaRocqRs.OriginalSelfHost
  -Q metatheory/peregrine-selfhost MetaRocqRs.PeregrineSelfHost
)
for f in   PeregrineSourceManifest.v   PeregrineLoadAll.v   PeregrineSnapshot.v   MaterializePeregrineSnapshot.v   PeregrineProofCorpus.v   PeregrineSelfHostEntrypoint.v   ExtractPeregrineSelfHost.v
do
  rocq compile "${Q[@]}" "metatheory/peregrine-selfhost/$f"
done

AST="$GEN/peregrine-selfhost.ast"
test -s "$AST"
sha256sum "$AST" | tee "$GEN/peregrine-selfhost.ast.sha256"

CAKEML="$GEN/peregrine-selfhost.cakeml"
peregrine cakeml "$AST" -o "$CAKEML"
test -s "$CAKEML"
sha256sum "$CAKEML" | tee "$GEN/peregrine-selfhost.cakeml.sha256"

cat > "$GEN/producer-boundary.txt" <<'EOF'
The prebuilt Rocq/MetaRocq and Peregrine executables produced these artifacts.
Their process success is not semantic evidence. Publication requires a HOL4
theorem binding the exact source snapshot, retained proof/replay corpus, exact
LambdaBox artifact, exact CakeML program, exact in-logic CakeML compilation,
and exact machine-code image.
EOF
