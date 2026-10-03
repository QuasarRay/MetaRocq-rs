"""Enforce bounded, diagnosed generation attempts before starting a process."""
import os

from .contracts import FRAMEWORK, ContractError, digest, read_json, require
from .extraction import tool_identity
from .security import confined_path
from .extraction_recipe import recipe, input_hashes


def attempt_inputs(root, timeout):
    # Diagnostics and ADR edits cannot alone authorize the same failed build.
    files = {}
    files.update(input_hashes(root, recipe(root)))
    for name in ("tools/bootstrap.py", "spec/toolchain.lock.json",
                 ".aegis/opam-switch.export"):
        path = confined_path(root, name)
        files[name] = digest(path.read_bytes()) if path.exists() else None
    try:
        tools = tool_identity()
    except (ContractError, OSError) as exc:
        tools = {"unavailable": str(exc)}
    return {"files": files, "tools": tools, "timeout": timeout,
            "environment": {k: os.environ.get(k) for k in (
                "OPAM_SWITCH_PREFIX", "OCAMLPATH", "COQLIB", "ROCQPATH")}}


def reserve(root, state, timeout, diagnosis):
    policy = read_json(FRAMEWORK / "contracts/extraction-budget.json")
    require(type(timeout) is int and 0 < timeout <= policy["max_seconds_per_attempt"],
            "extraction exceeds the per-attempt time budget")
    attempts = state.setdefault("extraction_attempts", [])
    require(len(attempts) < policy["max_attempts"],
            "extraction attempt budget exhausted; checkpoint the diagnosis before a new cycle")
    require(sum(a["reserved_seconds"] for a in attempts) + timeout <= policy["total_seconds"],
            "extraction total time budget exhausted")
    inputs = attempt_inputs(root, timeout)
    fingerprint = digest(inputs)
    if attempts:
        require(isinstance(diagnosis, str) and bool(diagnosis.strip()),
                "retry requires a recorded diagnosis and correction")
        require(fingerprint != attempts[-1]["inputs_digest"],
                "unchanged failed extraction is not eligible for retry")
    else:
        require(diagnosis is None, "a first extraction has no failed attempt to diagnose")
    attempt = {"number": len(attempts) + 1, "status": "RESERVED",
               "reserved_seconds": timeout, "inputs": inputs,
               "inputs_digest": fingerprint, "diagnosis": diagnosis,
               "previous_evidence": state.get("extraction_path"),
               "previous_digest": state.get("extraction_digest")}
    attempts.append(attempt)
    return attempt
