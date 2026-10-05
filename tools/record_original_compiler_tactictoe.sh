#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ $# -eq 2 ]] || { echo "usage: $0 THEORY WORKDIR" >&2; exit 64; }
theory="$1"
[[ "$theory" =~ ^[A-Za-z][A-Za-z0-9_]*$ ]] || exit 64
: "${HOLDIR:?Set HOLDIR to the .agents-pinned built HOL4}"
: "${HOL4_TACTICTOE_CACHE:?Select the persistent .agents TacticToe cache}"
workdir="$(cd "$2" && pwd)"
recipe="$ROOT/generated/peregrine-selfhost/hol4/tactictoe-serial-transport"
python3 "$ROOT/tools/materialize_tactictoe_transport.py" --holdir "$HOLDIR" --output "$recipe"
# SML, not shell, owns theorem dependencies, tactic search and cache publication.
# The compatibility launcher is deliberately available only to the serial recorder.
driver="$(mktemp)"
trap 'rm -f "$driver"' EXIT
python3 - "$HOLDIR" "$recipe" "$theory" "$driver" <<'PY'
import json, pathlib, sys
home, recipe, theory, destination = sys.argv[1:]
def guarded(command):
 return 'val _ = (' + command + ') handle e => (print (General.exnMessage e ^ "\\n"); OS.Process.exit OS.Process.failure);'
lines = [guarded('load "tttUnfold"'),
         guarded('use ' + json.dumps(str(pathlib.Path(recipe) / 'smlExecScripts.sml'))),
         # smlOpen captures the launcher when its structure is compiled. Rebind
         # that unchanged source before the unchanged recorder source as well.
         guarded('use ' + json.dumps(str(pathlib.Path(home) / 'src/AI/sml_inspection/smlOpen.sml'))),
         guarded('use ' + json.dumps(str(pathlib.Path(home) / 'src/tactictoe/src/tttUnfold.sml'))),
         guarded('load ' + json.dumps(theory + 'Theory')),
         'val _ = ((tttUnfold.ttt_record_thy ' + json.dumps(theory) + ';',
         '  print "TACTICTOE_RECORD_COMPLETE\\n"; OS.Process.exit OS.Process.success)',
         '  handle e => (print (General.exnMessage e ^ "\\n");',
         '               OS.Process.exit OS.Process.failure));']
pathlib.Path(destination).write_text('\n'.join(lines) + '\n')
PY
mkdir -p "$HOL4_TACTICTOE_CACHE"
(cd "$workdir"; "$HOLDIR/bin/hol" --gcthreads=1 --zero < "$driver")
test -s "$HOL4_TACTICTOE_CACHE/ttt_tacdata/MANIFEST"
sha256sum "$HOL4_TACTICTOE_CACHE/ttt_tacdata/MANIFEST"
