"""Qualify Z3 proof reconstruction and reject contaminated theorem objects."""
from pathlib import Path
import json
import os
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "infra"))

from agentinfra.contracts import digest, require
from agentinfra.hol4 import executable_identity, holmake, mcp_stdio_config, mcp_smoke


SCRIPT = r"""open HolKernel boolLib bossLib integerTheory;
val _ = new_theory "AegisHol4Smoke";

val goal = ``!x y:int. (2*x <= 2*y /\ y < x+1) ==> (x = y)``;
val reconstructed = prove (goal, HolSmtLib.Z3_TAC);

(* DISK_THM is HOL4's loaded-theory bookkeeping marker, not an SMT oracle.
   Match the pinned Sanity default; do not trust its mutable allow lists. *)
fun acceptable expected th =
  let val (oracles, axioms) = Tag.dest_tag (Thm.tag th)
  in null (Thm.hyp th) andalso aconv (Thm.concl th) expected
     andalso List.all (fn name => name = "DISK_THM") oracles
     andalso null axioms
  end;
val _ = if acceptable goal reconstructed then ()
        else raise Fail "reconstructed theorem failed scope/tag inspection";
val _ = if acceptable goal (mk_oracle_thm "AegisRejectedProbe" ([], goal))
        orelse acceptable goal (ASSUME goal) orelse acceptable goal TRUTH
        then raise Fail "theorem inspection accepted a negative control" else ();
val _ = save_thm ("integer_interval", reconstructed);

val _ = export_theory();
val out = TextIO.openOut "inspection.json";
val _ = TextIO.output (out,
  "{\"theorem\":\"AegisHol4Smoke.integer_interval\",\"goal_checked\":true,\"hypotheses\":0,\"non_disk_oracles\":0,\"local_axioms\":0,\"negative_controls\":3}\n");
val _ = TextIO.closeOut out;
"""


def main() -> int:
    packet = {"status": "FAILED", "script_sha256": digest(SCRIPT.encode()),
              "claim": "Z3/HOL4 reconstruction and inspection qualification only; not MetaRocq refinement"}
    try:
        with tempfile.TemporaryDirectory(prefix="aegis-hol4-") as td:
            root = Path(td)
            (root / ".aegis").mkdir()
            theory = root / "theory"
            theory.mkdir()
            (theory / "AegisHol4SmokeScript.sml").write_text(SCRIPT)
            (theory / "Holmakefile").write_text("INCLUDES = $(HOLDIR)/src/integer $(HOLDIR)/src/HolSmt\n")
            solver = Path(os.environ["HOL4_Z3_EXECUTABLE"])
            packet["z3"] = executable_identity(solver)
            packet["holmake"] = holmake(root, "theory", timeout=600)
            require(executable_identity(solver) == packet["z3"], "Z3 executable changed during replay")
            require(packet["holmake"]["status"] == "CHECKED", "direct HOL4 replay failed; see execution")
            packet["inspection"] = json.loads((theory / "inspection.json").read_text())
            require(packet["inspection"] == {
                "theorem": "AegisHol4Smoke.integer_interval", "goal_checked": True,
                "hypotheses": 0, "non_disk_oracles": 0, "local_axioms": 0, "negative_controls": 3},
                "unexpected theorem inspection result")
            packet["exports"] = {}
            # Pinned Poly/ML HOL4 uses HFS_NameMunge.HOLOBJDIR, not the source directory.
            for suffix in ("sml", "sig", "dat"):
                name = "AegisHol4SmokeTheory." + suffix
                data = (theory / ".hol/objs" / name).read_bytes()
                require(bool(data), "theory export is empty")
                packet["exports"][name] = digest(data)
            packet["mcp"] = mcp_stdio_config(root)
            packet["mcp_smoke"] = mcp_smoke(root)
            require(packet["mcp_smoke"]["status"] == "READY", "MCP discovery failed")
            packet["status"] = "QUALIFIED"
    except Exception as exc:
        # A later packaging/MCP failure must not discard the direct replay log.
        packet["reason"] = str(exc)
    output = ROOT / ".aegis/hol4-qualification.json"
    output.parent.mkdir(exist_ok=True)
    output.write_text(json.dumps(packet, indent=2) + "\n")
    print(json.dumps({"status": packet["status"], "claim": packet["claim"],
                      "reason": packet.get("reason")}))
    return 0 if packet["status"] == "QUALIFIED" else 1


if __name__ == "__main__":
    raise SystemExit(main())
