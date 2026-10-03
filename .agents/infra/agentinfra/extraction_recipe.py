"""Bounded additive extraction recipes; the legacy isApp recipe remains valid."""
import re

from .contracts import digest, keys, read_json, relative, require
from .security import confined_path

RECIPE = "extraction/recipe.json"
DEFAULT = {"schema": 1, "driver": "extraction/Bootstrap.v", "support": [],
           "units": [{"stem": "candidate", "ast": "generated/pcuic_isapp.ast",
                      "rust": "generated/pcuic_isapp.rs"}]}


def recipe(root):
    path = confined_path(root, RECIPE)
    value = read_json(path) if path.exists() else DEFAULT
    keys(value, "schema driver support units", "extraction recipe")
    require(type(value["schema"]) is int and value["schema"] == 1, "unknown recipe schema")
    require(type(value["support"]) is list and len(value["support"]) <= 16, "invalid support inventory")
    inputs = [*value["support"], value["driver"]]
    require(all(isinstance(n, str) for n in inputs), "recipe inputs must be paths")
    require(len(set(inputs)) == len(inputs), "duplicate recipe input")
    for name in inputs:
        relative(name)
        require(re.fullmatch(r"extraction/[A-Za-z][A-Za-z0-9_]*\.v", name),
                "recipe inputs must be direct extraction Rocq modules")
        require(confined_path(root, name, must_exist=True).is_file(), "missing recipe input")
    require(type(value["units"]) is list and 0 < len(value["units"]) <= 8, "invalid extraction unit count")
    stems, destinations = set(), set()
    for unit in value["units"]:
        keys(unit, "stem ast rust", "extraction unit")
        stem = unit["stem"]
        require(isinstance(stem, str) and re.fullmatch(r"[a-z][a-z0-9_]{0,63}", stem)
                and stem not in stems, "invalid/duplicate extraction stem")
        stems.add(stem)
        for ext in ("ast", "rust"):
            name = relative(unit[ext])
            suffix = "rs" if ext == "rust" else ext
            require(re.fullmatch(r"generated/[a-z][a-z0-9_]*\." + suffix, name)
                    and name not in destinations, "invalid/duplicate output destination")
            destinations.add(name)
    return value


def outputs(value):
    return {u["stem"] + "." + ext: u[key] for u in value["units"]
            for ext, key in (("ast", "ast"), ("rs", "rust"))}


def input_hashes(root, value=None):
    value = value or recipe(root)
    names = [*value["support"], value["driver"]]
    if confined_path(root, RECIPE).exists():
        names.append(RECIPE)
    return {n: digest(confined_path(root, n, must_exist=True).read_bytes()) for n in names}


def frontend_files(observation, selected):
    """Validate optional intermediate metadata without promoting it to Rust output."""
    value = observation.get("frontend", {})
    require(type(value) is dict and set(value) <= {u["ast"] for u in selected["units"]},
            "unexpected frontend checkpoint")
    files = {}
    for entry in value.values():
        keys(entry, "path sha256", "frontend checkpoint")
        sha = entry["sha256"]
        require(isinstance(sha, str) and re.fullmatch(r"[0-9a-f]{64}", sha), "invalid frontend digest")
        require(entry["path"] == f".metarocq/evidence/frontend-{sha}.ast", "invalid frontend checkpoint path")
        files[entry["path"]] = sha
    return files
