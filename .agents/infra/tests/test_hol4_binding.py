"""Binding regressions; these Python tests are not HOL4 proof evidence."""
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
from types import SimpleNamespace

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from agentinfra.contracts import ContractError
from agentinfra.hol4 import environment, hol4_home, pins, validate_mcp_probe


class Hol4Binding(unittest.TestCase):
    def test_mcp_wire_alias_is_used_and_unknown_status_fails_closed(self):
        calls = []
        def dump(**kw):
            calls.append(kw)
            return {"isError": False}
        validate_mcp_probe(SimpleNamespace(model_dump=dump))
        self.assertEqual(calls, [{"by_alias": True}])
        for data in ({}, {"isError": True}, {"isError": None}, {"isError": 0}):
            with self.subTest(data=data), self.assertRaises(ContractError):
                validate_mcp_probe(SimpleNamespace(model_dump=lambda **kw: data))

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "bin").mkdir()
        (self.root / "bin/Holmake").write_text("fixture only")

    def test_wrong_commit_and_dirty_tracked_source_are_rejected(self):
        with patch.dict(os.environ, {"HOLDIR": str(self.root)}):
            with patch("agentinfra.hol4.git", return_value=b"0" * 40):
                with self.assertRaisesRegex(ContractError, "pinned source"):
                    hol4_home()
            with patch("agentinfra.hol4.git", side_effect=[pins()["hol4_commit"].encode(), b"changed"]):
                with self.assertRaisesRegex(ContractError, "modified"):
                    hol4_home()

    def test_configured_z3_is_forwarded_and_shell_metacharacters_rejected(self):
        solver = self.root / "z3"
        solver.write_text("fixture only")
        solver.chmod(0o755)
        with patch("agentinfra.hol4.hol4_home", return_value=self.root), \
             patch.dict(os.environ, {"HOL4_Z3_EXECUTABLE": str(solver)}):
            self.assertEqual(environment(self.root)["HOL4_Z3_EXECUTABLE"], str(solver))
            unsafe = self.root / "z3;unexpected"
            unsafe.write_text("fixture only")
            unsafe.chmod(0o755)
            os.environ["HOL4_Z3_EXECUTABLE"] = str(unsafe)
            with self.assertRaisesRegex(ContractError, "shell-safe"):
                environment(self.root)


if __name__ == "__main__":
    unittest.main()
