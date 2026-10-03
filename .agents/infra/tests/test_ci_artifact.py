"""Adversarial packet fixtures; no compiler or proof output is fabricated as evidence."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import warnings
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from agentinfra.ci_artifact import inspect
from agentinfra.contracts import ContractError, digest, source_snapshot


class Artifact(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.root = self.base / "repo"
        self.root.mkdir()
        self.git("init", "-q")
        (self.root / "extraction").mkdir()
        (self.root / ".metarocq").mkdir()
        (self.root / "extraction/Bootstrap.v").write_text("fixture driver")
        (self.root / ".metarocq/plan.json").write_text("{}")
        self.git("add", ".")
        self.git("commit", "-qm", "fixture")
        self.head = self.git("rev-parse", "HEAD").decode().strip()
        self.manifest = {"schema": 1, "commit": "1" * 40, "head": self.head,
                         "run_id": "42", "attempt": "1", "claim": "fixture only",
                         "steps": {"preflight": "success", "install": "failure",
                                   "extract": "skipped", "compile": "skipped"}, "files": {}}
        self.members = {}

    def git(self, *args):
        return subprocess.check_output(["git", "-c", "user.name=Fixture", "-c",
            "user.email=fixture@example.invalid", *args], cwd=self.root, stderr=subprocess.DEVNULL)

    def archive(self):
        archive = self.base / "fixture.zip"
        self.manifest["files"] = {n: digest(b) for n, b in self.members.items()}
        with zipfile.ZipFile(archive, "w") as z:
            z.writestr("run.json", json.dumps(self.manifest))
            for name, content in self.members.items():
                z.writestr(name, content)
        return archive

    def inspect(self, archive=None, **kw):
        archive = archive or self.archive()
        args = {"expected_run": 42, "expected_head": self.head,
                "expected_sha256": digest(archive.read_bytes()), **kw}
        return inspect(self.root, archive, **args)

    def generated(self):
        self.manifest["steps"] = dict.fromkeys(self.manifest["steps"], "success")
        self.members = {"generated/pcuic_isapp.ast": b"fixture AST", "generated/pcuic_isapp.rs": b"fixture Rust",
                        ".aegis/opam-switch.export": b"fixture packages", "Cargo.lock": b"fixture dependencies"}
        result = {"status": "GENERATED", "plan_digest": digest({}),
                  "driver_sha256": digest(b"fixture driver"), "source": source_snapshot(self.root),
                  "outputs": {n: digest(self.members[n]) for n in self.members if n.startswith("generated/")}}
        name = ".metarocq/evidence/fixture-extraction-" + digest(result) + ".json"
        self.members[name] = json.dumps(result).encode()

    def test_failed_installation_is_not_generation(self):
        result = self.inspect()
        self.assertEqual(result["status"], "CONSISTENT")
        self.assertFalse(result["generated"])
        self.assertFalse(result["compiled"])

    def test_bound_output_reports_only_process_consistency(self):
        self.generated()
        result = self.inspect()
        self.assertTrue(result["compiled"])
        self.assertIn("no authenticated", result["claim"])

    def test_expanded_budget_is_explicit_bounded_and_does_not_skip_hashes(self):
        # A compact ZIP with a real oversized member, not a fabricated pass.
        self.members[".aegis/opam-switch.export"] = b"x" * (1024 * 1024 + 1)
        self.manifest["files"] = {n: digest(b) for n, b in self.members.items()}
        archive = self.base / "large.zip"
        with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED) as z:
            z.writestr("run.json", json.dumps(self.manifest))
            for name, data in self.members.items():
                z.writestr(name, data)
        with self.assertRaisesRegex(ContractError, "exceeds inspection budget"):
            self.inspect(archive, max_expanded_mib=1)
        result = self.inspect(archive, max_expanded_mib=2)
        self.assertGreater(result["expanded_bytes"], 1024 * 1024)
        self.assertEqual(result["max_expanded_mib"], 2)
        for budget in (0, 257, True, 1.5):
            with self.subTest(budget=budget), self.assertRaisesRegex(ContractError, "budget must"):
                self.inspect(archive, max_expanded_mib=budget)
        with self.assertRaisesRegex(ContractError, "independently observed"):
            self.inspect(archive, max_expanded_mib=256, expected_sha256="0" * 64)

    def add_frontend(self, *, failed=False, content=b"fixture AST"):
        old = next(n for n in self.members if n.endswith(".json"))
        observation = json.loads(self.members.pop(old))
        sha = digest(content)
        name = f".metarocq/evidence/frontend-{sha}.ast"
        observation["frontend"] = {"generated/pcuic_isapp.ast": {"path": name, "sha256": sha}}
        self.members[name] = content
        if failed:
            observation.update(status="FAILED", outputs={})
            self.manifest["steps"].update(extract="failure", compile="skipped")
            self.members = {n: b for n, b in self.members.items() if not n.startswith("generated/")}
        self.members[".metarocq/evidence/fixture-extraction-" + digest(observation) + ".json"] = json.dumps(observation).encode()
        return name

    def test_frontend_survives_backend_failure_without_claiming_generation(self):
        self.generated()
        name = self.add_frontend(failed=True)
        result = self.inspect()
        self.assertEqual(result["frontend_preserved"], ["generated/pcuic_isapp.ast"])
        self.assertFalse(result["generated"])
        self.assertFalse(result["compiled"])
        del self.members[name]
        with self.assertRaisesRegex(ContractError, "frontend checkpoint missing"):
            self.inspect()

    def test_frontend_cannot_disagree_with_published_ast(self):
        self.generated()
        self.add_frontend(content=b"different AST")
        with self.assertRaisesRegex(ContractError, "differs from published AST"):
            self.inspect()

    def test_stale_rust_after_skipped_generation_is_rejected(self):
        self.members["generated/pcuic_isapp.rs"] = b"previous candidate"
        with self.assertRaisesRegex(ContractError, "advertises candidate"):
            self.inspect()

    def test_missing_generation_and_false_compilation_are_rejected(self):
        self.manifest["steps"]["compile"] = "success"
        with self.assertRaisesRegex(ContractError, "prerequisite"):
            self.inspect()
        self.generated()
        del self.members["generated/pcuic_isapp.rs"]
        with self.assertRaisesRegex(ContractError, "missing outputs"):
            self.inspect()

    def test_external_identity_and_member_hashes_are_checked(self):
        archive = self.archive()
        for changes in ({"expected_sha256": "0" * 64}, {"expected_run": 43}, {"expected_head": "0" * 40}):
            with self.subTest(changes=changes), self.assertRaises(ContractError):
                self.inspect(archive, **changes)
        self.generated()
        archive = self.archive()
        with zipfile.ZipFile(archive) as z:
            members = {n: z.read(n) for n in z.namelist()}
        members["Cargo.lock"] = b"changed after manifest"
        with zipfile.ZipFile(archive, "w") as z:
            for n, b in members.items(): z.writestr(n, b)
        with self.assertRaisesRegex(ContractError, "digest mismatch"):
            self.inspect(archive)

    def test_duplicate_and_traversing_zip_members_are_rejected(self):
        archive = self.archive()
        with warnings.catch_warnings():
            warnings.simplefilter("ignore", UserWarning)
            with zipfile.ZipFile(archive, "a") as z:
                z.writestr("run.json", "{}")
        with self.assertRaisesRegex(ContractError, "duplicate ZIP"):
            self.inspect(archive)
        self.members["../escape"] = b"not extracted"
        with self.assertRaisesRegex(ContractError, "noncanonical"):
            self.inspect()
        self.assertFalse((self.base / "escape").exists())

    def test_legacy_artifact_does_not_count_as_current_progress(self):
        archive = self.base / "old.zip"
        with zipfile.ZipFile(archive, "w") as z:
            z.writestr("generated/README.md", "No output yet")
        with self.assertRaisesRegex(ContractError, "historical files"):
            self.inspect(archive)

    def test_changed_checkout_is_not_accepted(self):
        self.generated()
        (self.root / "extraction/Bootstrap.v").write_text("changed")
        with self.assertRaisesRegex(ContractError, "unchanged checkout"):
            self.inspect()


if __name__ == "__main__":
    unittest.main()
