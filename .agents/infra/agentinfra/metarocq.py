"""One contract, one evidence bundle, one durable checkpoint per work cycle."""
from __future__ import annotations

from contextlib import contextmanager
from pathlib import Path
import subprocess

from .atomic import atomic_write_json
from .checkpoints import attest, github_pr
from .contracts import (ContractError, authority_digest, digest, framework_digest, git,
                        read_json, require, source_snapshot, validate_plan, verify_references)
from .locks import FileLock
from .security import confined_path
from .verifiers import invocation, verify_one


class MetaRocq:
    def __init__(self, root):
        self.root = Path(root).resolve(strict=True)
        self.control = confined_path(self.root, ".aegis")
        self.state_path = confined_path(self.root, ".aegis/metarocq.json")

    @contextmanager
    def locked(self):
        lock_path = confined_path(self.root, ".aegis/metarocq.lock")
        lock = FileLock(lock_path, "MetaRocq contract cycle")
        lock.acquire(timeout=0)
        try:
            yield
        finally:
            lock.release()

    def state(self):
        state = read_json(self.state_path)
        require(state.get("schema") == 1, "legacy/unknown state: archive it; do not reinterpret it as MetaRocq evidence")
        require(state.get("framework") == framework_digest(), "control plane changed; explicit new cycle required")
        require(state.get("plan_digest") == digest(state.get("plan")), "frozen plan changed")
        validate_plan(state["plan"])
        return state

    def save(self, state):
        atomic_write_json(self.state_path, state, root=self.root)

    def freeze(self, plan_path, references):
        with self.locked():
            plan_file = confined_path(self.root, plan_path, must_exist=True)
            plan = validate_plan(read_json(plan_file))
            verify_references(plan, references)
            adr = confined_path(self.root, plan["adr"], must_exist=True)
            require(bool(adr.read_text().strip()), "architecture decision is empty")
            history = []
            if self.state_path.exists():
                previous = self.state()
                require(previous["phase"] == "PUBLISHED", "publish the current cycle before starting another")
                history = previous["history"] + [previous["checkpoint"]]
                require(plan["task"] not in {h["task"] for h in history}, "task ids cannot be reused")
                prior = previous["checkpoint"]
                require(plan["remote"]["repository"] == prior["repository"], "stack cannot change repository")
                remote = github_pr(prior["repository"], prior["pr"])
                require(remote.get("head", {}).get("sha") == prior["head"], "previous PR no longer has the preserved head")
                require(remote.get("state") == "open" or remote.get("merged") is True, "previous PR was closed without merge")
                expected_base = prior["branch"] if remote["state"] == "open" else prior["base"]
                require(plan["remote"]["base"] == expected_base, "next cycle must stack on the previous PR (or its merged base)")
                ancestor = subprocess.run(["git", "merge-base", "--is-ancestor", prior["head"], "HEAD"], cwd=self.root)
                require(ancestor.returncode == 0, "new work does not preserve the previous commit")
            state = {"schema": 1, "phase": "BOUND", "plan": plan, "plan_digest": digest(plan),
                     "framework": framework_digest(), "references": {k: str(Path(v).resolve()) for k, v in references.items()},
                     "plan_path": plan_file.relative_to(self.root).as_posix(), "history": history,
                     "start_head": git(self.root, "rev-parse", "HEAD").decode().strip()}
            self.save(state)
            return self.brief(state)

    def brief(self, state=None):
        s = state or self.state()
        return {"task": s["plan"]["task"], "phase": s["phase"], "contract": s["plan_digest"],
                "authority": authority_digest(), "paper_sections": s["plan"]["paper_sections"],
                "reuse": s["plan"]["reuse"], "obligations": [
                    {"id": o["id"], "original": f"{o['anchor']}#{o['symbol']}",
                     "statement": o["statement"], "argv": invocation(o), "limits": o["limits"]}
                    for o in s["plan"]["obligations"]],
                "next": "publish a small stacked PR; do not start another cycle until checkpointed"}

    def inputs(self, state):
        plan = state["plan"]
        require(read_json(confined_path(self.root, state["plan_path"], must_exist=True)) == plan, "contract file changed after binding")
        originals = verify_references(plan, state["references"])
        for o in plan["obligations"]:
            for p in o["rust_paths"]:
                require(confined_path(self.root, p, must_exist=True).is_file(), f"Rust source missing: {p}")
        return {**source_snapshot(self.root), "originals": originals}

    def extract(self, timeout=600, retry_diagnosis=None):
        from .extraction import generate
        from .extraction_budget import reserve
        with self.locked():
            s = self.state()
            require(s["phase"] == "BOUND", "extraction requires a bound, unverified cycle")
            require(read_json(confined_path(self.root, s["plan_path"], must_exist=True)) == s["plan"], "contract file changed after binding")
            originals = verify_references(s["plan"], s["references"])
            if "extraction_path" in s:
                old = read_json(confined_path(self.root, s["extraction_path"], must_exist=True))
                require(digest(old) == s["extraction_digest"], "extraction observation changed after capture")
                if old["status"] == "GENERATED":
                    old = self.extraction_evidence(s)
                    require(retry_diagnosis is None, "successful extraction is reused; new generation needs a new cycle")
                    return {"status": old["status"], "evidence": s["extraction_path"],
                            "reused": True, "claim": old["claim"]}
            attempt = reserve(self.root, s, timeout, retry_diagnosis)
            s.pop("extraction_path", None)
            s.pop("extraction_digest", None)
            # Reserve the full allowance BEFORE launch; crashes cannot reset it.
            self.save(s)
            result = generate(self.root, s["plan"], timeout)
            require(verify_references(s["plan"], s["references"]) == originals, "upstream references changed during extraction")
            require(s["framework"] == framework_digest(), "control plane changed during extraction")
            result.update(task=s["plan"]["task"], plan_digest=s["plan_digest"], framework=s["framework"], originals=originals,
                          attempt=dict(attempt))
            path = f".metarocq/evidence/{s['plan']['task']}-extraction-{digest(result)}.json"
            atomic_write_json(confined_path(self.root, path), result, root=self.root)
            attempt.update(status=result["status"], evidence=path, evidence_digest=digest(result))
            s.update(extraction_path=path, extraction_digest=digest(result))
            self.save(s)
            return {"status": result["status"], "evidence": path, "reason": result.get("reason"),
                    "reused": False, "attempt": attempt["number"], "claim": result["claim"]}

    def extraction_evidence(self, state):
        from .extraction import DRIVER, OUTPUTS
        from .extraction_recipe import recipe, outputs, input_hashes, frontend_files
        require("extraction_path" in state, "no captured extraction observation")
        result = read_json(confined_path(self.root, state["extraction_path"], must_exist=True))
        require(digest(result) == state["extraction_digest"], "extraction observation changed after capture")
        require(result["plan_digest"] == state["plan_digest"] and result["framework"] == state["framework"], "extraction binding mismatch")
        require(result["originals"] == verify_references(state["plan"], state["references"]), "extraction upstream binding mismatch")
        selected = recipe(self.root)
        require(result["driver_sha256"] == digest(confined_path(self.root, selected["driver"], must_exist=True).read_bytes()), "extraction driver changed")
        if (self.root / "extraction/recipe.json").exists():
            require(result.get("recipe") == selected and result.get("recipe_inputs") == input_hashes(self.root, selected),
                    "extraction recipe or support module changed")
        require(result["status"] in {"GENERATED", "BLOCKED", "FAILED"}, "unknown extraction status")
        for name, expected in frontend_files(result, selected).items():
            require(digest(confined_path(self.root, name, must_exist=True).read_bytes()) == expected,
                    "frontend checkpoint changed after extraction")
        if result["status"] == "GENERATED":
            require(set(result["outputs"]) == set(outputs(selected).values()), "incomplete extraction output inventory")
            for name, expected in result["outputs"].items():
                require(digest(confined_path(self.root, name, must_exist=True).read_bytes()) == expected, "generated output changed after extraction")
        else:
            require(not result["outputs"], "failed extraction cannot advertise successful outputs")
        return result

    def verify(self, timeout=120):
        require(type(timeout) is int and 0 < timeout <= 3600, "verification budget must be 1..3600 seconds per obligation")
        with self.locked():
            s = self.state()
            require(s["phase"] in {"BOUND", "EVIDENCE"}, "cycle already published")
            if s["plan"]["reuse"]["strategy"] == "generate":
                require(self.extraction_evidence(s)["status"] == "GENERATED", "generation is blocked or failed; cannot verify a substitute implementation")
            before = self.inputs(s)
            rows = []
            for o in s["plan"]["obligations"]:
                try:
                    rows.append(verify_one(self.root, o, timeout))
                except (OSError, ContractError, RuntimeError) as exc:
                    rows.append({"id": o["id"], "method": o["method"], "status": "BLOCKED", "reason": str(exc)})
            after = self.inputs(s)
            require(before == after, "source changed during verification; discard these results")
            require(s["framework"] == framework_digest(), "control plane changed during verification")
            evidence = {"schema": 1, "task": s["plan"]["task"], "plan_digest": s["plan_digest"],
                        "framework": s["framework"], "source": before, "results": rows,
                        "head_observed": git(self.root, "rev-parse", "HEAD").decode().strip(),
                        "claim": "scoped verifier observations; NOT a proof of the entire Rust MetaRocq prover"}
            evidence_id = digest(evidence)
            path = f".metarocq/evidence/{s['plan']['task']}-{evidence_id}.json"
            atomic_write_json(confined_path(self.root, path), evidence, root=self.root)
            s.update(phase="EVIDENCE", evidence_path=path, evidence_digest=evidence_id)
            self.save(s)
            return {"task": evidence["task"], "evidence": path,
                    "results": [{"id": x["id"], "status": x["status"]} for x in rows],
                    "claim": evidence["claim"]}

    def evidence(self, state):
        require("evidence_path" in state, "no captured verification evidence")
        evidence = read_json(confined_path(self.root, state["evidence_path"], must_exist=True))
        require(digest(evidence) == state["evidence_digest"], "evidence changed after capture")
        require(evidence["source"] == self.inputs(state), "evidence is stale for current inputs")
        require(evidence["plan_digest"] == state["plan_digest"] and evidence["framework"] == state["framework"], "evidence binding mismatch")
        require([r["id"] for r in evidence["results"]] == [o["id"] for o in state["plan"]["obligations"]], "incomplete evidence coverage")
        return evidence

    def checkpoint(self, pr):
        with self.locked():
            s = self.state()
            require(s["phase"] in {"BOUND", "EVIDENCE"}, "cycle already checkpointed")
            require(not git(self.root, "status", "--porcelain", "--untracked-files=all"), "commit all cycle work and evidence before checkpointing")
            # Bind the contract even when the Rust implementation is not yet available.
            require(read_json(confined_path(self.root, s["plan_path"], must_exist=True)) == s["plan"], "contract file drift")
            verify_references(s["plan"], s["references"])
            extraction = self.extraction_evidence(s) if "extraction_path" in s else None
            statuses = [r["status"] for r in self.evidence(s)["results"]] if "evidence_path" in s else ["UNVERIFIED"]
            receipt = attest(self.root, s["plan"]["remote"], pr)
            receipt.update(task=s["plan"]["task"], plan_digest=s["plan_digest"], statuses=statuses,
                           evidence=s.get("evidence_path"), evidence_digest=s.get("evidence_digest"),
                           extraction=s.get("extraction_path"), extraction_digest=s.get("extraction_digest"),
                           extraction_status=extraction["status"] if extraction else "UNOBSERVED",
                           extraction_attempts=s.get("extraction_attempts", []))
            s.update(phase="PUBLISHED", checkpoint=receipt)
            self.save(s)
            return receipt

    def audit(self):
        s = self.state()
        evidence = self.evidence(s)
        current = s.get("checkpoint")
        require(s["phase"] == "PUBLISHED" and current, "work is not durably checkpointed")
        require(attest(self.root, s["plan"]["remote"], current["pr"])["head"] == current["head"], "checkpoint no longer matches")
        require(all(r["status"] == "CHECKED" for r in evidence["results"]), "some obligations failed or remain blocked")
        return {"task": s["plan"]["task"], "status": "SCOPED_CHECKS_RECORDED", "checkpoint": current,
                "claim": evidence["claim"], "human_review": "required for semantic correspondence and trusted assumptions"}
