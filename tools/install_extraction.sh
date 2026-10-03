#!/usr/bin/env bash
# Cache is an acceleration only. Always let opam reconcile the pinned packages.
set -euo pipefail
export OPAMROOT="$PWD/.aegis/opam-root"
export OPAMYES=1
export OPAMJOBS=2
if [ ! -f "$OPAMROOT/config" ]; then
  opam init --bare --disable-sandboxing -y default https://opam.ocaml.org
fi
if [ ! -d .aegis/opam/_opam ]; then
  opam switch create .aegis/opam ocaml-base-compiler.4.14.2 -y --jobs=2
fi
opam repository add rocq-released https://rocq-prover.org/opam/released --switch .aegis/opam -y
for package in .aegis/references/metarocq/rocq-metarocq-*.opam; do
  name="$(basename "$package" .opam)"
  opam pin add --switch .aegis/opam --no-action -y "$name.1.5.1" .aegis/references/metarocq
done
opam pin add --switch .aegis/opam --no-action -y rocq-peregrine .aegis/references/peregrine
opam install --switch .aegis/opam -y rocq-peregrine rocq-core.9.1.1 rocq-stdlib.9.0.0 --jobs=2
opam switch export --switch .aegis/opam .aegis/opam-switch.export
