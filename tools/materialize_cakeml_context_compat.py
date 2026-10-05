#!/usr/bin/env python3
"""Adapt the pinned CakeML tactic wrapper to HOL4's context-aware API.

Keep the pinned source unchanged. Only the audited wrapper and grammar differ
in the derived worktree; neither HOL kernel code nor logical definitions change.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
PREAMBLE = "misc/preamble.sml"


def git(directory: Path, *args: str) -> str:
    return subprocess.check_output(["git", "-C", str(directory), *args], text=True).strip()


def compatible_preamble(original: str) -> str:
    substitutions = (
        ("fun clear_cache_prover gtac  =", "fun clear_cache_prover ctxt gtac  ="),
        ("val res = TAC_PROOF gtac", """val res =
     if isSome (Context.current_thy ctxt) then Tactical.TAC_PROOF_in ctxt gtac
     else Feedback.trace ("TAC_PROOF requires current theory", 0)
            (Tactical.TAC_PROOF_in ctxt) gtac"""),
        ("(*Temporary workaround for cache being slow on long files*)",
         """(* Preserve the MOD precedence used by this CakeML revision. *)
val _ = Parse.set_fixity "MOD" (Infixl 650);
(*Temporary workaround for cache being slow on long files*)"""),
    )
    for before, after in substitutions:
        if original.count(before) != 1:
            raise ValueError("pinned tactic wrapper changed; compatibility patch requires re-audit")
        original = original.replace(before, after)
    return original


def materialize(source: Path, target: Path, expected: str) -> dict:
    source, target = source.resolve(), target.resolve()
    if source == target:
        raise ValueError("compatibility worktree must be separate from the pinned source")
    if git(source, "rev-parse", "HEAD") != expected:
        raise ValueError("CakeML source pin mismatch")
    if git(source, "status", "--porcelain", "--untracked-files=no"):
        raise ValueError("pinned CakeML source has tracked changes")
    original = (source / PREAMBLE).read_text()
    adapted = compatible_preamble(original)
    if not target.exists():
        target.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["git", "-C", str(source), "worktree", "add", "--detach",
                        str(target), expected], check=True)
    if git(target, "rev-parse", "HEAD") != expected:
        raise ValueError("derived CakeML worktree pin mismatch")
    if (target / PREAMBLE).is_symlink() or (target / PREAMBLE).stat().st_nlink != 1:
        raise ValueError("derived wrapper must be an independent regular file")
    changed = git(target, "diff", "HEAD", "--name-only").splitlines()
    content = (target / PREAMBLE).read_text()
    if changed not in ([], [PREAMBLE]) or content not in (original, adapted):
        raise ValueError("unexpected derived source changes; refusing to overwrite progress")
    if content != adapted:
        (target / PREAMBLE).write_text(adapted)
    if git(target, "diff", "HEAD", "--name-only") != PREAMBLE:
        raise ValueError("compatibility patch changed an unaudited source file")
    patch = git(target, "diff", "HEAD", "--", PREAMBLE) + "\n"
    return {
        "schema": 1,
        "base_commit": expected,
        "original_source": str(source),
        "derived_source": str(target),
        "modified_files": [PREAMBLE],
        "original_preamble_sha256": hashlib.sha256(original.encode()).hexdigest(),
        "adapted_preamble_sha256": hashlib.sha256(adapted.encode()).hexdigest(),
        "patch_sha256": hashlib.sha256(patch.encode()).hexdigest(),
        "patch": patch,
        "claim": "tactic API compatibility recipe; NOT proof of source-to-machine correctness",
        "legacy_library_mode": "Scoped HOL4 compatibility trace only when the supplied context has no current theory; kernel proof rules remain unchanged.",
        "mod_grammar": {
            "fixity": "Infixl 650",
            "historical_hol4_commit": "bec0b16a8e4efed5c8aa75afe14797543da0eccd",
            "historical_source": "src/num/theories/arithmeticScript.sml",
            "reason": "Preserve the existing CakeML statements' original parse; current HOL4 uses Infixl 600.",
        },
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--receipt", type=Path, required=True)
    args = parser.parse_args()
    expected = json.loads((ROOT / "spec/toolchain.lock.json").read_text())["repositories"]["cakeml"]["commit"]
    result = materialize(args.source, args.output, expected)
    args.receipt.parent.mkdir(parents=True, exist_ok=True)
    args.receipt.write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps({"derived_source": result["derived_source"],
                      "patch_sha256": result["patch_sha256"],
                      "claim": result["claim"]}))


if __name__ == "__main__":
    main()
