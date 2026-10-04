"""Generate repeated agent context and the plan template from the authority lock."""
from pathlib import Path
import argparse
import json
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "infra"))
from agentinfra.contracts import authority, authority_digest


def artifacts():
    source = authority()
    outputs = {}
    # Include new source files too; no runtime/build/vendor enumeration.
    paths = subprocess.check_output(["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"], cwd=ROOT).decode().split("\0")
    dirs = {Path("docs/generated"), Path("templates")}
    for name in paths:
        if not name or not (ROOT / name).is_file() or name.startswith((".aegis/", ".metarocq/evidence/")):
            continue
        dirs.update(p for p in Path(name).parents if str(p) != ".")
    root_agents = (ROOT / "AGENTS.md").read_text()
    for directory in dirs:
        content = root_agents
        local = ROOT / directory / "AGENTS.local.md"
        if local.is_file():
            content += "\n\n---\n\n" + local.read_text().strip() + "\n"
        outputs[(directory / "AGENTS.md").as_posix()] = content
    template = {
        "schema": 1, "task": "pcuic-isapp", "authority_sha256": authority_digest(),
        "paper_sections": ["JACM 2025: PCUIC syntax and safe checker"],
        "reuse": {"strategy": "generate", "sources": ["pinned MetaRocq original Rocq definitions", "Kani proof harness pattern"],
                  "license": "REPLACE: inspect source licenses before copying", "reason": "REPLACE: record evaluated reuse alternatives",
                  "generator": ["python3", "tools/bootstrap.py", "extract"]},
        "adr": "docs/adr/0001-extraction-boundary.md", "remote": {"repository": "QuasarRay/MetaRocq-rs", "base": "main"},
        "obligations": [{"id": "pcuic-isapp", "anchor": "pcuic/theories/PCUICAst.v",
                         "symbol": "isApp", "statement": "REPLACE: exact Rust/PCUIC representation relation and domain",
                         "rust_paths": ["generated/pcuic_isapp.rs", "src/proofs.rs"], "method": "kani", "entry": "proofs::pcuic_isapp",
                         "expected_checks": 1, "assumptions": ["REPLACE: list trusted correspondence and environment assumptions"],
                         "limits": ["REPLACE: bounded term depth, allocation, unwind and input domain"]}]
    }
    outputs["templates/metarocq-plan.json"] = json.dumps(template, indent=2) + "\n"
    lines = ["# Original specification anchors", "", "Generated from `contracts/authority.json`; not a completeness or proof claim.", "",
             "| Original path | SHA-256 |", "| --- | --- |"]
    lines += [f"| `{s['path']}` | `{s['sha256']}` |" for s in source["specifications"]]
    outputs["docs/generated/anchors.md"] = "\n".join(lines) + "\n"
    return outputs


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    changed = []
    for name, content in sorted(artifacts().items()):
        p = ROOT / name
        if p.exists() and p.read_text() == content:
            continue
        changed.append(name)
        if not args.check:
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(content)
    print(json.dumps({"generated_changes": changed, "check": args.check}, separators=(",", ":")))
    return int(args.check and bool(changed))


if __name__ == "__main__":
    raise SystemExit(main())
