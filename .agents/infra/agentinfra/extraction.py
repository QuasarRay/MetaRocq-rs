"""Bounded Peregrine generation; GENERATED never means verified Rust semantics."""
from __future__ import annotations

from dataclasses import asdict
import os
from pathlib import Path
import shutil
import tempfile
import time

from .contracts import ContractError, digest, require, source_snapshot
from .process import run_process
from .security import confined_path
from .transaction import FileTransaction, Mutation
from .extraction_recipe import recipe, outputs as recipe_outputs, input_hashes

DRIVER = "extraction/Bootstrap.v"
OUTPUTS = {"candidate.ast": "generated/pcuic_isapp.ast", "candidate.rs": "generated/pcuic_isapp.rs"}
CLAIM = "candidate source generation only; Rust backend, printer and semantic correspondence are unverified"


def tool_identity():
    result = {}
    for name in ("rocq", "peregrine"):
        found = shutil.which(name)
        require(found is not None, f"required extraction tool unavailable: {name}")
        path = Path(found).resolve(strict=True)
        result[name] = {"path": str(path), "sha256": digest(path.read_bytes())}
    return result


def generate(root, plan, timeout):
    require(type(timeout) is int and 0 < timeout <= 3600, "extraction budget must be 1..3600 seconds total")
    require(plan["reuse"]["strategy"] == "generate", "extraction needs a generation decision")
    root = Path(root).resolve(strict=True)
    configured = (root / "extraction/recipe.json").exists()
    selected = recipe(root)
    output_map = recipe_outputs(selected)
    require(configured or any(o["anchor"] == "pcuic/theories/PCUICAst.v" and o["symbol"] == "isApp"
                and OUTPUTS["candidate.rs"] in o["rust_paths"] for o in plan["obligations"]),
            "this bootstrap adapter supports only the declared PCUIC isApp slice")
    require({u["rust"] for u in selected["units"]} <=
            {p for o in plan["obligations"] for p in o["rust_paths"]},
            "recipe output lacks a declared proof obligation")
    driver = confined_path(root, selected["driver"], must_exist=True)
    before = source_snapshot(root)
    result = {"schema": 1, "status": "BLOCKED", "claim": CLAIM, "source": before,
              "driver_sha256": digest(driver.read_bytes()), "executions": [], "outputs": {},
              "installation_provenance": "Installed Rocq libraries must be independently tied to the pinned sources; executable hashes alone do not establish this."}
    if configured:
        result.update(recipe=selected, recipe_inputs=input_hashes(root, selected))
    try:
        identity = tool_identity()
        result["tool_identity"] = identity
        env = {k: os.environ[k] for k in ("HOME", "OPAM_SWITCH_PREFIX", "CAML_LD_LIBRARY_PATH", "OCAMLPATH", "COQLIB", "ROCQPATH") if k in os.environ}
        deadline = time.monotonic() + timeout
        with tempfile.TemporaryDirectory(prefix="aegis-metarocq-") as td:
            work = Path(td)
            inputs = [*selected["support"], selected["driver"]]
            for name in inputs:
                (work / Path(name).name).write_bytes(confined_path(root, name, must_exist=True).read_bytes())
            commands = [[identity["rocq"]["path"], "compile", Path(n).name] for n in inputs]
            commands += [[identity["peregrine"]["path"], "rust", u["stem"] + ".ast", "-o", u["stem"] + ".rs"]
                         for u in selected["units"]]
            for argv in commands:
                if argv[0] == identity["peregrine"]["path"]:
                    candidate = confined_path(work, argv[2], must_exist=True)
                    require(candidate.is_file() and candidate.stat().st_size > 0, "frontend emitted no typed AST")
                    require(candidate.stat().st_size <= 32 * 1024 * 1024, "frontend checkpoint exceeds 32 MiB budget")
                    require(source_snapshot(root) == before and tool_identity() == identity,
                            "source or extraction executable changed before frontend checkpoint")
                    content = candidate.read_bytes()
                    sha = digest(content)
                    name = f".metarocq/evidence/frontend-{sha}.ast"
                    saved = confined_path(root, name)
                    exists = saved.exists()
                    require(not exists or digest(saved.read_bytes()) == sha, "frontend checkpoint was changed")
                    FileTransaction(root, [Mutation(Path(name), content, expected_exists=exists,
                        expected_sha256=sha if exists else None)], state_dir=root / ".aegis/extraction-transactions",
                        name="frontend").commit(retain=False)
                    result.setdefault("frontend", {})[output_map[argv[2]]] = {"path": name, "sha256": sha}
                remaining = deadline - time.monotonic()
                require(remaining > 0, "extraction time budget exhausted")
                observed = run_process(argv, cwd=work, timeout=remaining, env=env)
                result["executions"].append(asdict(observed))
                require(observed.returncode == 0 and not observed.timed_out and not observed.stdout_truncated
                        and not observed.stderr_truncated, "extraction failed, timed out, or produced truncated diagnostics")
                # A zero-exit frontend without a fresh AST must not run the backend.
            outputs = {}
            for name, destination in output_map.items():
                path = confined_path(work, name, must_exist=True)
                require(path.is_file() and path.stat().st_size > 0, f"missing/empty generated artifact: {name}")
                outputs[destination] = path.read_bytes()
            require(tool_identity() == identity, "extraction executable changed during generation")
            require(source_snapshot(root) == before, "source changed during generation")
            # Reuse the existing recovery journal instead of hand-writing a
            # second multi-file publication mechanism.
            mutations = [Mutation(Path(name), content,
                expected_exists=name in before["entries"],
                expected_sha256=before["entries"].get(name, {}).get("sha256"))
                for name, content in outputs.items()]
            FileTransaction(root, mutations, state_dir=root / ".aegis/extraction-transactions",
                            name="peregrine").commit(retain=False)
            result["outputs"] = {name: digest(content) for name, content in outputs.items()}
            result["status"] = "GENERATED"
            result["output_source"] = source_snapshot(root)
    except (ContractError, OSError, RuntimeError) as exc:
        result["reason"] = str(exc)
        if result["executions"]:
            result["status"] = "FAILED"
    return result
