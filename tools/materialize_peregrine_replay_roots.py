#!/usr/bin/env python3
"""Render every root emitted by the MetaRocq module inventory, without selection.

This is source materialization, not theorem acceptance. The generated unit
definitions contain unreduced let bindings so one opacity-bypassing recursive
quotation visits every exported constant and inductive plus their dependencies.
The quoted program is ordinary Type-valued data in the extracted runtime.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re

NAME = re.compile(r"[A-Za-z_][A-Za-z0-9_']*(?:\.[A-Za-z_][A-Za-z0-9_']*)+")
MODULE = "PEREGRINE_REPLAY_MODULE "
DONE = "PEREGRINE_REPLAY_MODULE_DONE "
ROOT = "PEREGRINE_REPLAY_ROOT "
COMPLETE = "PEREGRINE_REPLAY_COMPLETE"


def materialize(log: str, manifest: str, *, module_list: str = "peregrine_modules",
                marker_prefix: str = "PEREGRINE_REPLAY",
                import_module: str = "MetaRocqRs.PeregrineSelfHost.PeregrineLoadAll",
                root_prefix: str = "peregrine", coverage_ledger: bool = False) -> tuple[str, dict]:
    if not re.fullmatch(r"[a-z][a-z0-9_]*", module_list) or not re.fullmatch(r"[a-z][a-z0-9_]*", root_prefix):
        raise ValueError("unsafe generated identifier")
    if not re.fullmatch(r"[A-Z][A-Z0-9_]*", marker_prefix) or not NAME.fullmatch(import_module):
        raise ValueError("unsafe inventory marker/import")
    module_marker = marker_prefix + "_MODULE "
    root_marker = marker_prefix + "_ROOT "
    done_marker = marker_prefix + "_MODULE_DONE "
    complete_marker = marker_prefix + "_COMPLETE"
    match = re.search(r"Definition " + re.escape(module_list) + r"\s*:.*?\[(.*?)\]\.",
                      manifest, re.S)
    if not match:
        raise ValueError("Peregrine module manifest is missing")
    expected = re.findall(r'"([^"\n]+)"%bs', match[1])
    if not expected or len(set(expected)) != len(expected):
        raise ValueError("Peregrine module manifest is empty or duplicated")
    modules, roots, seen, exports = [], [], set(), {}
    root_kinds = {}
    current, complete = None, False
    for line in log.splitlines():
        line = line.strip()
        if line.startswith(module_marker):
            module = line[len(module_marker):]
            if complete or current is not None or not NAME.fullmatch(module) or module in modules:
                raise ValueError("invalid or repeated module inventory entry")
            modules.append(module)
            current = module
            exports[module] = []
        elif line.startswith(root_marker):
            fields = line[len(root_marker):].split()
            if complete or current is None or len(fields) != 2:
                raise ValueError("malformed replay root or missing module marker")
            kind, name = fields
            if kind not in ("CONST", "IND", "ASSUMPTION") or not NAME.fullmatch(name):
                raise ValueError("unsupported replay root; no declaration is omitted")
            if name in root_kinds and root_kinds[name] != kind:
                raise ValueError("contradictory declaration/body classification")
            root_kinds[name] = kind
            exports[current].append({"kind": kind, "name": name})
            if name not in seen:
                seen.add(name)
                roots.append(name)
        elif line.startswith(done_marker):
            fields = line[len(done_marker):].split()
            if complete or len(fields) != 2 or fields[0] != current:
                raise ValueError("unmatched module completion marker")
            if not fields[1].isdecimal() or int(fields[1]) != len(exports[current]):
                raise ValueError("module declaration inventory is incomplete")
            current = None
        elif line == complete_marker:
            if complete or current is not None:
                raise ValueError("invalid inventory completion marker")
            complete = True
        elif line.startswith(marker_prefix + "_"):
            raise ValueError("malformed replay inventory record")
    if not complete or current is not None:
        raise ValueError("truncated replay inventory")
    if modules != expected:
        raise ValueError("module inventory does not exactly cover the pinned manifest")
    if not roots:
        raise ValueError("empty replay root inventory")
    lines = [
        "(* Generated from MetaRocq tmQuoteModule output; do not edit. *)",
        "From " + import_module.rsplit(".", 1)[0] + " Require Import " + import_module.rsplit(".", 1)[1] + ".",
        "",
    ]
    # Small chunks avoid one exceptionally deep term while sharing a single
    # recursive quotation environment. Do not reduce these definitions before
    # quoting: their computational result is unit, their syntax retains roots.
    chunks = []
    for start in range(0, len(roots), 64):
        chunk = f"{root_prefix}_replay_roots_{start // 64:04d}"
        chunks.append(chunk)
        lines.append(f"Definition {chunk} : unit :=")
        for name in roots[start:start + 64]:
            lines.append(f"  let _ := @{name} in")
        lines.extend(["  tt.", ""])
    lines.append(f"Definition {root_prefix}_all_declarations_root : unit :=")
    lines.extend(f"  let _ := {chunk} in" for chunk in chunks)
    lines.append("  tt.")
    if coverage_ledger:
        lines.extend(["", "From Stdlib Require Import List.",
                      "From MetaRocq.Utils Require Import utils.", "Import ListNotations."])
        for kind, suffix in (("CONST", "body_names"), ("IND", "inductive_names"), ("ASSUMPTION", "assumption_names")):
            names = list(dict.fromkeys(e["name"] for es in exports.values() for e in es if e["kind"] == kind))
            lines.append(f"Definition {root_prefix}_expected_{suffix} : list string := [")
            lines.extend(f'  "{name}"%bs' + (";" if i + 1 < len(names) else "") for i, name in enumerate(names))
            lines.append("].")
    source = "\n".join(lines) + "\n"
    receipt = {
        "schema": 1,
        "module_count": len(modules),
        "unique_declaration_roots": len(roots),
        "exports": exports,
        "roots": roots,
        "generated_source_sha256": hashlib.sha256(source.encode()).hexdigest(),
        "claim": "complete emitted root materialization; not checker soundness or machine refinement",
    }
    return source, receipt


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("log", type=Path)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--module-list", default="peregrine_modules")
    parser.add_argument("--marker-prefix", default="PEREGRINE_REPLAY")
    parser.add_argument("--import-module", default="MetaRocqRs.PeregrineSelfHost.PeregrineLoadAll")
    parser.add_argument("--root-prefix", default="peregrine")
    parser.add_argument("--output-name", default="PeregrineReplayAllGlobals.v")
    parser.add_argument("--coverage-ledger", action="store_true")
    args = parser.parse_args()
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*\.v", args.output_name):
        raise ValueError("unsafe generated source filename")
    source, receipt = materialize(args.log.read_text(), args.manifest.read_text(),
                                  module_list=args.module_list, marker_prefix=args.marker_prefix,
                                  import_module=args.import_module, root_prefix=args.root_prefix,
                                  coverage_ledger=args.coverage_ledger)
    args.output_dir.mkdir(parents=True, exist_ok=True)
    (args.output_dir / args.output_name).write_text(source)
    (args.output_dir / "replay-root-inventory.json").write_text(
        json.dumps(receipt, indent=2) + "\n")
    print(json.dumps({"module_count": receipt["module_count"],
                      "unique_declaration_roots": receipt["unique_declaration_roots"]}))


if __name__ == "__main__":
    main()
