"""HOL4/hol4-mcp orchestration.

hol4-mcp is an editing/proof-navigation aid.  Acceptance is always a direct
HOL4 kernel build via Holmake; MCP output is never promoted to proof evidence.
"""
from __future__ import annotations

from dataclasses import asdict
from pathlib import Path
import asyncio
import os
import re
import shutil

from .contracts import FRAMEWORK, digest, git, read_json, require
from .process import run_process
from .security import confined_path


def pins():
    lock = read_json(FRAMEWORK / "contracts/toolchain.json")
    return {
        "hol4_repo": lock["hol4_repo"],
        "hol4_commit": lock["hol4_commit"],
        "hol4_mcp_repo": lock["hol4_mcp_repo"],
        "hol4_mcp_commit": lock["hol4_mcp_commit"],
        "hol4_mcp_version": lock["hol4_mcp_version"],
    }


def hol4_home() -> Path:
    value = os.environ.get("HOLDIR")
    require(bool(value), "HOLDIR must point at the pinned HOL4 checkout")
    home = Path(value).resolve(strict=True)
    require((home / "bin/Holmake").is_file(), "HOLDIR has no built bin/Holmake")
    require(git(home, "rev-parse", "HEAD").decode().strip() == pins()["hol4_commit"],
            "HOL4 checkout differs from the pinned source")
    require(not git(home, "diff", "HEAD", "--"), "HOL4 tracked source is modified")
    return home


def executable_identity(path: Path) -> dict:
    path = path.resolve(strict=True)
    return {"path": str(path), "sha256": digest(path.read_bytes())}


def identity(*, require_mcp=False) -> dict:
    result = {
        "pins": pins(),
        "Holmake": executable_identity(hol4_home() / "bin/Holmake"),
    }
    if require_mcp:
        mcp = shutil.which("hol4-mcp")
        require(mcp is not None, "required tool unavailable: hol4-mcp")
        result["hol4-mcp"] = executable_identity(Path(mcp))
    if os.environ.get("HOL4_Z3_EXECUTABLE"):
        result["Z3"] = executable_identity(Path(os.environ["HOL4_Z3_EXECUTABLE"]))
    return result


def tactictoe_cache(root: Path) -> Path:
    root = Path(root).resolve(strict=True)
    cache = confined_path(root, ".aegis/tactictoe-cache")
    cache.mkdir(parents=True, exist_ok=True)
    return cache


def environment(root: Path) -> dict[str, str]:
    result = {
        "HOLDIR": str(hol4_home()),
        "HOL4_TACTICTOE_CACHE": str(tactictoe_cache(root)),
        **({"HOME": os.environ["HOME"]} if "HOME" in os.environ else {}),
    }
    if os.environ.get("HOL4_Z3_EXECUTABLE"):
        # HOL4's Z3 adapter interpolates this into a shell command.
        solver = str(Path(os.environ["HOL4_Z3_EXECUTABLE"]).resolve(strict=True))
        require(re.fullmatch(r"/[A-Za-z0-9_./+-]+", solver) is not None,
                "Z3 executable path is not shell-safe for the upstream adapter")
        require(os.access(solver, os.X_OK), "configured Z3 is not executable")
        result["HOL4_Z3_EXECUTABLE"] = solver
    return result


def mcp_stdio_config(root: Path) -> dict:
    """Configuration consumable by an MCP client; not verification evidence."""
    mcp = shutil.which("hol4-mcp")
    require(mcp is not None, "required tool unavailable: hol4-mcp")
    return {
        "command": str(Path(mcp).resolve(strict=True)),
        "args": ["--transport", "stdio"],
        "env": {
            "HOLDIR": str(hol4_home()),
            "HOL4_TACTICTOE_CACHE": str(tactictoe_cache(root)),
        },
        "identity": identity(require_mcp=True),
        "claim": "orchestration only; final acceptance requires direct Holmake",
    }


def holmake(root: Path, workdir: str = ".", timeout: int = 600) -> dict:
    """Run the trusted acceptance boundary directly, bypassing hol4-mcp."""
    root = Path(root).resolve(strict=True)
    cwd = confined_path(root, workdir, must_exist=True)
    require(cwd.is_dir(), "HOL4 workdir is not a directory")
    before = identity()
    result = run_process(
        [str(hol4_home() / "bin/Holmake"), "--qof", "--no-cache"],
        cwd=cwd,
        timeout=timeout,
        env=environment(root),
    )
    require(identity() == before, "HOL4 or solver executable changed during verification")
    checked = (
        result.returncode == 0
        and not result.timed_out
        and not result.stdout_truncated
        and not result.stderr_truncated
    )
    return {
        "status": "CHECKED" if checked else "FAILED",
        "tool_identity": before,
        "execution": asdict(result),
        "claim": "direct Holmake process observation; theorem scope and tags require separate inspection",
    }


def validate_mcp_probe(probe):
    # MCP 2.x uses snake_case Python fields; wire aliases remain stable.
    payload = probe.model_dump(by_alias=True)
    require(payload.get("isError") is False, "hol4-mcp hol_sessions probe failed or omitted its status")


async def _mcp_smoke_async(root: Path, timeout: int = 30) -> dict:
    """Start the pinned hol4-mcp server and exercise one read-only tool."""
    from mcp import ClientSession, StdioServerParameters
    from mcp.client.stdio import stdio_client

    root = Path(root).resolve(strict=True)
    config = mcp_stdio_config(root)
    params = StdioServerParameters(
        command=config["command"],
        args=config["args"],
        env={**os.environ, **config["env"]},
    )
    async with asyncio.timeout(timeout):
        async with stdio_client(params) as (read_stream, write_stream):
            async with ClientSession(read_stream, write_stream) as session:
                initialized = await session.initialize()
                listed = await session.list_tools()
                tool_names = sorted(tool.name for tool in listed.tools)
                require("hol_sessions" in tool_names, "hol4-mcp did not expose hol_sessions")
                probe = await session.call_tool("hol_sessions", {})
                validate_mcp_probe(probe)
                server_info = initialized.model_dump(by_alias=True).get("serverInfo")
                return {
                    "status": "READY",
                    "server": str(server_info) if server_info is not None else None,
                    "tools": tool_names,
                    "probe": "hol_sessions",
                    "claim": "MCP orchestration smoke test only; not proof evidence",
                }


def mcp_smoke(root: Path, timeout: int = 30) -> dict:
    """Synchronously qualify the configured stdio MCP server."""
    return asyncio.run(_mcp_smoke_async(root, timeout=timeout))
