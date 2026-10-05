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


def materialize(log: str, manifest: str) -> tuple[str, dict]:
    match = re.search(r"Definition peregrine_modules\s*:.*?\[(.*?)\]\.",
                      manifest, re.S)
    if not match:
        raise ValueError("Peregrine module manifest is missing")
    expected = re.findall(r'"([^"\n]+)"%bs', match[1])
    if not expected or len(set(expected)) != len(expected):
        raise ValueError("Peregrine module manifest is empty or duplicated")
    modules, roots, seen, exports = [], [], set(), {}
    current, complete = None, False
    for line in log.splitlines():
        line = line.strip()
        if line.startswith(MODULE):
            module = line[len(MODULE):]
            if complete or current is not None or not NAME.fullmatch(module) or module in modules:
                raise ValueError("invalid or repeated module inventory entry")
            modules.append(module)
            current = module
            exports[module] = []
        elif line.startswith(ROOT):
            fields = line[len(ROOT):].split()
            if complete or current is None or len(fields) != 2:
                raise ValueError("malformed replay root or missing module marker")
            kind, name = fields
            if kind not in ("CONST", "IND") or not NAME.fullmatch(name):
                raise ValueError("unsupported replay root; no declaration is omitted")
            exports[current].append({"kind": kind, "name": name})
            if name not in seen:
                seen.add(name)
                roots.append(name)
        elif line.startswith(DONE):
            fields = line[len(DONE):].split()
            if complete or len(fields) != 2 or fields[0] != current:
                raise ValueError("unmatched module completion marker")
            if not fields[1].isdecimal() or int(fields[1]) != len(exports[current]):
                raise ValueError("module declaration inventory is incomplete")
            current = None
        elif line == COMPLETE:
            if complete or current is not None:
                raise ValueError("invalid inventory completion marker")
            complete = True
        elif line.startswith("PEREGRINE_REPLAY_"):
            raise ValueError("malformed replay inventory record")
    if not complete or current is not None:
        raise ValueError("truncated replay inventory")
    if modules != expected:
        raise ValueError("module inventory does not exactly cover the pinned manifest")
    if not roots:
        raise ValueError("empty replay root inventory")
    lines = [
        "(* Generated from MetaRocq tmQuoteModule output; do not edit. *)",
        "From MetaRocqRs.PeregrineSelfHost Require Import PeregrineLoadAll.",
        "",
    ]
    # Small chunks avoid one exceptionally deep term while sharing a single
    # recursive quotation environment. Do not reduce these definitions before
    # quoting: their computational result is unit, their syntax retains roots.
    chunks = []
    for start in range(0, len(roots), 64):
        chunk = f"peregrine_replay_roots_{start // 64:04d}"
        chunks.append(chunk)
        lines.append(f"Definition {chunk} : unit :=")
        for name in roots[start:start + 64]:
            lines.append(f"  let _ := @{name} in")
        lines.extend(["  tt.", ""])
    lines.append("Definition peregrine_all_declarations_root : unit :=")
    lines.extend(f"  let _ := {chunk} in" for chunk in chunks)
    lines.append("  tt.")
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
    args = parser.parse_args()
    source, receipt = materialize(args.log.read_text(), args.manifest.read_text())
    args.output_dir.mkdir(parents=True, exist_ok=True)
    (args.output_dir / "PeregrineReplayAllGlobals.v").write_text(source)
    (args.output_dir / "replay-root-inventory.json").write_text(
        json.dumps(receipt, indent=2) + "\n")
    print(json.dumps({"module_count": receipt["module_count"],
                      "unique_declaration_roots": receipt["unique_declaration_roots"]}))


if __name__ == "__main__":
    main()
