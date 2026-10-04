#!/usr/bin/env python3
"""Hermetic Dagger checks for the Aegis-on-GitLab integration layer."""
from __future__ import annotations

import argparse
import asyncio
import json
from pathlib import Path
import sys

import dagger

def ruby_files(source: Path) -> list[str]:
    return sorted(
        path.relative_to(source).as_posix()
        for path in (source / "gitlab" / "overlay").glob("**/*.rb")
        if path.is_file()
    )


async def run(source: Path) -> dict:
    source = source.resolve(strict=True)
    async with dagger.Connection(dagger.Config(log_output=sys.stderr)) as client:
        src = client.host().directory(
            str(source),
            exclude=[".git", ".aegis", ".metarocq", "__pycache__"],
        )

        python = (
            client.container()
            .from_("python:3.12-alpine")
            .with_directory("/src", src)
            .with_workdir("/src")
        )
        overlay = await python.with_exec(
            ["python3", "-B", "gitlab/assemble.py", "--check-overlay"]
        ).stdout()
        await python.with_exec(
            [
                "python3",
                "-m",
                "py_compile",
                "gitlab/assemble.py",
                "gitlab/materialize.py",
                "dagger/supervision.py",
            ]
        ).sync()

        ruby = (
            client.container()
            .from_("ruby:3.3-alpine")
            .with_directory("/src", src)
            .with_workdir("/src")
        )
        checked = []
        for path in ruby_files(source):
            await ruby.with_exec(["ruby", "-c", path]).sync()
            checked.append(path)

        return {
            "schema": 1,
            "overlay": json.loads(overlay),
            "ruby_syntax": checked,
            "claim": "hermetic syntax/structure checks only; not formal proof acceptance",
        }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=Path("."))
    args = parser.parse_args()
    print(
        json.dumps(
            asyncio.run(run(args.source)), sort_keys=True, separators=(",", ":")
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
