"""Inspect a downloaded CI artifact without executing or extracting its files.

Expected run/head/archive digest must come from an independently observed
GitHub run, never from the artifact itself. Consistency is not a proof.
"""
from pathlib import Path, PurePosixPath
import io
import re
import stat
import zipfile

from .contracts import digest, git, keys, load_json, read_json, require, source_snapshot
from .extraction import DRIVER, OUTPUTS
from .security import confined_path
from .extraction_recipe import recipe, outputs, input_hashes, frontend_files

HEX256 = re.compile(r"[0-9a-f]{64}\Z")


def inspect(root, archive, *, expected_run, expected_head, expected_sha256, max_expanded_mib=64):
    # An operator may explicitly budget for the large, repetitive output of a
    # proof-data printer. The archive cannot choose or remove this bound.
    require(type(max_expanded_mib) is int and 1 <= max_expanded_mib <= 256,
            "expanded inspection budget must be an integer from 1 to 256 MiB")
    root = Path(root).resolve(strict=True)
    selected = recipe(root)
    output_map = outputs(selected)
    require(type(expected_run) is int and expected_run > 0, "expected run id must be positive")
    require(re.fullmatch(r"[0-9a-f]{40}", expected_head) is not None, "expected checkout SHA required")
    require(HEX256.fullmatch(expected_sha256) is not None, "expected GitHub artifact digest required")
    require(git(root, "rev-parse", "HEAD").decode().strip() == expected_head,
            "inspect from the expected source checkout")
    require(not git(root, "status", "--porcelain", "--untracked-files=all"),
            "inspection requires an unchanged checkout")
    with Path(archive).open("rb") as stream:
        data = stream.read(32 * 1024 * 1024 + 1)
    require(len(data) <= 32 * 1024 * 1024, "compressed artifact exceeds inspection budget")
    require(digest(data) == expected_sha256, "artifact differs from independently observed GitHub digest")
    # Inspect the very bytes whose digest was checked, not a reopened path.
    with zipfile.ZipFile(io.BytesIO(data)) as z:
        infos = z.infolist()
        expanded_bytes = sum(i.file_size for i in infos)
        require(len(infos) <= 128 and expanded_bytes <= max_expanded_mib * 1024 * 1024,
                "expanded artifact exceeds inspection budget")
        names = [i.filename for i in infos]
        require(len(names) == len(set(names)), "duplicate ZIP member")
        for i in infos:
            p = PurePosixPath(i.filename)
            require(not p.is_absolute() and p.as_posix() == i.filename
                    and all(x not in {"", ".", ".."} for x in i.filename.split("/"))
                    and "\\" not in i.filename and not i.is_dir(), "noncanonical ZIP member")
            require(not stat.S_ISLNK(i.external_attr >> 16), "symlink ZIP member")
        require("run.json" in names, "no current-run manifest; historical files are not extraction progress")
        manifest = load_json(z.read("run.json"))
        keys(manifest, "schema commit head run_id attempt steps files claim", "CI manifest")
        require(type(manifest["schema"]) is int and manifest["schema"] == 1, "unknown CI manifest schema")
        require(manifest["head"] == expected_head and manifest["run_id"] == str(expected_run),
                "artifact is for another run or checkout")
        steps = manifest["steps"]
        keys(steps, "preflight install extract compile", "CI steps")
        require(all(s in {"success", "failure", "cancelled", "skipped"} for s in steps.values()),
                "missing or unknown step outcome")
        ordered = [steps[k] for k in ("preflight", "install", "extract", "compile")]
        for i, outcome in enumerate(ordered):
            require(outcome != "success" or all(s == "success" for s in ordered[:i]),
                    "successful step follows a failed or skipped prerequisite")
        files = manifest["files"]
        require(type(files) is dict and set(files) == set(names) - {"run.json"}, "artifact inventory mismatch")
        for name, sha in files.items():
            require(isinstance(sha, str) and HEX256.fullmatch(sha) and digest(z.read(name)) == sha,
                    "artifact member digest mismatch")
        observations = [n for n in files if n.startswith(".metarocq/evidence/") and n.endswith(".json")]
        require(len(observations) <= 1, "ambiguous extraction observations")
        observation = load_json(z.read(observations[0])) if observations else None
        frontend = frontend_files(observation, selected) if observation else {}
        for name, sha in frontend.items():
            require(files.get(name) == sha and bool(z.read(name)), "frontend checkpoint missing or changed")
        permitted = set(output_map.values()) | set(observations) | set(frontend) | {"Cargo.lock", ".aegis/opam-switch.export"}
        require(set(files) <= permitted, "unexpected artifact member")
        generated = steps["extract"] == "success"
        if generated:
            require(set(output_map.values()) <= set(files) and len(observations) == 1,
                    "successful extraction is missing outputs or observation")
        else:
            require(not (set(output_map.values()) & set(files)), "failed or skipped extraction advertises candidate output")
        if observations:
            plan = read_json(root / ".metarocq/plan.json")
            require(observation["plan_digest"] == digest(plan), "extraction plan differs from checkout")
            require(observation["driver_sha256"] == digest(confined_path(root, selected["driver"], must_exist=True).read_bytes()),
                    "extraction driver differs from checkout")
            if (root / "extraction/recipe.json").exists():
                require(observation.get("recipe") == selected and observation.get("recipe_inputs") == input_hashes(root, selected),
                        "extraction recipe/support differs from checkout")
            require(observation["source"] == source_snapshot(root), "extraction source inventory differs from checkout")
            require(observations[0].endswith("-" + digest(observation) + ".json"), "observation name/digest mismatch")
            require(observation["status"] == "GENERATED" if generated else observation["status"] in {"FAILED", "BLOCKED"},
                    "step outcome and extraction status disagree")
            expected = {n: files[n] for n in output_map.values()} if generated else {}
            require(observation["outputs"] == expected, "extraction/output binding mismatch")
            if generated:
                require(all(bool(z.read(n)) for n in output_map.values()), "empty generated candidate")
                require(all(files.get(n) == entry["sha256"] for n, entry in observation.get("frontend", {}).items()),
                        "frontend checkpoint differs from published AST")
        if steps["compile"] == "success":
            require("Cargo.lock" in files, "successful Rust compilation lacks dependency lock")
        if steps["install"] == "success":
            require(".aegis/opam-switch.export" in files, "successful installation lacks dependency export")
    return {"status": "CONSISTENT", "run_id": expected_run, "head": expected_head,
            "expanded_bytes": expanded_bytes, "max_expanded_mib": max_expanded_mib,
            "generated": generated, "compiled": steps["compile"] == "success", "steps": steps,
            "frontend_preserved": sorted(observation.get("frontend", {})) if observation else [],
            "claim": "artifact/run/source consistency only; no authenticated build provenance or semantic proof"}
