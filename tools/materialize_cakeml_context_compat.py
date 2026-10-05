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
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
PREAMBLE = "misc/preamble.sml"
ASM_LIBRARY = "compiler/encoders/asm/asmLib.sml"
EVALUATOR_LIBRARY = "cv_translator/eval_cake_compileLib.sml"
COMPUTE_UPDATES = {
    "compiler/parsing/cmlPEGScript.sml": (
        "val _ = (computeLib.the_compset := computeLib.add_thms distinct_ths (!computeLib.the_compset))",
        "val _ = computeLib.add_funs distinct_ths"),
    "translator/ml_progLib.sml": (
        "val () = (computeLib.the_compset := computeLib.add_thms [nsLookup_eq] (!computeLib.the_compset))",
        "val () = computeLib.add_funs [nsLookup_eq]"),
}
ASM_PROVE_PREFIX = '''(* Preserve the legacy load-time proof call with a scoped context policy. *)
fun legacy_library_prove ttac =
  if isSome (Context.current_thy (Context.snapshot())) then Tactical.prove ttac
  else Feedback.trace ("TAC_PROOF requires current theory", 0) Tactical.prove ttac;

'''
THEORY_HEADER = re.compile(r"(?m)^Theory[^\n]*\n(?:(?:Ancestors|Libs)[^\n]*\n(?:[ \t]+[^\n]*\n)*)*")
MOD_PREFIX = '(* Preserve the pinned CakeML MOD grammar after ancestor loading. *)\nval _ = Parse.temp_set_fixity "MOD" (Parse.Infixl 650);\n'


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


def compatible_theory(original: str) -> str:
    if not re.search(r"\bMOD\b", original):
        return original
    header = THEORY_HEADER.search(original)
    if not header:
        raise ValueError("MOD theory header changed; grammar adaptation requires re-audit")
    return original[:header.end()] + MOD_PREFIX + original[header.end():]


def compatible_asm_library(original: str) -> str:
    anchor = "val asm_rwts =\n"
    proof = "    prove\n      (“!a b x:'a y. a /\\ (a ==> ~b) ==> ((if b then x else y) = y)”, rw [])"
    if original.count(anchor) != 1 or original.count(proof) != 1:
        raise ValueError("pinned asm library proof call changed; compatibility patch requires re-audit")
    return original.replace(anchor, ASM_PROVE_PREFIX + anchor).replace(
        proof, proof.replace("prove\n", "legacy_library_prove\n", 1))


def compatible_evaluator_library(original: str) -> str:
    old = 'Feedback.set_trace "TheoryPP.include_docs" 0'
    if original.count(old) != 1:
        raise ValueError("pinned evaluator documentation trace changed; compatibility patch requires re-audit")
    return original.replace(old, 'Feedback.set_trace "TheoryPP.include_html_docs" 0')


def compatible_compute_update(name: str, original: str) -> str:
    before, after = COMPUTE_UPDATES[name]
    if original.count(before) != 1:
        raise ValueError("pinned computation-set update changed; compatibility patch requires re-audit")
    return original.replace(before, after)


def adapted_sources(source: Path) -> dict[str, str]:
    result = {PREAMBLE: compatible_preamble((source / PREAMBLE).read_text())}
    result[ASM_LIBRARY] = compatible_asm_library((source / ASM_LIBRARY).read_text())
    result[EVALUATOR_LIBRARY] = compatible_evaluator_library((source / EVALUATOR_LIBRARY).read_text())
    for name in git(source, "ls-files", "*Script.sml").splitlines():
        original = (source / name).read_text()
        adapted = compatible_theory(original)
        if adapted != original:
            result[name] = adapted
    for name in COMPUTE_UPDATES:
        original = result.get(name, (source / name).read_text())
        result[name] = compatible_compute_update(name, original)
    return result


def compatibility_key(source: Path) -> str:
    h = hashlib.sha256()
    for name, content in sorted(adapted_sources(source).items()):
        h.update(name.encode() + b"\0" + content.encode() + b"\0")
    return h.hexdigest()[:16]


def materialize(source: Path, target: Path, expected: str) -> dict:
    source, target = source.resolve(), target.resolve()
    if source == target:
        raise ValueError("compatibility worktree must be separate from the pinned source")
    if git(source, "rev-parse", "HEAD") != expected:
        raise ValueError("CakeML source pin mismatch")
    if git(source, "status", "--porcelain", "--untracked-files=no"):
        raise ValueError("pinned CakeML source has tracked changes")
    originals = {PREAMBLE: (source / PREAMBLE).read_text()}
    adaptations = adapted_sources(source)
    originals.update({n: (source / n).read_text() for n in adaptations})
    if not target.exists():
        target.parent.mkdir(parents=True, exist_ok=True)
        subprocess.run(["git", "-C", str(source), "worktree", "add", "--detach",
                        str(target), expected], check=True)
    if git(target, "rev-parse", "HEAD") != expected:
        raise ValueError("derived CakeML worktree pin mismatch")
    changed = git(target, "diff", "HEAD", "--name-only").splitlines()
    if set(changed) - set(adaptations):
        raise ValueError("unexpected derived source changes; refusing to overwrite progress")
    for name, adapted in adaptations.items():
        file = target / name
        if file.is_symlink() or file.stat().st_nlink != 1:
            raise ValueError("derived source must be an independent regular file")
        if file.read_text() not in (originals[name], adapted):
            raise ValueError("unexpected derived source changes; refusing to overwrite progress")
    for name, adapted in adaptations.items():
        if (target / name).read_text() != adapted:
            (target / name).write_text(adapted)
    modified = sorted(adaptations)
    if git(target, "diff", "HEAD", "--name-only").splitlines() != modified:
        raise ValueError("compatibility patch changed an unaudited source file")
    patch = git(target, "diff", "HEAD", "--", *modified) + "\n"
    return {
        "schema": 1,
        "base_commit": expected,
        "original_source": str(source),
        "derived_source": str(target),
        "modified_files": modified,
        "source_digests": {n: {"original": hashlib.sha256(originals[n].encode()).hexdigest(),
                               "adapted": hashlib.sha256(adaptations[n].encode()).hexdigest()} for n in modified},
        "original_preamble_sha256": hashlib.sha256(originals[PREAMBLE].encode()).hexdigest(),
        "adapted_preamble_sha256": hashlib.sha256(adaptations[PREAMBLE].encode()).hexdigest(),
        "patch_sha256": hashlib.sha256(patch.encode()).hexdigest(),
        "patch": patch,
        "claim": "tactic API compatibility recipe; NOT proof of source-to-machine correctness",
        "legacy_library_mode": "Scoped HOL4 compatibility trace only when the supplied context has no current theory, for the preamble wrapper and the single asmLib load-time rewrite proof; kernel proof rules and the original proposition/tactic remain unchanged.",
        "documentation_trace": "Use the pinned HOL4 TheoryPP.include_html_docs setting in the compiler evaluator; this changes documentation output only.",
        "mod_grammar": {
            "fixity": "Infixl 650",
            "historical_hol4_commit": "bec0b16a8e4efed5c8aa75afe14797543da0eccd",
            "historical_source": "src/num/theories/arithmeticScript.sml",
            "reason": "Preserve the existing CakeML statements' original parse; current HOL4 uses Infixl 600.",
            "theory_contexts": "Restore temporary fixity immediately after each MOD-using theory header. Ancestor loading resets the preamble's earlier grammar setting.",
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
