#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
GEN="$ROOT/generated/peregrine-selfhost"
mkdir -p "$GEN"
rm -f "$GEN/producer-inputs.sha256"

compile_rocq() {
  local source="${@: -1}"
  local key
  key="$(printf '%s' "$source" | sha256sum | cut -c1-12)"
  local obs="$GEN/compilations/$key"
  mkdir -p "$obs"
  printf '%s\n' "$source" > "$obs/source.txt"
  printf 'BEGIN Rocq compile: %s\n' "$source"
  set +e
  /usr/bin/time -v -o "$obs/time-memory.txt" rocq compile "$@" \
    2>&1 | tee "$obs/stdout-stderr.log"
  local result=("${PIPESTATUS[@]}")
  set -e
  local rc="${result[0]}"
  [[ "$rc" -ne 0 || "${result[1]}" -eq 0 ]] || rc="${result[1]}"
  printf 'exit=%s\n' "$rc" > "$obs/status.txt"
  printf 'END Rocq compile: %s exit=%s\n' "$source" "$rc"
  return "$rc"
}

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
compile_rocq "${Q0[@]}" metatheory/original-selfhost/PCUICModuleManifest.v
compile_rocq "${Q0[@]}" metatheory/original-selfhost/SelfSnapshot.v
compile_rocq "${Q0[@]}" metatheory/original-selfhost/DeclarationReplayInventory.v

Q=(
  -Q metatheory/original-selfhost MetaRocqRs.OriginalSelfHost
  -Q metatheory/peregrine-selfhost MetaRocqRs.PeregrineSelfHost
  -Q generated/peregrine-selfhost/replay-roots MetaRocqRs.PeregrineGenerated
)
mkdir -p "$GEN/replay-roots"

# Reuse the previously formalized checked frontend/compiler components.  These
# are compiled here only so the executable adapter below cannot silently drift
# away from the exact source on this branch.
for f in \
  EmbeddedPeregrine.v \
  CandidateCakeMLCompiler.v \
  EAstSupportedFragment.v \
  CakeMLNoRaise.v \
  CheckedCandidateCakeML.v
do
  compile_rocq "${Q[@]}" "metatheory/original-selfhost/$f"
done

compile_rocq "${Q[@]}" \
  metatheory/peregrine-selfhost/PeregrineCheckedCakeMLProducer.v

rm -rf "$GEN/checked-extraction"
mkdir -p "$GEN/checked-extraction"
compile_rocq "${Q[@]}" \
  metatheory/peregrine-selfhost/PeregrineCheckedCakeMLExtraction.v
bash tools/build_checked_cakeml_producer.sh

for f in \
  PeregrineSourceManifest.v \
  PeregrineLoadAll.v \
  PeregrineSnapshot.v \
  MaterializePeregrineSnapshot.v \
  PeregrineProofCorpus.v
do
  compile_rocq "${Q[@]}" "metatheory/peregrine-selfhost/$f"
done

# Rocq/MetaRocq enumerates every module declaration. The renderer only emits
# those exact references; it never chooses theorem names from source text.
compile_rocq "${Q[@]}" \
  metatheory/peregrine-selfhost/PeregrineReplayRootInventory.v \
  2>&1 | tee "$GEN/replay-roots/module-inventory.log"
python3 tools/materialize_peregrine_replay_roots.py \
  "$GEN/replay-roots/module-inventory.log" \
  --manifest metatheory/peregrine-selfhost/PeregrineSourceManifest.v \
  --output-dir "$GEN/replay-roots"
compile_rocq "${Q[@]}" "$GEN/replay-roots/PeregrineReplayAllGlobals.v"

for f in PeregrineRuntimeReplay.v PeregrineSelfHostEntrypoint.v ExtractPeregrineSelfHost.v
do
  compile_rocq "${Q[@]}" "metatheory/peregrine-selfhost/$f"
done

AST="$GEN/peregrine-selfhost.ast"
test -s "$AST"
sha256sum "$AST" | tee "$GEN/peregrine-selfhost.ast.sha256"

CAKEML="$GEN/peregrine-selfhost.cakeml"
peregrine cakeml "$AST" -o "$CAKEML"
test -s "$CAKEML"
sha256sum "$CAKEML" | tee "$GEN/peregrine-selfhost.cakeml.sha256"

CHECKED_CAKEML="$GEN/peregrine-selfhost.checked.cakeml"
"$GEN/checked-cakeml-producer" "$AST" "$CHECKED_CAKEML"
test -s "$CHECKED_CAKEML"
sha256sum "$CHECKED_CAKEML" | tee "$GEN/peregrine-selfhost.checked.cakeml.sha256"

if ! cmp -s "$CAKEML" "$CHECKED_CAKEML"; then
  {
    echo "BLOCKED: native Peregrine CakeML and checked-adapter CakeML differ."
    sha256sum "$CAKEML" "$CHECKED_CAKEML"
  } | tee "$GEN/checked-native-cakeml-mismatch.txt" >&2
  exit 43
fi
printf 'byte-identical\n' > "$GEN/checked-native-cakeml-equality.txt"

# Bind reusable producer outputs to their actual source recipe. This is a
# provenance receipt; later proof replay and HOL4 semantic gates still apply.
{
  find metatheory/original-selfhost metatheory/peregrine-selfhost \
    "$GEN/replay-roots" -maxdepth 1 -type f -name '*.v' -print0
  printf '%s\0' spec/toolchain.lock.json \
    tools/peregrine_selfhost_pipeline.sh tools/build_checked_cakeml_producer.sh \
    tools/materialize_peregrine_replay_roots.py \
    "$AST" "$CAKEML" "$CHECKED_CAKEML" \
    "$GEN/checked-native-cakeml-equality.txt"
} | sort -z | xargs -0 sha256sum > "$GEN/producer-inputs.sha256"

cat > "$GEN/producer-boundary.txt" <<'EOF'
The prebuilt Rocq/MetaRocq and Peregrine executables produced these artifacts.
Their process success is not semantic evidence.
The native Peregrine CakeML candidate is independently regenerated by an
extracted adapter that reuses the repository's existing checked
prepare_cakeml/PAst_to_EAst/checked_candidate_compile_past path and the pinned
CakeML Serialize_module printer.  The pipeline requires the two serialized
CakeML files to be byte-identical before continuing.  This equality is
engineering/provenance evidence only; it does not replace the missing semantic
preservation theorem.
The extracted self-host entrypoint contains an executable replay command whose
runtime data includes a dependency-closed pre-erasure quotation of Peregrine.
That replay uses MetaRocq.Template.Checker as a diagnostic execution engine;
upstream documents that checker as fuel-bounded and unverified. Its success is
therefore not semantic evidence. Publication still requires a HOL4 theorem
binding the exact source snapshot, retained proof/replay corpus, exact
LambdaBox artifact, exact CakeML program, exact in-logic CakeML compilation,
and exact machine-code image.
EOF
