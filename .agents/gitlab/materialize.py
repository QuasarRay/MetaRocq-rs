#!/usr/bin/env python3
"""Materialize the pinned GitLab source and assemble Aegis into that Rails tree."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys

HERE = Path(__file__).resolve().parent
LOCK = HERE / "runtime.lock.json"


def run(*argv: str) -> None:
    subprocess.run(list(argv), check=True)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("destination", type=Path)
    parser.add_argument(
        "--source",
        choices=("canonical", "github-mirror"),
        default="canonical",
        help="clone canonical gitlab-foss or the pinned GitHub mirror",
    )
    args = parser.parse_args()
    lock = json.loads(LOCK.read_text())
    destination = args.destination.resolve()
    if destination.exists():
        if any(destination.iterdir()):
            raise ValueError("destination must not exist or must be empty")
    else:
        destination.parent.mkdir(parents=True, exist_ok=True)

    key = "repository" if args.source == "canonical" else "github_mirror"
    remote = lock["host"][key]
    commit = lock["host"]["commit"]
    run("git", "clone", "--filter=blob:none", "--no-checkout", remote, str(destination))
    run("git", "-C", str(destination), "fetch", "--depth=1", "origin", commit)
    run("git", "-C", str(destination), "checkout", "--detach", commit)
    run(sys.executable, str(HERE / "assemble.py"), "--gitlab", str(destination))
    print(
        json.dumps(
            {"gitlab": str(destination), "commit": commit, "assembled": True},
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
