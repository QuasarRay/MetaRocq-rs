#!/usr/bin/env python3
"""Assemble Aegis into an exact pinned GitLab CE/FOSS checkout.

Aegis is an overlay on GitLab's Rails application. This script never creates a
second Rails application and fails closed when the pinned host or patch anchors
drift.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import shutil
import subprocess

HERE = Path(__file__).resolve().parent
AEGIS = HERE.parent
LOCK_PATH = HERE / "runtime.lock.json"
OVERLAY = HERE / "overlay"
OVERLAY_MAP = OVERLAY / "overlay.json"

ROUTES_NEEDLE = "      draw :development\n"
ROUTES_INSERT = ROUTES_NEEDLE + "      draw :aegis\n"
MCP_NEEDLE = "      CUSTOM_TOOLS = {\n"
MCP_ENTRIES = (
    "        'aegis_get_supervision_state' => ::Mcp::Tools::Aegis::GetSupervisionStateService,\n"
    "        'aegis_github_get_state' => ::Mcp::Tools::Aegis::GetGithubStateService,\n"
    "        'aegis_github_mutate' => ::Mcp::Tools::Aegis::MutateGithubService,\n"
)
FORBIDDEN_TARGETS = {
    "Gemfile",
    "config/application.rb",
    "config/environment.rb",
    "config/boot.rb",
}


def git(root: Path, *args: str) -> str:
    return subprocess.check_output(
        ["git", "-C", str(root), *args], text=True, stderr=subprocess.STDOUT
    ).strip()


def load_json(path: Path) -> dict:
    value = json.loads(path.read_text())
    if not isinstance(value, dict):
        raise ValueError(f"expected JSON object: {path}")
    return value


def safe_relative(value: str) -> PurePosixPath:
    path = PurePosixPath(value)
    if path.is_absolute() or ".." in path.parts or not path.parts:
        raise ValueError(f"unsafe relative path: {value}")
    return path


def validate_overlay() -> dict:
    spec = load_json(OVERLAY_MAP)
    files = spec.get("files")
    if spec.get("schema") != 1 or not isinstance(files, dict) or not files:
        raise ValueError("overlay.json must contain non-empty schema-1 files map")

    targets: set[str] = set()
    for source_name, target_name in files.items():
        source_rel = safe_relative(source_name)
        target_rel = safe_relative(target_name)
        source = OVERLAY / Path(*source_rel.parts)
        if not source.is_file():
            raise ValueError(f"missing overlay source: {source_name}")
        normalized_target = target_rel.as_posix()
        if normalized_target in targets:
            raise ValueError(f"duplicate overlay target: {normalized_target}")
        if normalized_target in FORBIDDEN_TARGETS:
            raise ValueError(
                f"overlay would define/replace Rails application root: {normalized_target}"
            )
        targets.add(normalized_target)

    return spec


def verify_host(host: Path, lock: dict) -> None:
    host = host.resolve(strict=True)
    expected = lock["host"]["commit"]
    actual = git(host, "rev-parse", "HEAD")
    if actual != expected:
        raise ValueError(f"GitLab HEAD {actual} != pinned {expected}")
    if git(host, "status", "--porcelain", "--untracked-files=all"):
        raise ValueError("GitLab source must be clean before Aegis assembly")

    for relative, expected_blob in lock.get("anchors", {}).items():
        path = host / relative
        if not path.is_file():
            raise ValueError(f"missing GitLab anchor: {relative}")
        actual_blob = git(host, "hash-object", relative)
        if actual_blob != expected_blob:
            raise ValueError(
                f"GitLab anchor drift: {relative}: {actual_blob} != {expected_blob}"
            )


def patch_once(path: Path, needle: str, replacement: str, marker: str) -> None:
    data = path.read_text()
    if marker in data:
        raise ValueError(f"host already contains Aegis marker in {path}")
    if data.count(needle) != 1:
        raise ValueError(f"expected exactly one patch anchor in {path}")
    path.write_text(data.replace(needle, replacement, 1))


def copy_overlay(host: Path, spec: dict) -> list[str]:
    copied: list[str] = []
    for source_name, target_name in sorted(spec["files"].items()):
        source_rel = safe_relative(source_name)
        target_rel = safe_relative(target_name)
        source = OVERLAY / Path(*source_rel.parts)
        target = host / Path(*target_rel.parts)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
        copied.append(target_rel.as_posix())

    extra = {
        AEGIS / "dagger" / "supervision.py": Path("aegis/dagger/supervision.py"),
        LOCK_PATH: Path("aegis/runtime.lock.json"),
    }
    for source, target_rel in extra.items():
        if not source.is_file():
            raise ValueError(f"missing Aegis runtime source: {source}")
        target = host / target_rel
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
        copied.append(target_rel.as_posix())
    return copied


def build_manifest(host: Path, copied: list[str], lock: dict) -> dict:
    paths = sorted(
        set(copied + ["config/routes.rb", "app/services/mcp/tools/manager.rb"])
    )
    hashes = {
        relative: hashlib.sha256((host / relative).read_bytes()).hexdigest()
        for relative in paths
    }
    return {
        "schema": 1,
        "gitlab_commit": lock["host"]["commit"],
        "aegis_overlay_files": copied,
        "result_sha256": hashes,
        "single_rails_application": True,
        "mcp_tools": [
            "aegis_get_supervision_state",
            "aegis_github_get_state",
            "aegis_github_mutate",
        ],
        "claim": "assembly identity only; not semantic or formal proof evidence",
    }


def assemble(host: Path) -> dict:
    host = host.resolve(strict=True)
    lock = load_json(LOCK_PATH)
    spec = validate_overlay()
    verify_host(host, lock)
    copied = copy_overlay(host, spec)
    patch_once(
        host / "config/routes.rb",
        ROUTES_NEEDLE,
        ROUTES_INSERT,
        "draw :aegis",
    )
    patch_once(
        host / "app/services/mcp/tools/manager.rb",
        MCP_NEEDLE,
        MCP_NEEDLE + MCP_ENTRIES,
        "aegis_get_supervision_state",
    )
    manifest = build_manifest(host, copied, lock)
    destination = host / "aegis" / "assembly-manifest.json"
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    return manifest


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--gitlab", type=Path)
    parser.add_argument("--check-overlay", action="store_true")
    args = parser.parse_args()
    if args.check_overlay:
        spec = validate_overlay()
        print(
            json.dumps(
                {"schema": spec["schema"], "overlay_files": len(spec["files"])},
                sort_keys=True,
            )
        )
        return 0
    if args.gitlab is None:
        parser.error("--gitlab is required unless --check-overlay is used")
    print(
        json.dumps(
            assemble(args.gitlab), sort_keys=True, separators=(",", ":")
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
