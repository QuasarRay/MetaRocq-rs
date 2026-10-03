"""Narrow evidence adapters. CHECKED is scoped evidence, not MetaRocq soundness."""
from __future__ import annotations

from dataclasses import asdict
from pathlib import Path
import os
import re
import shutil

from .contracts import FRAMEWORK, digest, read_json, require
from .process import run_process


def invocation(obligation):
    if obligation["method"] == "kani":
        return ["cargo", "kani", "--harness", obligation["entry"], "--exact", "--output-format", "regular"]
    return ["verus", obligation["entry"]]


def tool_identity(method):
    names = ["cargo", "cargo-kani", "rustc"] if method == "kani" else ["verus"]
    result = {}
    for name in names:
        found = shutil.which(name)
        require(found is not None, f"required tool unavailable: {name}")
        p = Path(found).resolve(strict=True)
        result[name] = {"path": str(p), "sha256": digest(p.read_bytes())}
    return result


def checked_output(o, result):
    if result.returncode or result.timed_out or result.stdout_truncated or result.stderr_truncated:
        return False
    out = result.stdout + "\n" + result.stderr
    if o["method"] == "kani":
        harnesses = re.findall(r"^Checking harness (.+?)\.\.\.$", out, re.M)
        statuses = re.findall(r"^\s*- Status: ([A-Z_]+)\s*$", out, re.M)
        return (harnesses == [o["entry"]] and out.count("VERIFICATION:- SUCCESSFUL") == 1
                and "SUCCESS" in statuses and set(statuses) <= {"SUCCESS", "SATISFIED"}
                and "VERIFICATION:- FAILED" not in out
                and "Complete - 1 successfully verified harnesses, 0 failures, 1 total." in out)
    summaries = re.findall(r"verification results::?\s*(\d+) verified, (\d+) errors", out)
    return summaries == [(str(o["expected_checks"]), "0")]


def verify_one(root, o, timeout):
    identity = tool_identity(o["method"])
    argv = invocation(o)
    version_argv = ["cargo", "kani", "--version"] if o["method"] == "kani" else ["verus", "--version"]
    # Reuse the process recorder but preserve installed Rust toolchain locations.
    env = {k: os.environ[k] for k in ("CARGO_HOME", "RUSTUP_HOME", "KANI_HOME", "HOME") if k in os.environ}
    env["NO_COLOR"] = "1"
    version = run_process(version_argv, cwd=root, timeout=min(timeout, 30), env=env)
    require(version.returncode == 0 and not version.timed_out and not version.stdout_truncated and not version.stderr_truncated, "tool version probe failed")
    expected = read_json(FRAMEWORK / "contracts/toolchain.json")[o["method"]]
    require(expected in version.stdout + version.stderr, "verifier version differs from the qualified toolchain")
    result = run_process(argv, cwd=root, timeout=timeout, env=env)
    require(tool_identity(o["method"]) == identity, "verifier executable changed during execution")
    return {"id": o["id"], "method": o["method"], "status": "CHECKED" if checked_output(o, result) else "FAILED",
            "tool_identity": identity, "version": asdict(version), "execution": asdict(result),
            "assumptions": o["assumptions"], "limits": o["limits"],
            "claim": "bounded harness result" if o["method"] == "kani" else "declared deductive obligation result"}
