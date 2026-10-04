#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import os
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "generated/hol4-pcuic/cakeml"
TRUSTED_BIN = ROOT / "metatheory/artifacts/original-checker.bin"
INTERFACE = ROOT / "metatheory/evidence/original-checker-interface.json"
PCUIC_MANIFEST = ROOT / "generated/hol4-pcuic/qualification/manifest.json"


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    original = (ROOT / "metatheory/bootstrap/OriginalChecker.v").read_text()
    blockers = []

    if "Context {guard_implementation : abstract_guard_impl}." in original:
        blockers.append("OriginalChecker.v still requires a concrete guard implementation.")
    if "Context (normalize : forall Sigma : global_env_ext," in original:
        blockers.append("OriginalChecker.v still requires a concrete normalization implementation.")
    if not TRUSTED_BIN.is_file():
        blockers.append("No trusted metatheory/artifacts/original-checker.bin exists.")
    if not INTERFACE.is_file():
        blockers.append("No independently specified original CakeML checker I/O contract exists.")
    if not PCUIC_MANIFEST.is_file():
        blockers.append("No generated canonical PCUIC proof manifest exists.")

    report = {
        "schema": 1,
        "status": "BLOCKED" if blockers else "READY",
        "claim": "CakeML execution is accepted only for a closed original MetaRocq checker with explicit I/O contract and trust ledger.",
        "diagnostic_untyped_ast": str(OUT / "original-checker-open.ast"),
        "diagnostic_cakeml_source": str(OUT / "original-checker-open.cml"),
        "blockers": blockers,
    }

    if not blockers:
        proof = ROOT / "generated/hol4-pcuic/qualification/QuoteImported.vo"
        command = [str(TRUSTED_BIN), str(proof)]
        p = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
        report["execution"] = {
            "argv": command,
            "returncode": p.returncode,
            "stdout_sha256": hashlib.sha256(p.stdout).hexdigest(),
            "stderr_sha256": hashlib.sha256(p.stderr).hexdigest(),
            "binary_sha256": digest(TRUSTED_BIN),
            "proof_sha256": digest(proof),
        }
        report["status"] = "EXECUTED" if p.returncode == 0 else "FAILED"

    path = OUT / "replay.json"
    path.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
    print(json.dumps({"status": report["status"], "blockers": blockers}))
    return 0 if report["status"] == "EXECUTED" else 2


if __name__ == "__main__":
    raise SystemExit(main())
