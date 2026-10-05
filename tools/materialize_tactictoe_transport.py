#!/usr/bin/env python3
"""Materialize a serial TacticToe child-launch compatibility recipe.

Proof search, tactic recording, cache identities and publication remain in
pinned HOL4 SML. Only the POSIX child launcher changes; the kernel is untouched.
The outer observed process owns cancellation of the complete process group.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
SOURCE = "src/AI/sml_inspection/smlExecScripts.sml"
START = "fun run_with_pid private_group started finished dir cmd =\n"
END = "\nfun exec_scriptb_in_dir_with_pid private_group started finished b dir script =\n"
REPLACEMENT = '''(* Serial recorder transport only. The outer runner owns process-group cancellation. *)
fun run_with_pid private_group
    (started : Posix.Process.pid -> unit)
    (finished : Posix.Process.pid -> unit) dir cmd =
  if private_group then raise ERR "run_with_pid" "serial recorder transport only"
  else let
    val previous = OS.FileSys.getDir ()
    val _ = OS.FileSys.chDir (current_dir_if_empty dir)
    val status = OS.Process.system cmd
      handle e => (OS.FileSys.chDir previous; raise e)
    val _ = OS.FileSys.chDir previous
  in
    if OS.Process.isSuccess status then ()
    else raise ERR "run_with_pid" "external recording command failed"
  end
'''


def adapt(source: str) -> str:
    if source.count(START) != 1 or source.count(END) != 1:
        raise ValueError("pinned child-launch boundaries changed; re-audit required")
    begin, end = source.index(START), source.index(END)
    if end <= begin or "case Posix.Process.fork () of" not in source[begin:end]:
        raise ValueError("pinned POSIX launcher changed; re-audit required")
    return source[:begin] + REPLACEMENT + source[end:]


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--holdir", type=Path, required=True)
    p.add_argument("--output", type=Path, required=True)
    args = p.parse_args()
    home = args.holdir.resolve(strict=True)
    lock = json.loads((ROOT / ".agents/contracts/toolchain.json").read_text())
    observed = subprocess.check_output(["git", "-C", str(home), "rev-parse", "HEAD"], text=True).strip()
    if observed != lock["hol4_commit"] or subprocess.check_output(
            ["git", "-C", str(home), "diff", "HEAD", "--"]):
        raise ValueError("HOL4 source must match the clean .agents pin")
    original = (home / SOURCE).read_text()
    rendered = adapt(original)
    target = args.output.resolve()
    if target.is_symlink():
        raise ValueError("redirected transport output")
    target.mkdir(parents=True, exist_ok=True)
    file = target / "smlExecScripts.sml"
    if file.exists() and file.read_text() != rendered:
        raise ValueError("refusing to overwrite previous transport progress")
    file.write_text(rendered)
    packet = {"schema": 1, "hol4_commit": observed, "source": SOURCE,
              "original_sha256": hashlib.sha256(original.encode()).hexdigest(),
              "adapted_sha256": hashlib.sha256(rendered.encode()).hexdigest(),
              "scope": "serial TacticToe recording only; private-group launch rejected",
              "claim": "process-launch compatibility; not proof evidence"}
    (target / "receipt.json").write_text(json.dumps(packet, indent=2) + "\n")
    print(json.dumps(packet))


if __name__ == "__main__":
    main()
