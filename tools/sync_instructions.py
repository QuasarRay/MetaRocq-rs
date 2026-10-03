#!/usr/bin/env python3
"""Copy the canonical project instructions into each tracked source directory."""
import argparse
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def generated():
    canonical = (ROOT / "AGENTS.MD").read_bytes()
    names = subprocess.check_output(["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"], cwd=ROOT).decode().split("\0")
    dirs = {Path(".")}
    for name in filter(None, names):
        dirs.update(Path(name).parents)
    return {(directory / "AGENTS.md").as_posix(): canonical for directory in dirs}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    drift = []
    for name, content in generated().items():
        path = ROOT / name
        if not path.exists() or path.read_bytes() != content:
            drift.append(name)
            if not args.check:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(content)
    print({"instruction_drift": sorted(drift), "check": args.check})
    raise SystemExit(int(args.check and bool(drift)))
