#!/usr/bin/env python3
"""Fail-closed provenance/policy checks for Selfhost 9.

This script does not prove semantic preservation. It verifies that the exact
pinned producer/kernel sources and the Candle-free active MetaRocq modules are
the objects the formal proof pipeline expects.
"""

from __future__ import annotations

import hashlib
import json
import os
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
SPEC = ROOT / "spec" / "hol4-selfhost-e2e.json"

ACTIVE_V_FILES = [
    "metatheory/original-selfhost/HOL4KernelContract.v",
    "metatheory/original-selfhost/SourceLambdaBoxRefinement.v",
    "metatheory/original-selfhost/IntegratedPeregrineCakeML.v",
    "metatheory/original-selfhost/HOL4MachineRefinement.v",
    "metatheory/original-selfhost/HOL4ProofLedger.v",
    "metatheory/original-selfhost/HOL4CertificateReplayIR.v",
    "metatheory/original-selfhost/HOL4RecursiveSelfIdentity.v",
    "metatheory/original-selfhost/HOL4SelfHostEntrypoint.v",
    "metatheory/original-selfhost/ExtractHOL4SelfHost.v",
]


class ContractError(RuntimeError):
    pass


def run(*args: str, cwd: pathlib.Path) -> str:
    return subprocess.check_output(args, cwd=cwd, text=True).strip()


def git_blob_sha(path: pathlib.Path) -> str:
    data = path.read_bytes()
    header = f"blob {len(data)}\0".encode()
    return hashlib.sha1(header + data).hexdigest()


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ContractError(message)


def exact_checkout(name: str, directory: pathlib.Path, commit: str) -> None:
    require(directory.is_dir(), f"{name}: missing checkout {directory}")
    got = run("git", "rev-parse", "HEAD", cwd=directory)
    require(got == commit, f"{name}: HEAD {got} != pinned {commit}")


def check_blob(base: pathlib.Path, rel: str, expected: str, symbol: str) -> None:
    path = base / rel
    require(path.is_file(), f"missing pinned source {path}")
    got = git_blob_sha(path)
    require(got == expected, f"{path}: blob {got} != pinned {expected}")
    require(symbol in path.read_text(errors="replace"),
            f"{path}: expected symbol {symbol!r} missing")


def main() -> int:
    spec = json.loads(SPEC.read_text())
    repos = spec["repositories"]

    dirs = {
        "hol4": pathlib.Path(os.environ.get("HOL4_DIR", ROOT / ".aegis/references/hol4")),
        "cakeml": pathlib.Path(os.environ.get("CAKEML_DIR", ROOT / ".aegis/references/cakeml")),
        "peregrine": pathlib.Path(os.environ.get("PEREGRINE_DIR", ROOT / ".aegis/references/peregrine-upstream")),
        "cakeml_backend": pathlib.Path(os.environ.get("CAKEML_BACKEND_DIR", ROOT / ".aegis/references/cakeml-backend")),
    }

    for name, directory in dirs.items():
        exact_checkout(name, directory, repos[name]["commit"])

    for binding in spec["cakeml_hol4_bindings"]:
        check_blob(dirs["cakeml"], binding["path"], binding["blob"], binding["symbol"])

    for binding in spec["peregrine_bindings"]:
        base = dirs["peregrine"] if binding["path"] == "theories/PAst.v" else dirs["cakeml_backend"]
        check_blob(base, binding["path"], binding["blob"], binding["symbol"])

    peregrine_backend = dirs["peregrine"] / "theories/backends/CakeMLBackend.v"
    backend_pipeline = dirs["cakeml_backend"] / "theories/Backend/Pipeline.v"
    require("trust_coq_kernel" in peregrine_backend.read_text(),
            "pinned Peregrine trust escape changed; re-audit required")
    require("Admitted." in peregrine_backend.read_text(),
            "pinned Peregrine admitted boundary changed; re-audit required")
    backend_text = backend_pipeline.read_text()
    require("assume_can_be_extracted" in backend_text,
            "pinned CakeML backend extraction assumption changed; re-audit required")
    require("compile_to_malfunction" in backend_text and "Admitted." in backend_text,
            "pinned CakeML backend preservation boundary changed; re-audit required")

    for rel in ACTIVE_V_FILES:
        path = ROOT / rel
        require(path.is_file(), f"active HOL4 module missing: {rel}")
        text = path.read_text()
        require("Candle" not in text and "candle" not in text,
                f"active HOL4 module still references Candle: {rel}")

    entrypoint = (ROOT / "metatheory/original-selfhost/HOL4SelfHostEntrypoint.v").read_text()
    require("HOL4SelfVerified" in entrypoint, "HOL4 verification response missing")
    require("accept_hol4_self_evidence" in entrypoint,
            "HOL4 entrypoint no longer gates acceptance on full self evidence")
    require("accept_original_hol4_certificate_corpus" in entrypoint,
            "HOL4 entrypoint no longer requires the entire certificate corpus")
    require("accept_hol4_recursive_identity" in entrypoint,
            "HOL4 entrypoint no longer requires recursive installed-image identity")

    extraction = (ROOT / "metatheory/original-selfhost/ExtractHOL4SelfHost.v").read_text()
    require("HOL4SelfHostEntrypoint.hol4_selfhost_entrypoint" in extraction,
            "HOL4 extraction root changed unexpectedly")

    require(spec["status"] == "FAIL_CLOSED", "contract must remain fail-closed")
    require(bool(spec["current_blockers"]), "contract must record unresolved formal blockers")

    print("Selfhost 9 provenance/policy contract: PASS")
    print("Semantic publication remains blocked until the formal obligations are proved.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ContractError, subprocess.CalledProcessError, OSError, KeyError, ValueError) as exc:
        print(f"Selfhost 9 provenance/policy contract: FAIL: {exc}", file=sys.stderr)
        raise SystemExit(1)
