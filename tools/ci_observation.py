#!/usr/bin/env python3
"""Package this run's observations; never relabel historical failures as output."""
import hashlib
import json
import os
from pathlib import Path
import shutil

ROOT = Path(__file__).resolve().parents[1]
out = ROOT / ".aegis/artifact"
out.mkdir(parents=True, exist_ok=True)
steps = {s: os.environ.get(s.upper() + "_OUTCOME", "unknown")
         for s in ("preflight", "install", "extract", "compile")}
files = []
if steps["extract"] == "success":
    files += ["generated/pcuic_isapp.ast", "generated/pcuic_isapp.rs"]
state_path = ROOT / ".aegis/metarocq.json"
if state_path.exists():
    state = json.loads(state_path.read_text())
    if state.get("extraction_path"):
        files.append(state["extraction_path"])
for name in (".aegis/opam-switch.export", "Cargo.lock"):
    if (ROOT / name).is_file():
        files.append(name)
manifest = {"schema": 1, "commit": os.environ["GITHUB_SHA"],
            "head": os.environ["CHECKOUT_SHA"], "run_id": os.environ["GITHUB_RUN_ID"],
            "attempt": os.environ["GITHUB_RUN_ATTEMPT"], "steps": steps, "files": {},
            "claim": "CI process observations only; no semantic or production-readiness proof"}
for name in files:
    path = ROOT / name
    destination = out / name
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(path, destination)
    manifest["files"][name] = hashlib.sha256(path.read_bytes()).hexdigest()
(out / "run.json").write_text(json.dumps(manifest, indent=2) + "\n")
print(json.dumps(manifest, indent=2))
