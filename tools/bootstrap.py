#!/usr/bin/env python3
"""Use pinned Aegis for MetaRocq candidate extraction and supervision."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
LOCK = ROOT / "spec/toolchain.lock.json"


def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args], text=True).strip()


def check_source(name, pin):
    if name == 'aegis' and (ROOT / '.agents').exists():
        return check_deployment(pin)
    path = ROOT / ".aegis/references" / name
    # Reject redirected source roots; immutable commit checking is not a sandbox.
    for p in [path, *path.parents]:
        if p.is_symlink():
            raise ValueError(f"redirected source root: {p}")
        if p == ROOT:
            break
    if not path.is_dir():
        raise ValueError(f"missing pinned source {name}; run: python tools/bootstrap.py sources")
    if Path(git(path, "rev-parse", "--show-toplevel")).resolve() != path.resolve():
        raise ValueError(f"source is not a repository root: {name}")
    if git(path, "rev-parse", "HEAD") != pin["commit"]:
        raise ValueError(f"wrong pinned revision: {name}")
    if git(path, "status", "--porcelain", "--untracked-files=all"):
        raise ValueError(f"pinned source is dirty: {name}")
    return path


def check_deployment(pin):
    deployment = ROOT / '.agents'
    record = json.loads((ROOT / 'spec/aegis-deployment.json').read_text())
    if deployment.is_symlink() or record['commit'] != pin['commit'] or record['repository'] != pin['repository']:
        raise ValueError('Aegis deployment pin mismatch')
    for name, expected in record['files'].items():
        path = deployment / name
        if Path(name).is_absolute() or '..' in Path(name).parts or any(p.is_symlink() for p in [path, *path.parents]):
            raise ValueError('redirected Aegis deployment')
        if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != expected:
            raise ValueError(f'Aegis deployment bytes differ: {name}')
    return deployment


def sources(lock):
    parent = ROOT / ".aegis/references"
    if (ROOT / ".aegis").is_symlink() or parent.is_symlink():
        raise ValueError("redirected reference destination")
    parent.mkdir(parents=True, exist_ok=True)
    for name, pin in lock["repositories"].items():
        if name == 'aegis' and (ROOT / '.agents').exists():
            check_deployment(pin)
            continue
        path = parent / name
        if not path.exists():
            subprocess.run(["git", "init", "-q", str(path)], check=True)
            subprocess.run(["git", "-C", str(path), "remote", "add", "origin", pin["repository"]], check=True)
            subprocess.run(["git", "-C", str(path), "fetch", "--depth", "1", "origin", pin["commit"]], check=True)
            subprocess.run(["git", "-C", str(path), "checkout", "--detach", "FETCH_HEAD"], check=True)
        check_source(name, pin)
    return {"status": "SOURCES_MATCH", "repositories": {k: v["commit"] for k, v in lock["repositories"].items()},
            "claim": "source identity only; no extraction or proof run"}


def controller(lock):
    path = check_source("aegis", lock["repositories"]["aegis"])
    sys.path.insert(0, str(path / "infra"))
    from agentinfra.metarocq import MetaRocq
    return MetaRocq(ROOT)


def check(lock):
    from sync_instructions import generated
    drift = [name for name, content in generated().items()
             if not (ROOT / name).is_file() or (ROOT / name).read_bytes() != content]
    if drift:
        raise ValueError(f"instruction drift: {drift}")
    app = controller(lock)
    from agentinfra.contracts import authority, digest, read_json, validate_plan, verify_references
    plan = validate_plan(read_json(ROOT / ".metarocq/plan.json"))
    refs = {name: check_source(name, lock["repositories"][name]) for name in ("metarocq", "peregrine")}
    observed = verify_references(plan, refs)
    shared = read_json(ROOT / "spec/upstream.lock.json")
    if shared != authority():
        raise ValueError("target's shared source lock differs from Aegis authority")
    for entry in shared["specifications"]:
        path = refs[entry["repository"]] / entry["path"]
        if digest(path.read_bytes()) != entry["sha256"]:
            raise ValueError(f"changed original specification: {entry['path']}")
    return {"status": "PREFLIGHT_OK", "references": observed,
            "tools": {tool: bool(shutil.which(tool)) for tool in ("rocq", "peregrine", "cargo", "cargo-kani", "Holmake", "z3")},
            "claim": "contract, source and instruction consistency only; not implementation verification"}


def manifest(lock, directory, output):
    source = check_source("kontroli", lock["repositories"]["kontroli"])
    script = source / "scripts/aeneas_hol4_manifest.py"
    expected = lock["reuse"]["kontroli_manifest_sha256"]
    if hashlib.sha256(script.read_bytes()).hexdigest() != expected:
        raise ValueError("Kontroli manifest tool bytes differ")
    generated = Path(directory).resolve(strict=True)
    destination = ROOT / output
    from agentinfra.security import confined_path
    destination = confined_path(ROOT, destination)
    if not any(generated.rglob("*.sml")):
        raise ValueError("no generated HOL4 source; empty manifest is not progress")
    subprocess.run([sys.executable, "-B", str(script), str(generated), str(destination)], check=True)
    return {"status": "INDEXED", "claim": "Kontroli interface discovery only; no refinement proof"}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("sources", "check", "bind", "extract", "verify", "checkpoint", "hol4-smoke", "manifest"))
    parser.add_argument("--timeout", type=int, default=600)
    parser.add_argument("--retry-diagnosis")
    parser.add_argument("--pr", type=int)
    parser.add_argument("--generated")
    parser.add_argument("--output", default=".metarocq/evidence/hol4-symbols.json")
    args = parser.parse_args()
    lock = json.loads(LOCK.read_text())
    if args.command in {'extract', 'verify'}:
        deployed = check_source('aegis', lock['repositories']['aegis'])
        # This independent gate has no status-flag bypass. Existing extraction
        # code and evidence remain available, but cannot advance implementation.
        subprocess.run([sys.executable, '-B', str(deployed / 'pipelines/bootstrap.py'),
                        '--root', str(ROOT), 'gate'], check=True)
    if args.command == "sources":
        result = sources(lock)
    elif args.command == "check":
        result = check(lock)
    else:
        app = controller(lock)
        if args.command == "bind":
            check(lock)
            result = app.freeze(".metarocq/plan.json", {
                name: check_source(name, lock["repositories"][name]) for name in ("metarocq", "peregrine")})
        elif args.command == "extract":
            result = app.extract(args.timeout, retry_diagnosis=args.retry_diagnosis)
        elif args.command == "verify":
            result = app.verify(args.timeout)
        elif args.command == "checkpoint":
            if args.pr is None:
                raise ValueError("checkpoint requires --pr")
            result = app.checkpoint(args.pr)
        elif args.command == "manifest":
            if not args.generated:
                raise ValueError("manifest requires --generated")
            result = manifest(lock, args.generated, args.output)
        else:
            from agentinfra.hol4 import holmake
            result = holmake(ROOT, "formal/hol4", timeout=args.timeout)
            # This theorem qualifies the SMT integration, not MetaRocq refinement.
            result["claim"] = "Z3/HOL4 adapter smoke build only; no MetaRocq source or binary proof"
            output = ROOT / ".metarocq/evidence/hol4-smoke.json"
            output.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))
    if args.command == "extract" and result["status"] != "GENERATED":
        return 2
    if args.command == "verify" and any(r["status"] != "CHECKED" for r in result["results"]):
        return 2
    if args.command == "hol4-smoke" and result["status"] != "CHECKED":
        return 2
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ValueError, OSError, RuntimeError, subprocess.CalledProcessError) as exc:
        print(json.dumps({"status": "BLOCKED", "reason": str(exc), "claim": "no successful verification observation"}), file=sys.stderr)
        raise SystemExit(2)
