#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

GEN="$ROOT/generated/peregrine-selfhost"
EXTRACT="$GEN/checked-extraction"
PEREGRINE_SRC="$ROOT/.aegis/references/peregrine"

[[ -d "$EXTRACT" ]] || {
  echo "checked extraction directory missing: $EXTRACT" >&2
  exit 2
}
[[ -d "$PEREGRINE_SRC" ]] || {
  echo "pinned Peregrine checkout missing: $PEREGRINE_SRC" >&2
  exit 2
}
command -v dune >/dev/null
command -v ocamlc >/dev/null

# Peregrine's extraction configuration intentionally refers to these two
# handwritten conversion helpers.  Copy the exact pinned implementations into
# the generated build directory instead of maintaining a fork.
cp "$PEREGRINE_SRC/src/printC/caml_byte.ml" "$EXTRACT/"
cp "$PEREGRINE_SRC/src/printC/caml_bytestring.ml" "$EXTRACT/"

cat > "$EXTRACT/dune-project" <<'EOF'
(lang dune 3.17)
(name peregrine_checked_cakeml_producer)
EOF

cat > "$EXTRACT/dune" <<'EOF'
(executable
 (name checked_cakeml_driver)
 (libraries
  rocq-primitive.uint63
  rocq-primitive.float64
  rocq-primitive.pstring
  str))
EOF

cat > "$EXTRACT/checked_cakeml_driver.ml" <<'EOF'
let read_file path =
  let ic = open_in_bin path in
  let len = in_channel_length ic in
  let s = really_input_string ic len in
  close_in ic;
  s

let write_file path s =
  let oc = open_out_bin path in
  output_string oc s;
  flush oc;
  close_out oc

let fail_bytestring prefix e =
  prerr_endline (prefix ^ Caml_bytestring.caml_string_of_bytestring e);
  exit 2

let () =
  if Array.length Sys.argv <> 3 then begin
    prerr_endline "usage: checked_cakeml_driver INPUT.ast OUTPUT.cakeml";
    exit 64
  end;
  let source =
    Sys.argv.(1)
    |> read_file
    |> Caml_bytestring.bytestring_of_caml_string
  in
  match
    PeregrineCheckedCakeMLProducer.checked_lambdabox_to_serialized_cakeml
      [] source
  with
  | ResultMonad.Ok (_names, code) ->
      write_file Sys.argv.(2)
        (Caml_bytestring.caml_string_of_bytestring code)
  | ResultMonad.Err e ->
      fail_bytestring "checked CakeML producer failed: " e
EOF

(
  cd "$EXTRACT"
  dune build ./checked_cakeml_driver.exe
)

BIN="$GEN/checked-cakeml-producer"
cp "$EXTRACT/_build/default/checked_cakeml_driver.exe" "$BIN"
chmod +x "$BIN"
"$BIN" --help >/dev/null 2>&1 || true

printf '%s\n' "$BIN"
