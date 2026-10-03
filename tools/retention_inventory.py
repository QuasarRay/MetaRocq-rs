#!/usr/bin/env python3
"""Inventory every pinned source file and generate additive module-quotation drivers.

This uses upstream build mappings, not a regex approximation to the Gallina
declaration grammar. Actual declarations are enumerated by tmQuoteModule in Rocq.
Inventory entries never claim successful extraction or proof transport.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import subprocess

from bootstrap import ROOT, check_source


def inventory():
    lock = json.loads((ROOT / "spec/toolchain.lock.json").read_text())
    pin = lock["repositories"]["metarocq"]
    source = check_source("metarocq", pin)
    names = subprocess.check_output(["git", "ls-files", "-z"], cwd=source).decode().split("\0")
    names = sorted(filter(None, names))
    mappings = []
    for name in names:
        if Path(name).name in {"_RocqProject", "_RocqProject.in"}:
            for local, logical in re.findall(r"^-(?:R|Q)\s+(\S+)\s+(\S+)", (source / name).read_text(), re.M):
                directory = ((source / name).parent / local).resolve()
                directory.relative_to(source)  # reject mappings outside pinned source
                mappings.append((directory, logical))
    files = []
    for name in names:
        path = source / name
        suffix = path.suffix
        kind = "rocq-module" if suffix == ".v" else (
            "ocaml-plugin" if suffix in {".ml", ".mli", ".mlg", ".mlpack"} else "build-doc-or-asset")
        modules = []
        if suffix == ".v":
            candidates = [(len(directory.parts), logical + "." + ".".join(path.relative_to(directory).with_suffix("").parts))
                          for directory, logical in mappings if path.is_relative_to(directory)]
            if candidates:
                depth = max(d for d, _ in candidates)
                modules = sorted({m for d, m in candidates if d == depth})
        files.append({"path": name, "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                      "kind": kind, "modules": modules})
    return {"schema": 1, "repository": pin["repository"], "commit": pin["commit"],
            "counts": dict(sorted(Counter(f["kind"] for f in files).items())), "files": files,
            "claim": "Complete tracked-file inventory at the pinned commit; NOT complete quotation, extraction, or semantic coverage.",
            "boundaries": [
                "Rocq modules may also contain Ltac, notations, commands and functors: quoting their declarations does not port those facilities.",
                "Module snapshots need explicit dependency-closure, universe/axiom inventories and independent checking.",
                "OCaml plugin code and build assets require separate porting/semantics; none is counted as Rust by inventory membership."]}


def driver(module, data):
    matches = [f for f in data["files"] if module in f["modules"]]
    if len(matches) != 1 or not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)+", module):
        raise ValueError("module must identify exactly one pinned upstream file")
    return f'''(* Generated additive driver for {matches[0]['path']}; never edit upstream. *)
From MetaRocq.Template Require Import All.
From Peregrine.Plugin Require Import Loader.
Require Import Retention {module}.
Import MonadNotation.
MetaRocq Run (snapshot <- retain_module "{module}"%bs;;
              tmDefinition "retained_module_data" snapshot).
Peregrine Extract Typed "module_snapshot.ast" retained_module_data.
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--module", help="generate a module driver instead of the inventory")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    data = inventory()
    if args.module:
        content = driver(args.module, data)
        if args.output is None:
            print(content, end="")
            return
        destination = args.output
    else:
        content = json.dumps(data, indent=2) + "\n"
        destination = args.output or ROOT / "spec/source-inventory.json"
    if args.check:
        if not destination.is_file() or destination.read_text() != content:
            raise ValueError("inventory/driver drift")
    else:
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(content)
    print(json.dumps({"counts": data["counts"], "checked": args.check,
                      "claim": "file coverage only; extraction coverage remains OPEN"}))


if __name__ == "__main__":
    main()
