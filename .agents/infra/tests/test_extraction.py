"""Adversarial recorder tests. Mock compiler output is never proof evidence."""
from dataclasses import replace
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from agentinfra.contracts import ContractError
from agentinfra.extraction import generate, tool_identity
from agentinfra.process import run_process


class Extraction(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        (self.root / ".gitignore").write_text(".aegis/\n")
        (self.root / "extraction").mkdir()
        (self.root / "extraction/Bootstrap.v").write_text("(* fixture only *)\n")
        self.plan = {"reuse": {"strategy": "generate"}, "obligations": [{
            "anchor": "pcuic/theories/PCUICAst.v", "symbol": "isApp",
            "rust_paths": ["generated/pcuic_isapp.rs"]}]}
        self.identity = {n: {"path": n, "sha256": "0" * 64} for n in ("rocq", "peregrine")}
        self.process = run_process([sys.executable, "-c", "pass"], cwd=self.root)

    def compiler(self, argv, *, cwd, **kwargs):
        name = "candidate.ast" if argv[0] == "rocq" else "candidate.rs"
        (cwd / name).write_text("fixture output; not executable proof\n")
        return self.process

    def run_fixture(self, compiler=None):
        with patch("agentinfra.extraction.tool_identity", return_value=self.identity), \
             patch("agentinfra.extraction.run_process", side_effect=compiler or self.compiler):
            return generate(self.root, self.plan, 30)

    def test_missing_tool_is_blocked_without_generated_files(self):
        with patch("agentinfra.extraction.tool_identity", side_effect=ContractError("missing rocq")):
            r = generate(self.root, self.plan, 30)
        self.assertEqual(r["status"], "BLOCKED")
        self.assertEqual(r["executions"], [])
        self.assertFalse((self.root / "generated").exists())

    def test_tool_discovery_requires_both_tools(self):
        with patch("agentinfra.extraction.shutil.which", return_value=None):
            with self.assertRaisesRegex(ContractError, "unavailable"):
                tool_identity()

    def test_generated_means_only_observed_outputs(self):
        r = self.run_fixture()
        self.assertEqual(r["status"], "GENERATED")
        self.assertEqual(len(r["outputs"]), 2)
        self.assertIn("unverified", r["claim"])
        self.assertNotIn("CHECKED", r.values())

    def test_zero_exit_without_ast_does_not_run_backend(self):
        with patch("agentinfra.extraction.tool_identity", return_value=self.identity), \
             patch("agentinfra.extraction.run_process", return_value=self.process) as process:
            r = generate(self.root, self.plan, 30)
        self.assertEqual(r["status"], "FAILED")
        self.assertEqual(process.call_count, 1)
        self.assertFalse((self.root / "generated").exists())

    def test_backend_failure_preserves_existing_outputs(self):
        (self.root / "generated").mkdir()
        output = self.root / "generated/pcuic_isapp.rs"
        output.write_text("old candidate")
        def compiler(argv, **kw):
            result = self.compiler(argv, **kw)
            return replace(result, returncode=1) if argv[0] == "peregrine" else result
        result = self.run_fixture(compiler)
        self.assertEqual(result["status"], "FAILED")
        intermediate = result["frontend"]["generated/pcuic_isapp.ast"]
        self.assertEqual((self.root / intermediate["path"]).read_text(), "fixture output; not executable proof\n")
        self.assertEqual(result["outputs"], {})
        self.assertEqual(output.read_text(), "old candidate")
        self.assertFalse((self.root / "generated/pcuic_isapp.ast").exists())

    def test_redirected_frontend_checkpoint_is_rejected(self):
        (self.root / ".metarocq").mkdir()
        (self.root / ".metarocq/evidence").symlink_to(self.root / "extraction", target_is_directory=True)
        with self.assertRaises(RuntimeError):
            self.run_fixture()
        self.assertFalse((self.root / "generated").exists())

    def test_truncated_output_and_timeouts_are_not_success(self):
        for change in ({"timed_out": True}, {"stdout_truncated": True}, {"stderr_truncated": True}):
            with self.subTest(change=change):
                self.assertEqual(self.run_fixture(lambda *a, **kw: replace(self.process, **change))["status"], "FAILED")

    def test_changed_source_prevents_output_publication(self):
        def compiler(argv, **kw):
            result = self.compiler(argv, **kw)
            if argv[0] == "peregrine":
                (self.root / "extraction/Bootstrap.v").write_text("changed")
            return result
        r = self.run_fixture(compiler)
        self.assertEqual(r["status"], "FAILED")
        self.assertIn("source changed", r["reason"])
        self.assertFalse((self.root / "generated").exists())

    def test_redirected_output_is_rejected(self):
        (self.root / "generated").symlink_to(self.root / "extraction", target_is_directory=True)
        # The source snapshot rejects even before launching the generator.
        with self.assertRaises(RuntimeError):
            self.run_fixture()

    def test_invalid_budget_or_unrelated_contract_is_rejected(self):
        for budget in (0, True, 3601):
            with self.assertRaises(ContractError):
                generate(self.root, self.plan, budget)
        self.plan["obligations"][0]["symbol"] = "typecheck_program"
        with self.assertRaisesRegex(ContractError, "only"):
            generate(self.root, self.plan, 30)

    def configure_retention(self):
        value = {"schema": 1, "driver": "extraction/Bootstrap.v",
                 "support": ["extraction/Retention.v"], "units": [{
                     "stem": "candidate", "ast": "generated/retained.ast", "rust": "generated/retained.rs"}]}
        (self.root / "extraction/Retention.v").write_text("fixture support")
        (self.root / "extraction/recipe.json").write_text(json.dumps(value))
        self.plan["obligations"][0]["rust_paths"].append("generated/retained.rs")
        return value

    def test_recipe_binds_support_and_output_scope(self):
        self.configure_retention()
        result = self.run_fixture()
        self.assertEqual(result["status"], "GENERATED")
        self.assertEqual(len(result["executions"]), 3)
        self.assertIn("extraction/Retention.v", result["recipe_inputs"])
        self.assertEqual(set(result["outputs"]), {"generated/retained.ast", "generated/retained.rs"})
        self.plan["obligations"][0]["rust_paths"].remove("generated/retained.rs")
        with self.assertRaisesRegex(ContractError, "obligation"):
            self.run_fixture()

    def test_recipe_cannot_escape_or_alias_destinations(self):
        value = self.configure_retention()
        for update in ({"driver": "../escape.v"}, {"support": ["extraction/Bootstrap.v"]},
                       {"units": value["units"] * 2}):
            (self.root / "extraction/recipe.json").write_text(json.dumps({**value, **update}))
            with self.assertRaises(ContractError):
                self.run_fixture()

    def test_changed_support_prevents_publication(self):
        self.configure_retention()
        def compiler(argv, **kw):
            result = self.compiler(argv, **kw)
            (self.root / "extraction/Retention.v").write_text("changed support")
            return result
        result = self.run_fixture(compiler)
        self.assertEqual(result["status"], "FAILED")
        self.assertFalse((self.root / "generated/retained.rs").exists())

    def test_missing_second_unit_never_publishes_partial_results(self):
        value = self.configure_retention()
        value["units"].append({"stem": "missing", "ast": "generated/missing.ast", "rust": "generated/missing.rs"})
        (self.root / "extraction/recipe.json").write_text(json.dumps(value))
        self.plan["obligations"][0]["rust_paths"].append("generated/missing.rs")
        result = self.run_fixture()
        self.assertEqual(result["status"], "FAILED")
        self.assertFalse((self.root / "generated/retained.rs").exists())

    def test_unused_legacy_driver_cannot_unlock_recipe_retry(self):
        from agentinfra.extraction_budget import attempt_inputs
        value = self.configure_retention()
        value["driver"] = "extraction/Retained.v"
        (self.root / "extraction/Retained.v").write_text("actual driver")
        (self.root / "extraction/recipe.json").write_text(json.dumps(value))
        with patch("agentinfra.extraction_budget.tool_identity", return_value=self.identity):
            before = attempt_inputs(self.root, 30)
            (self.root / "extraction/Bootstrap.v").write_text("unrelated change")
            self.assertEqual(before, attempt_inputs(self.root, 30))
