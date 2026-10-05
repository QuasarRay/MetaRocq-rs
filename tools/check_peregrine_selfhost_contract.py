#!/usr/bin/env python3
from __future__ import annotations
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
SPEC = ROOT / "spec" / "peregrine-selfhost-e2e.json"

class ContractError(RuntimeError):
    pass

def require(cond: bool, msg: str) -> None:
    if not cond:
        raise ContractError(msg)

def run(*args: str, cwd: pathlib.Path) -> str:
    return subprocess.check_output(args, cwd=cwd, text=True).strip()

def exact_checkout(name: str, directory: pathlib.Path, commit: str) -> None:
    require(directory.is_dir(), f"{name}: missing checkout {directory}")
    got = run("git", "rev-parse", "HEAD", cwd=directory)
    require(got == commit, f"{name}: HEAD {got} != pinned {commit}")
    require(not run("git", "status", "--porcelain", "--untracked-files=no", cwd=directory),
            f"{name}: tracked checkout is dirty")

def project_rocq_files(peregrine: pathlib.Path) -> list[str]:
    return [line.strip() for line in (peregrine / "_CoqProject").read_text().splitlines()
            if line.strip().endswith(".v")]

def gitlinks(peregrine: pathlib.Path) -> list[str]:
    out = run("git", "ls-files", "-s", cwd=peregrine)
    return [line.split(None, 3)[3] for line in out.splitlines()
            if line.startswith("160000 ")]

