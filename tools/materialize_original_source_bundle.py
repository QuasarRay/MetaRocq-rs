#!/usr/bin/env python3
"""Vendor exact source worktrees within MetaRocq and index every tracked file.

This tool transports source, build module names, and hashes. Rocq enumerates
declarations; no Python code selects, translates, or accepts a proof.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import shlex
import subprocess

ROOT = Path(__file__).resolve().parents[1]
LOCK = ROOT / "spec/original-three-projects.lock.json"
NAME = re.compile(r"[A-Za-z_][A-Za-z0-9_']*(?:\.[A-Za-z_][A-Za-z0-9_']*)*")


def git(path: Path, *args: str) -> str:
    return subprocess.check_output(["git", "-C", str(path), *args], text=True).strip()


def unredirected(path: Path) -> None:
    if any(p.is_symlink() for p in [path, *path.parents]):
        raise ValueError(f"redirected source/worktree path: {path}")


def check(path: Path, commit: str) -> None:
    unredirected(path)
    if Path(git(path, "rev-parse", "--show-toplevel")).resolve() != path.resolve():
        raise ValueError(f"not an independent worktree: {path}")
    if git(path, "rev-parse", "HEAD") != commit:
        raise ValueError(f"source pin mismatch: {path}")
    if git(path, "status", "--porcelain", "--untracked-files=no"):
        raise ValueError(f"tracked source changes; refusing to overwrite: {path}")


def worktree(source: Path, target: Path, pin: dict, fetch: bool) -> None:
    if not re.fullmatch(r"[0-9a-f]{40}", pin["commit"]):
        raise ValueError("source requires an exact commit")
    unredirected(source)
    unredirected(target)
    if source.resolve() == target.resolve():
        raise ValueError("vendored worktree must be separate from the reference")
    if not source.exists():
        if not fetch:
            raise ValueError(f"missing reference {source}; use --fetch")
        source.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["git", "init", "-q", str(source)], check=True)
        subprocess.run(["git", "-C", str(source), "remote", "add", "origin", pin["repository"]], check=True)
        subprocess.run(["git", "-C", str(source), "fetch", "--depth", "1", "origin", pin["commit"]], check=True)
        subprocess.run(["git", "-C", str(source), "checkout", "--detach", "FETCH_HEAD"], check=True)
    check(source, pin["commit"])
    if not target.exists():
        target.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["git", "-C", str(source), "worktree", "add", "--detach", str(target), pin["commit"]], check=True)
    check(target, pin["commit"])


def module_roots(path: Path, pin: dict) -> list[tuple[Path, str]]:
    roots = [(Path(p), n) for p, n in pin.get("module_roots", {}).items()]
    pattern = pin.get("module_projects")
    if pattern:
        for project in sorted(path.rglob(pattern)):
            if project.name not in ("_RocqProject", "_RocqProject.in", "_CoqProject"):
                continue
            tokens = shlex.split(project.read_text(), comments=True)
            for i, token in enumerate(tokens):
                if token in ("-Q", "-R"):
                    if i + 2 >= len(tokens):
                        raise ValueError(f"truncated module mapping in {project}")
                    physical = (project.parent / tokens[i + 1]).resolve()
                    roots.append((physical.relative_to(path.resolve()), tokens[i + 2]))
    for physical, logical in roots:
        if physical.is_absolute() or ".." in physical.parts or not NAME.fullmatch(logical):
            raise ValueError("unsafe physical/logical module mapping")
    return sorted(set(roots), key=lambda r: (-len(r[0].parts), str(r[0]), r[1]))


def inventory(path: Path, pin: dict) -> dict:
    roots = module_roots(path, pin)
    files, modules, uncovered = [], {}, []
    # NUL-separated Git paths avoid treating embedded whitespace as records.
    entries = subprocess.check_output(["git", "-C", str(path), "ls-tree", "-rz", "HEAD"])
    for record in entries.split(b"\0"):
        if not record:
            continue
        metadata, raw_name = record.split(b"\t", 1)
        mode, kind, blob = metadata.decode().split()
        name = raw_name.decode("utf-8")
        if kind != "blob" or mode not in ("100644", "100755", "120000"):
            raise ValueError(f"unmaterialized submodule/unsupported tracked entry: {name}")
        file = path / name
        if mode == "120000":
            if not file.is_symlink():
                raise ValueError(f"missing tracked symlink: {file}")
            payload = str(file.readlink()).encode()
        else:
            if not file.is_file() or file.is_symlink():
                raise ValueError(f"missing/redirected tracked file: {file}")
            payload = file.read_bytes()
        observed_blob = hashlib.sha1(b"blob " + str(len(payload)).encode() + b"\0" + payload).hexdigest()
        if observed_blob != blob:
            raise ValueError(f"physical source bytes differ from the pin: {file}")
        language = "Gallina" if name.endswith(".v") else "OCaml" if Path(name).suffix in (".ml", ".mli") else "other"
        entry = {"path": name, "mode": mode, "git_blob": blob, "sha256": hashlib.sha256(payload).hexdigest(), "language": language}
        if language == "Gallina":
            matches = []
            for physical, logical in roots:
                try:
                    relative = Path(name).relative_to(physical).with_suffix("")
                except ValueError:
                    continue
                module = logical + "." + ".".join(relative.parts)
                if NAME.fullmatch(module):
                    matches.append(module)
            if matches:
                module = matches[0]
                if module in modules and modules[module] != name:
                    raise ValueError(f"two source files claim one module: {module}")
                modules[module] = name
                entry["module"] = module
            else:
                uncovered.append(name)
        files.append(entry)
    return {"commit": pin["commit"], "tree": git(path, "rev-parse", "HEAD^{tree}"), "destination": pin["destination"],
            "files": files, "modules": modules, "unmapped_gallina": uncovered,
            "counts": {"tracked": len(files), **{k: sum(f["language"] == k for f in files) for k in ("Gallina", "OCaml", "other")}}}


def materialize(lock: dict, references: Path, output: Path, fetch: bool = False) -> dict:
    output = output.absolute()
    repositories = lock["repositories"]
    if repositories["metarocq"]["destination"] != ".":
        raise ValueError("MetaRocq must be the containing source tree")
    observed, all_modules = {}, {}
    for name, pin in repositories.items():
        relative = Path(pin["destination"])
        if relative.is_absolute() or ".." in relative.parts:
            raise ValueError("source destination escapes the bundle")
        source, target = references / name, output / relative
        worktree(source, target, pin, fetch)
        project = inventory(target, pin)
        for module, source_file in project["modules"].items():
            if module in all_modules:
                raise ValueError(f"module namespace collision: {module}")
            all_modules[module] = {"project": name, "path": source_file}
        observed[name] = project
    if git(output, "ls-tree", "HEAD", "vendor"):
        raise ValueError("pinned MetaRocq already owns the vendor destination")
    modules = sorted(all_modules)
    manifest = ["(* Generated from pinned build load paths; theorem enumeration remains in Rocq. *)",
                "From Stdlib Require Import List.", "From MetaRocq.Utils Require Import utils.",
                "From MetaRocq.Common Require Import Kernames.", "Import ListNotations.",
                "Definition unified_modules : list qualid := ["]
    manifest += [f'  "{m}"%bs' + (";" if i + 1 < len(modules) else "") for i, m in enumerate(modules)]
    manifest += ["].", f"Definition unified_expected_modules : nat := {len(modules)}."]
    unmapped = sum(len(p["unmapped_gallina"]) for p in observed.values())
    manifest += [f"Definition unified_unmapped_source_count : nat := {unmapped}."]
    generated = output / "selfhost/generated"
    generated.mkdir(parents=True, exist_ok=True)
    rendered = {"UnifiedModuleManifest.v": "\n".join(manifest) + "\n",
                "UnifiedLoadAll.v": "(* Every mapped module; unavailable artifacts block compilation. *)\n" + "".join(f"Require Import {m}.\n" for m in modules)}
    for name, content in rendered.items():
        destination = generated / name
        if destination.exists() and destination.read_text() != content:
            raise ValueError(f"unexpected generated source; refusing to overwrite: {destination}")
        destination.write_text(content)
    result = {"schema": 1, "source_bundle": str(output), "repositories": observed,
              "module_count": len(modules), "modules": all_modules,
              "unmapped_gallina_count": sum(len(p["unmapped_gallina"]) for p in observed.values()),
              "generated_sources": {n: hashlib.sha256(c.encode()).hexdigest() for n, c in rendered.items()},
              "claim": "complete physical source inventory; NOT complete proof replay or machine correctness"}
    receipt = generated / "source-inventory.json"
    content = json.dumps(result, indent=2) + "\n"
    if receipt.exists() and receipt.read_text() != content:
        raise ValueError("existing bundle receipt differs; preserve it and use a new recipe address")
    receipt.write_text(content)
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--references", type=Path, default=ROOT / ".aegis/references")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--fetch", action="store_true")
    parser.add_argument("--evidence-dir", type=Path)
    args = parser.parse_args()
    lock = json.loads(LOCK.read_text())
    toolchain = json.loads((ROOT / "spec/toolchain.lock.json").read_text())
    for name in ("metarocq", "peregrine"):
        if any(lock["repositories"][name][k] != toolchain["repositories"][name][k] for k in ("repository", "commit")):
            raise ValueError("bundle and existing bootstrap pins differ")
    recipe_inputs = [LOCK, Path(__file__), ROOT / "tools/materialize_peregrine_replay_roots.py",
                     ROOT / "tools/build_original_three_project_lambdabox.sh"]
    recipe_inputs += [ROOT / "metatheory/original-selfhost" / n for n in
                     ("DeclarationReplayInventory.v", "UnifiedReplayRootInventory.v",
                      "UnifiedRetainedReplay.v", "ExtractUnifiedRetainedReplay.v")]
    recipe_hash = hashlib.sha256()
    for path in recipe_inputs:
        recipe_hash.update(str(path.relative_to(ROOT)).encode() + b"\0" + path.read_bytes() + b"\0")
    recipe = recipe_hash.hexdigest()[:16]
    result = materialize(lock, args.references, args.output or ROOT / f".aegis/derived/metarocq-three-projects-{recipe}", args.fetch)
    if args.evidence_dir:
        evidence = args.evidence_dir / recipe
        evidence.mkdir(parents=True, exist_ok=True)
        generated = Path(result["source_bundle"]) / "selfhost/generated"
        for name in ("source-inventory.json", "UnifiedModuleManifest.v", "UnifiedLoadAll.v"):
            destination = evidence / name
            content = (generated / name).read_bytes()
            if destination.exists() and destination.read_bytes() != content:
                raise ValueError("evidence differs; refusing to replace an earlier checkpoint")
            destination.write_bytes(content)
        (args.evidence_dir / "latest.json").write_text(json.dumps({"recipe": recipe, "source_bundle": result["source_bundle"],
            "inventory": str(evidence / "source-inventory.json")}, indent=2) + "\n")
    print(json.dumps({"source_bundle": result["source_bundle"], "module_count": result["module_count"],
                      "unmapped_gallina_count": result["unmapped_gallina_count"],
                      "repositories": {n: p["counts"] for n, p in result["repositories"].items()}, "claim": result["claim"]}))


if __name__ == "__main__":
    main()
