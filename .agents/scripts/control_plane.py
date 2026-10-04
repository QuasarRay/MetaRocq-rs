#!/usr/bin/env python3
"""Select, diagnose and adopt the Aegis control plane with a safe legacy fallback.

GitLab is the preferred supervision/forge runtime when configured and ready. The
legacy Python/PostgreSQL/Git/GitHub controller remains available for control-plane
faults. Persistence and formal-proof failures never fall back.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
PACKET = ROOT / "spec" / "astra-adoption.json"
VALID_MODES = {"auto", "gitlab", "legacy"}
DEFAULT_PROBE_PATH = "/users/sign_in"


def emit(value: dict) -> None:
    print(json.dumps(value, sort_keys=True, separators=(",", ":")))


def run(argv: list[str], *, cwd: Path = ROOT) -> dict:
    result = subprocess.run(argv, cwd=cwd)
    return {"argv": argv, "returncode": result.returncode, "ok": result.returncode == 0}


def readiness_url() -> str | None:
    override = os.environ.get("AEGIS_GITLAB_READINESS_URL", "").strip()
    if override:
        return override
    base = os.environ.get("AEGIS_GITLAB_URL", "").strip().rstrip("/")
    return f"{base}{DEFAULT_PROBE_PATH}" if base else None


def probe_gitlab(*, opener=urlopen, timeout: float = 5.0) -> dict:
    url = readiness_url()
    if not url:
        return {
            "configured": False,
            "ready": False,
            "reason": "AEGIS_GITLAB_URL is not configured",
        }
    request = Request(url, headers={"Accept": "application/json", "User-Agent": "Aegis-MetaRocq/12"})
    try:
        with opener(request, timeout=timeout) as response:
            body = response.read(4096).decode("utf-8", "replace")
            status = getattr(response, "status", 200)
        return {
            "configured": True,
            "ready": status == 200,
            "status": status,
            "url": url,
            "body": body[:1000],
            "reason": "GitLab availability probe passed" if status == 200 else "GitLab availability probe returned non-200",
        }
    except HTTPError as error:
        return {
            "configured": True,
            "ready": False,
            "status": error.code,
            "url": url,
            "reason": "GitLab availability HTTP failure",
        }
    except (URLError, TimeoutError, OSError) as error:
        return {
            "configured": True,
            "ready": False,
            "url": url,
            "reason": f"GitLab availability transport failure: {type(error).__name__}",
        }


def select_mode(requested: str | None = None, *, probe: dict | None = None) -> dict:
    mode = (requested or os.environ.get("AEGIS_CONTROL_PLANE_MODE", "auto")).strip().lower()
    if mode not in VALID_MODES:
        raise ValueError(f"AEGIS_CONTROL_PLANE_MODE must be one of {sorted(VALID_MODES)}")
    if mode == "legacy":
        return {
            "requested": mode,
            "selected": "legacy",
            "degraded": False,
            "reason": "legacy control plane explicitly selected",
        }

    observed = probe if probe is not None else probe_gitlab()
    if observed.get("ready"):
        return {
            "requested": mode,
            "selected": "gitlab",
            "degraded": False,
            "reason": observed["reason"],
            "probe": observed,
        }
    if mode == "gitlab":
        return {
            "requested": mode,
            "selected": "blocked",
            "degraded": True,
            "reason": observed["reason"],
            "probe": observed,
        }
    return {
        "requested": mode,
        "selected": "legacy",
        "degraded": bool(observed.get("configured")),
        "reason": observed["reason"],
        "probe": observed,
    }


def packet() -> dict:
    value = json.loads(PACKET.read_text())
    if value.get("schema") != 1:
        raise ValueError("unsupported Astra adoption packet schema")
    for relative in value["must_read"]:
        if not (ROOT / relative).is_file():
            raise ValueError(f"missing adoption review file: {relative}")
    return value


def diagnose() -> dict:
    checks = [
        run([sys.executable, "-B", "scripts/generate.py", "--check"]),
        run([sys.executable, "-B", "-m", "unittest", "discover", "-s", "infra/tests", "-q"]),
        run([sys.executable, "-B", "gitlab/assemble.py", "--check-overlay"]),
    ]
    packet_value = packet()
    selection = select_mode()
    return {
        "schema": 1,
        "ok": all(item["ok"] for item in checks),
        "checks": checks,
        "control_plane": selection,
        "review_files": packet_value["must_read"],
        "claim": "architecture/control-plane qualification only; not formal proof acceptance",
    }


def legacy_validate(root: Path) -> dict:
    root = root.resolve(strict=True)
    # Keep CI/adoption qualification dependency-light: the validate operation needs
    # only the machine-readable roadmap, not a PostgreSQL connection or driver.
    for search_path in (ROOT, ROOT / "infra"):
        value = str(search_path)
        if value not in sys.path:
            sys.path.insert(0, value)
    from pipelines import roadmap as bootstrap_roadmap

    doc, tasks = bootstrap_roadmap.load(ROOT / "roadmaps" / "metarocq-bootstrap.json")
    return {
        "mode": "legacy",
        "validated": True,
        "roadmap": doc["id"],
        "tasks": len(tasks),
        "target": str(root),
        "execution_dependencies": {
            "postgresql_driver": "required for status/run/recover; qualification does not bypass it",
            "database_dsn": "required for status/run/recover and remains a hard block when unavailable",
        },
        "shared_state": [".aegis/", ".metarocq/", "PostgreSQL event store", "roadmap"],
        "claim": "fallback changes orchestration only; no proof or persistence gate is bypassed",
    }


def ci(root: Path, *, prevalidated: bool) -> dict:
    selection = select_mode()
    if not prevalidated:
        structural = diagnose()
        if not structural["ok"]:
            raise RuntimeError("architecture structural checks failed")

    if selection["selected"] == "gitlab":
        delegated = run([sys.executable, "-B", "gitlab/github_actions_bridge.py"])
        if delegated["ok"]:
            return {
                "schema": 1,
                "selected": "gitlab",
                "degraded": False,
                "delegation": delegated,
            }
        # A nonzero result may mean a failed proof, a commit mismatch, or an
        # uncertain remote execution. The bridge cannot distinguish a safe
        # availability-only retry here. Preserve the failure in every mode.
        raise RuntimeError(
            f"GitLab delegation failed (exit {delegated['returncode']}); "
            "legacy qualification cannot replace its execution result"
        )

    if selection["selected"] == "blocked":
        raise RuntimeError(f"GitLab was explicitly required but unavailable: {selection['reason']}")

    fallback = legacy_validate(root)
    return {
        "schema": 1,
        "selected": "legacy",
        "degraded": selection["degraded"],
        "reason": selection["reason"],
        "fallback": fallback,
    }


def continuation(root: Path) -> dict:
    selection = select_mode()
    root = root.resolve(strict=True)
    if selection["selected"] == "gitlab":
        return {
            "schema": 1,
            "control_plane": selection,
            "continue_with": {
                "supervision_mcp": "aegis_get_supervision_state",
                "github_mcp": "aegis_github_get_state",
                "formal_state": "use the same committed roadmap/PostgreSQL evidence; do not create GitLab-only proof state",
            },
            "fallback_command": f"AEGIS_CONTROL_PLANE_MODE=legacy {sys.executable} -B scripts/control_plane.py continue --root {root}",
        }
    if selection["selected"] == "blocked":
        return {
            "schema": 1,
            "control_plane": selection,
            "continue_with": None,
            "reason": "explicit GitLab mode is unavailable; choose auto/legacy or repair GitLab",
        }
    return {
        "schema": 1,
        "control_plane": selection,
        "continue_with": {
            "validate": f"{sys.executable} -B pipelines/bootstrap.py --root {root} validate",
            "status": f"AEGIS_DATABASE_DSN=<private> {sys.executable} -B pipelines/bootstrap.py --root {root} status",
            "recover": f"AEGIS_DATABASE_DSN=<private> {sys.executable} -B pipelines/bootstrap.py --root {root} recover --task <task-id>",
        },
        "hard_blocks": [
            "PostgreSQL persistence unavailable",
            "Git publication identity mismatch",
            "formal verifier/replay failure",
            "metatheory-verified gate closed",
        ],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("select")
    sub.add_parser("review")
    sub.add_parser("diagnose")
    sub.add_parser("adopt")

    cont = sub.add_parser("continue")
    cont.add_argument("--root", type=Path, default=Path("."))

    ci_parser = sub.add_parser("ci")
    ci_parser.add_argument("--root", type=Path, default=Path("."))
    ci_parser.add_argument("--prevalidated", action="store_true")

    args = parser.parse_args()
    if args.command == "select":
        result = select_mode()
    elif args.command == "review":
        result = packet()
    elif args.command in {"diagnose", "adopt"}:
        result = diagnose()
        if args.command == "adopt":
            result["next"] = {
                "command": "python3 -B scripts/control_plane.py continue --root <MetaRocq-rs>",
                "rule": "supply the existing MetaRocq-rs checkout; do not create or regenerate a roadmap",
            }
    elif args.command == "continue":
        result = continuation(args.root)
    else:
        result = ci(args.root, prevalidated=args.prevalidated)

    emit(result)
    if args.command in {"diagnose", "adopt"} and not result.get("ok", False):
        return 2
    if result.get("control_plane", {}).get("selected") == "blocked":
        return 2
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        emit({
            "schema": 1,
            "status": "BLOCKED",
            "error_type": type(error).__name__,
            "reason": str(error),
            "claim": "failure is not converted into proof or persistence success",
        })
        raise SystemExit(2)