def main() -> int:
    spec = json.loads(SPEC.read_text())
    repos = spec["repositories"]
    refs = ROOT / ".aegis" / "references"
    dirs = {
        "metarocq": refs / "metarocq",
        "peregrine": refs / "peregrine",
        "cakeml_backend": refs / "cakeml-backend",
        "cakeml": refs / "cakeml",
        "hol4": refs / "hol4",
    }
    for name, directory in dirs.items():
        exact_checkout(name, directory, repos[name]["commit"])

    peregrine = dirs["peregrine"]
    got_files = project_rocq_files(peregrine)
    expected_files = spec["peregrine"]["rocq_files"]
    require(got_files == expected_files,
            "pinned Peregrine _CoqProject no longer matches retained module manifest")
    require(len(got_files) == spec["peregrine"]["rocq_module_count"] == 56,
            "unexpected Peregrine Rocq module count")

    expected_submodules = spec["peregrine"]["expected_git_submodules"]
    got_submodules = gitlinks(peregrine)
    require(got_submodules == expected_submodules,
            f"Peregrine gitlink set changed: {got_submodules!r}")
    require((peregrine / ".gitmodules").exists() == bool(expected_submodules),
            "Peregrine .gitmodules state changed; re-audit recursive clone policy")

    backend = (peregrine / "theories/backends/CakeMLBackend.v").read_text()
    require("Final Obligation." in backend and "Admitted." in backend,
            "Peregrine CakeML admitted boundary changed; re-audit required")
    require("Axiom trust_coq_kernel" in backend,
            "Peregrine CakeML trust escape changed; re-audit required")

    backend2 = (dirs["cakeml_backend"] / "theories/Backend/Pipeline.v").read_text()
    require("assume_can_be_extracted" in backend2,
            "pinned CakeML backend assumption changed; re-audit required")
    require("Admitted." in backend2,
            "pinned CakeML backend admitted boundary changed; re-audit required")

    extraction = (ROOT / "metatheory/peregrine-selfhost/ExtractPeregrineSelfHost.v").read_text()
    require("peregrine-selfhost.ast" in extraction and
            "peregrine_selfhost_runtime_root" in extraction,
            "selfhost extraction root no longer uses the replay-gated runtime root")

    entry = (ROOT / "metatheory/peregrine-selfhost/PeregrineSelfHostEntrypoint.v").read_text()
    require("Peregrine.Pipeline.peregrine_pipeline" in entry,
            "LambdaBox root no longer reaches real Peregrine pipeline")
    require("peregrine_selfhost_runtime_root" in entry and
            "replay_peregrine_runtime_program" in entry and
            "PeregrineRuntimeReady peregrine_selfhost_entrypoint" in entry and
            "PeregrineRuntimeReplayRejected" in entry,
            "CakeML runtime root no longer fail-closes normal dispatch on replay")
    require("retained_peregrine_proof_corpus" in entry and
            "retained_peregrine_assumption_ledger" in entry and
            "retained_peregrine_replay_jobs" in entry,
            "LambdaBox root no longer retains complete proof/replay payload")

    checked_producer_path = ROOT / "metatheory/peregrine-selfhost/PeregrineCheckedCakeMLProducer.v"
    require(checked_producer_path.is_file(), "checked CakeML producer adapter missing")
    checked_producer = checked_producer_path.read_text()
    require("EmbeddedPeregrine.prepare_cakeml" in checked_producer and
            "CheckedCandidateCakeML.checked_candidate_compile_past" in checked_producer and
            "Serialize_module" in checked_producer,
            "checked CakeML producer no longer reuses the audited checked path/printer")
    for forbidden in ("Admitted", "trust_coq_kernel", "assume_can_be_extracted"):
        require(forbidden not in checked_producer,
                f"checked CakeML producer contains forbidden trust escape: {forbidden}")

    checked_extraction_path = ROOT / "metatheory/peregrine-selfhost/PeregrineCheckedCakeMLExtraction.v"
    require(checked_extraction_path.is_file(), "checked CakeML extraction wrapper missing")
    checked_extraction = checked_extraction_path.read_text()
    require("From Peregrine Require Import Extraction." in checked_extraction and
            "checked_lambdabox_to_serialized_cakeml" in checked_extraction,
            "checked CakeML extraction no longer reuses Peregrine's pinned extraction configuration")

    replay_path = ROOT / "metatheory/peregrine-selfhost/PeregrineRuntimeReplay.v"
    require(replay_path.is_file(), "runtime replay module missing")
    replay = replay_path.read_text()
    require("tmQuoteRecTransp" in replay and
            "peregrine_all_declarations_root true" in replay and
            "MetaRocq.Template.Checker.typecheck_program" in replay and
            "replay_peregrine_runtime_program" in replay,
            "runtime replay no longer quotes and checks the retained Peregrine program")
    inventory = (ROOT / "metatheory/peregrine-selfhost/PeregrineReplayRootInventory.v").read_text()
    enumerator = (ROOT / "metatheory/original-selfhost/DeclarationReplayInventory.v").read_text()
    require("tmQuoteModule q" in enumerator and
            "emit_declaration_inventory peregrine_inventory_markers" in inventory and
            "PeregrineSourceManifest.peregrine_modules" in inventory and
            "VarRef id => tmFail" in enumerator and
            "PEREGRINE_REPLAY_COMPLETE" in inventory and
            "replay_corpus_has_all_retained_bodies" in replay,
            "replay root inventory must enumerate every pinned module and reject open variables")
    require("ReplayPeregrineRuntimeProofs" in entry and
            "PeregrineRuntimeReplayResult" in entry,
            "LambdaBox root no longer exposes runtime replay")

    blockers = spec["current_blockers"]
    require(any("PCUIC SafeChecker replay" in blocker for blocker in blockers),
            "diagnostic runtime replay must not silently close the faithful PCUIC SafeChecker blocker")

    require(spec["status"] == "FAIL_CLOSED", "contract must remain fail-closed")
    require(bool(spec["current_blockers"]), "unresolved formal blockers must stay explicit")
    print("Peregrine selfhost source/provenance contract: PASS")
    print("Semantic publication remains BLOCKED until HOL4 obligations are actually proved.")
    return 0

if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ContractError, OSError, ValueError, KeyError, subprocess.CalledProcessError) as exc:
        print(f"Peregrine selfhost source/provenance contract: FAIL: {exc}", file=sys.stderr)
        raise SystemExit(2)
