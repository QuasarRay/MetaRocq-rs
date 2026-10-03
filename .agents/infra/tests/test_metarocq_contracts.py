import copy
from dataclasses import replace
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from agentinfra.metarocq import MetaRocq
from agentinfra.checkpoints import validate_pr
from agentinfra.contracts import ContractError, FRAMEWORK, digest, read_json, source_snapshot, validate_plan
from agentinfra.process import run_process
from agentinfra.verifiers import checked_output, invocation
from agentinfra.atomic import atomic_write_bytes
from agentinfra.governance import GovernanceViolation


def plan():
    p = read_json(FRAMEWORK / "templates/metarocq-plan.json")
    p["reuse"].update(strategy="handwrite", sources=[], generator=[], license="new code", reason="No reusable binding; small direct adapter costs least.")
    p["obligations"][0].update(statement="Rust type result refines isApp under the declared representation relation.",
        assumptions=["The HOL4-to-Rust relation is independently reviewed, not established by this fixture."],
        limits=["finite model fixture, depth at most 2"])
    return p


class Contracts(unittest.TestCase):
    def test_unfilled_template_is_not_an_implementation_contract(self):
        with self.assertRaisesRegex(ContractError, "placeholders"):
            validate_plan(read_json(FRAMEWORK / "templates/metarocq-plan.json"))

    def test_retired_test_order_commands_are_not_reachable(self):
        for command in ("task", "tdd", "law", "policy", "install"):
            p = subprocess.run([sys.executable, str(FRAMEWORK / "bin/agentctl.py"), command], capture_output=True)
            self.assertNotEqual(p.returncode, 0)

    def test_uppercase_target_instruction_name_is_protected(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            p = root / "AGENTS.MD"
            p.write_text("governing instructions")
            with self.assertRaises(OSError):
                atomic_write_bytes(p, b"changed", root=root)
            self.assertEqual(p.read_text(), "governing instructions")

    def test_contract_without_test_order_fields_is_valid(self):
        self.assertEqual(validate_plan(plan())["task"], "pcuic-isapp")

    def test_generated_schema_mutants_are_rejected(self):
        mutations = [lambda p: p.update(schema=True), lambda p: p.update(extra="ignored"),
            lambda p: p.update(authority_sha256="0"*64), lambda p: p.update(obligations=[]),
            lambda p: p["obligations"].append(copy.deepcopy(p["obligations"][0])),
            lambda p: p["obligations"][0].update(expected_checks=0),
            lambda p: p["obligations"][0].update(expected_checks=True),
            lambda p: p["obligations"][0].update(method="tests"),
            lambda p: p["obligations"][0].update(anchor="invented.spec"),
            lambda p: p["obligations"][0].update(entry="x; echo success"),
            lambda p: p["obligations"][0].update(rust_paths=["../outside.rs"]),
            lambda p: p["obligations"][0].update(rust_paths=[".metarocq/evidence/trick.rs"]),
            lambda p: p["obligations"][0].update(limits=[]),
            lambda p: p["reuse"].update(reason=""),
            lambda p: p["reuse"].update(strategy="generate", generator=[]),
            lambda p: p["remote"].update(repository="../../elsewhere"),
            lambda p: p.update(adr="/outside")]
        for index, mutate in enumerate(mutations):
            with self.subTest(index=index):
                value = plan()
                mutate(value)
                with self.assertRaises(ContractError):
                    validate_plan(value)

    def test_duplicate_json_keys_are_rejected(self):
        with tempfile.TemporaryDirectory() as td:
            p = Path(td) / "p.json"
            p.write_text('{"schema":1,"schema":2}')
            with self.assertRaises(ContractError):
                read_json(p)

    def test_output_adapters_fail_closed_on_absent_duplicate_wrong_or_failed_proofs(self):
        with tempfile.TemporaryDirectory() as td:
            result = run_process([sys.executable, "-c", "pass"], cwd=Path(td))
        o = plan()["obligations"][0]
        good = "Checking harness proofs::pcuic_isapp...\n - Status: SUCCESS\nVERIFICATION:- SUCCESSFUL\nComplete - 1 successfully verified harnesses, 0 failures, 1 total.\n"
        for text in ["", good*2, good.replace("proofs::pcuic_isapp", "other"), good+" - Status: UNREACHABLE\n", good+" - Status: FAILURE\n"]:
            self.assertFalse(checked_output(o, replace(result, stdout=text)))
        self.assertTrue(checked_output(o, replace(result, stdout=good)))
        # A solver's UNSAT result establishes the assertion; it is not a cover status.
        self.assertTrue(checked_output(o, replace(result, stdout=good+"SAT checker: instance is UNSATISFIABLE\n")))
        for kwargs in ({"returncode": 1}, {"timed_out": True}, {"stdout_truncated": True}):
            self.assertFalse(checked_output(o, replace(result, stdout=good, **kwargs)))
        o.update(method="verus", entry="src/proofs.rs", expected_checks=2)
        for text in ["", "verification results:: 0 verified, 0 errors", "verification results:: 2 verified, 1 errors"]:
            self.assertFalse(checked_output(o, replace(result, stdout=text)))
        self.assertTrue(checked_output(o, replace(result, stdout="verification results:: 2 verified, 0 errors")))
        self.assertEqual(invocation(o), ["verus", "src/proofs.rs"])

    def test_pr_requires_exact_repository_base_head_and_open_state(self):
        data = {"number": 7, "state": "open", "html_url": "https://github.com/owner/repo/pull/7",
                "base": {"ref": "parent", "repo": {"full_name": "owner/repo"}},
                "head": {"sha": "a"*40, "ref": "child", "repo": {"full_name": "owner/repo"}}}
        self.assertEqual(validate_pr(data, "owner/repo", "parent", "a"*40)["pr"], 7)
        for repo, base, head in [("other/repo", "parent", "a"*40), ("owner/repo", "main", "a"*40), ("owner/repo", "parent", "b"*40)]:
            with self.assertRaises(ContractError):
                validate_pr(data, repo, base, head)
        data["state"] = "closed"
        with self.assertRaises(ContractError):
            validate_pr(data, "owner/repo", "parent", "a"*40)


class Lifecycle(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.run_git("init", "-q")
        (self.root / ".gitignore").write_text(".aegis/\n")
        (self.root / "src").mkdir()
        (self.root / "generated").mkdir()
        (self.root / "generated/pcuic_isapp.rs").write_text("// fixture only\n")
        for name in ("kernel", "proofs"):
            (self.root / f"src/{name}.rs").write_text("// fixture, no Rust proof claimed\n")
        (self.root / "docs/adr").mkdir(parents=True)
        (self.root / "docs/adr/0001-extraction-boundary.md").write_text("Fixture correspondence assumptions")
        (self.root / "plan.json").write_text(json.dumps(plan()))
        self.commit()
        self.app = MetaRocq(self.root)

    def run_git(self, *args):
        return subprocess.check_output(["git", "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", *args], cwd=self.root, stderr=subprocess.DEVNULL)

    def commit(self):
        self.run_git("add", ".")
        self.run_git("commit", "-qm", "fixture checkpoint")

    def freeze(self):
        with patch("agentinfra.metarocq.verify_references", return_value={}):
            return self.app.freeze("plan.json", {"candle": self.root, "cakeml": self.root})

    def observe(self, status="CHECKED"):
        with patch("agentinfra.metarocq.verify_references", return_value={}), patch("agentinfra.metarocq.verify_one", return_value={"id": "pcuic-isapp", "status": status}):
            return self.app.verify()

    def test_production_cycle_accepts_contract_without_failing_test_and_requires_checkpoint(self):
        self.assertEqual(self.freeze()["phase"], "BOUND")
        with self.assertRaisesRegex(ContractError, "publish"):
            self.freeze()
        self.assertEqual(self.observe()["results"][0]["status"], "CHECKED")
        self.commit()
        receipt = {"head": self.run_git("rev-parse", "HEAD").decode().strip(), "pr": 7,
                   "repository": "QuasarRay/MetaRocq-rs", "branch": "child", "base": "main", "url": "fixture"}
        with patch("agentinfra.metarocq.verify_references", return_value={}), patch("agentinfra.metarocq.attest", return_value=receipt):
            self.app.checkpoint(7)
            self.assertEqual(self.app.audit()["status"], "SCOPED_CHECKS_RECORDED")

    def test_failure_can_be_preserved_but_never_finalized_as_checked(self):
        self.freeze()
        self.observe("BLOCKED")
        self.commit()
        with patch("agentinfra.metarocq.verify_references", return_value={}), patch("agentinfra.metarocq.attest", return_value={"head": "a"*40, "pr": 7}):
            self.app.checkpoint(7)
            with self.assertRaisesRegex(ContractError, "blocked"):
                self.app.audit()

    def test_stale_source_and_evidence_and_contract_drift_are_rejected(self):
        self.freeze()
        self.observe()
        state = self.app.state()
        (self.root / "generated/pcuic_isapp.rs").write_text("changed")
        with patch("agentinfra.metarocq.verify_references", return_value={}):
            with self.assertRaisesRegex(ContractError, "stale"):
                self.app.evidence(state)
        (self.root / state["evidence_path"]).write_text("{}")
        with self.assertRaisesRegex(ContractError, "changed"):
            self.app.evidence(state)
        (self.root / "plan.json").write_text("{}")
        with self.assertRaisesRegex(ContractError, "contract file"):
            self.app.inputs(state)

    def test_source_change_during_verification_cannot_produce_evidence(self):
        self.freeze()
        def mutate(*args):
            (self.root / "generated/pcuic_isapp.rs").write_text("changed during proof")
            return {"id": "pcuic-isapp", "status": "CHECKED"}
        with patch("agentinfra.metarocq.verify_references", return_value={}), patch("agentinfra.metarocq.verify_one", side_effect=mutate):
            with self.assertRaisesRegex(ContractError, "source changed"):
                self.app.verify()
        self.assertFalse((self.root / ".metarocq/evidence").exists())

    def test_source_snapshot_includes_untracked_inputs_and_rejects_symlinks(self):
        before = source_snapshot(self.root)
        (self.root / "new.rs").write_text("new")
        self.assertNotEqual(source_snapshot(self.root), before)
        (self.root / "linked.rs").symlink_to(self.root / "new.rs")
        with self.assertRaises(RuntimeError):
            source_snapshot(self.root)

    def test_uncommitted_work_cannot_be_called_durable(self):
        self.freeze()
        (self.root / "generated/pcuic_isapp.rs").write_text("uncommitted")
        with self.assertRaisesRegex(ContractError, "commit all"):
            self.app.checkpoint(7)

    def extraction_fixture(self, status="GENERATED"):
        from agentinfra.extraction import DRIVER, OUTPUTS
        (self.root / DRIVER).parent.mkdir(exist_ok=True)
        (self.root / DRIVER).write_text("(* fixture; not a proof *)")
        outputs = {}
        if status == "GENERATED":
            for name in OUTPUTS.values():
                (self.root / name).parent.mkdir(exist_ok=True)
                (self.root / name).write_text("fixture generated output")
                outputs[name] = digest((self.root / name).read_bytes())
        self.freeze()
        result = {"status": status, "driver_sha256": digest((self.root / DRIVER).read_bytes()),
                  "outputs": outputs, "claim": "fixture only"}
        with patch("agentinfra.metarocq.verify_references", return_value={}), \
             patch("agentinfra.extraction.generate", return_value=result):
            self.app.extract()
        return self.app.state()

    def test_extraction_digest_driver_and_output_tampering_are_rejected(self):
        state = self.extraction_fixture()
        with patch("agentinfra.metarocq.verify_references", return_value={}):
            self.assertEqual(self.app.extraction_evidence(state)["status"], "GENERATED")
            p = self.root / "generated/pcuic_isapp.rs"
            p.write_text("substituted implementation")
            with self.assertRaisesRegex(ContractError, "output changed"):
                self.app.extraction_evidence(state)
            p.write_text("fixture generated output")
            (self.root / "extraction/Bootstrap.v").write_text("different extraction")
            with self.assertRaisesRegex(ContractError, "driver changed"):
                self.app.extraction_evidence(state)
        (self.root / state["extraction_path"]).write_text("{}")
        with self.assertRaisesRegex(ContractError, "observation changed"):
            self.app.extraction_evidence(state)

    def test_blocked_generation_cannot_be_promoted_to_verification(self):
        p = plan()
        p["reuse"].update(strategy="generate", sources=["fixture"], generator=["fixture-generator"])
        (self.root / "plan.json").write_text(json.dumps(p))
        self.extraction_fixture("BLOCKED")
        with patch("agentinfra.metarocq.verify_references", return_value={}), \
             patch("agentinfra.metarocq.verify_one") as verifier:
            with self.assertRaisesRegex(ContractError, "generation is blocked"):
                self.app.verify()
            verifier.assert_not_called()

    def test_intact_generation_is_reused_without_another_process(self):
        self.extraction_fixture()
        with patch("agentinfra.metarocq.verify_references", return_value={}), \
             patch("agentinfra.extraction.generate") as compiler:
            self.assertTrue(self.app.extract()["reused"])
            self.assertEqual(len(self.app.state()["extraction_attempts"]), 1)
            compiler.assert_not_called()

    def test_retry_needs_diagnosis_changed_inputs_and_remaining_budget(self):
        self.extraction_fixture("FAILED")
        driver = self.root / "extraction/Bootstrap.v"
        with patch("agentinfra.metarocq.verify_references", return_value={}), \
             patch("agentinfra.extraction.generate") as compiler:
            with self.assertRaisesRegex(ContractError, "diagnosis"):
                self.app.extract()
            with self.assertRaisesRegex(ContractError, "unchanged"):
                self.app.extract(retry_diagnosis="Blind retry must not launch")
            # A documentation edit is not a change to generation inputs.
            (self.root / "docs/diagnosis.md").write_text("diagnosis only")
            with self.assertRaisesRegex(ContractError, "unchanged"):
                self.app.extract(retry_diagnosis="Added a note only")
            compiler.assert_not_called()
            driver.write_text("(* corrected driver fixture *)")
            compiler.return_value = {"status": "FAILED", "outputs": {}, "claim": "fixture only",
                                     "driver_sha256": digest(driver.read_bytes())}
            self.app.extract(retry_diagnosis="Corrected the unsupported frontend command")
            driver.write_text("(* third fixture *)")
            with self.assertRaisesRegex(ContractError, "budget exhausted"):
                self.app.extract(retry_diagnosis="Third attempt must require a checkpoint")
            self.assertEqual(compiler.call_count, 1)
            self.assertEqual(len(self.app.state()["extraction_attempts"]), 2)

    def test_interruption_reserves_budget_and_does_not_keep_stale_active_evidence(self):
        self.extraction_fixture("FAILED")
        (self.root / "extraction/Bootstrap.v").write_text("(* corrected driver *)")
        with patch("agentinfra.metarocq.verify_references", return_value={}), \
             patch("agentinfra.extraction.generate", side_effect=RuntimeError("interrupted")):
            with self.assertRaisesRegex(RuntimeError, "interrupted"):
                self.app.extract(retry_diagnosis="Corrected frontend command")
        restarted = MetaRocq(self.root)
        state = restarted.state()
        self.assertEqual(state["extraction_attempts"][-1]["status"], "RESERVED")
        self.assertNotIn("extraction_path", state)
        with patch("agentinfra.metarocq.verify_references", return_value={}), \
             patch("agentinfra.extraction.generate") as compiler:
            with self.assertRaisesRegex(ContractError, "budget exhausted"):
                restarted.extract(retry_diagnosis="Restart cannot reset attempts")
            compiler.assert_not_called()

    def test_budget_limits_are_enforced_before_tool_execution(self):
        self.freeze()
        with patch("agentinfra.metarocq.verify_references", return_value={}), \
             patch("agentinfra.extraction.generate") as compiler:
            for timeout in (True, 0, -1, 601):
                with self.assertRaisesRegex(ContractError, "time budget"):
                    self.app.extract(timeout)
            compiler.assert_not_called()


if __name__ == "__main__":
    unittest.main()
