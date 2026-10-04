import importlib.util
import json
import os
from pathlib import Path
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "aegis_control_plane", ROOT / "scripts" / "control_plane.py"
)
CONTROL = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CONTROL)


class ControlPlaneAdoptionTests(unittest.TestCase):
    def test_auto_prefers_ready_gitlab(self):
        result = CONTROL.select_mode("auto", probe={"configured": True, "ready": True, "reason": "ready"})
        self.assertEqual(result["selected"], "gitlab")
        self.assertFalse(result["degraded"])

    def test_auto_falls_back_to_legacy_for_gitlab_fault(self):
        result = CONTROL.select_mode(
            "auto",
            probe={"configured": True, "ready": False, "reason": "transport failure"},
        )
        self.assertEqual(result["selected"], "legacy")
        self.assertTrue(result["degraded"])

    def test_explicit_gitlab_fails_closed(self):
        result = CONTROL.select_mode(
            "gitlab",
            probe={"configured": True, "ready": False, "reason": "not ready"},
        )
        self.assertEqual(result["selected"], "blocked")

    def test_explicit_legacy_never_probes_gitlab(self):
        with patch.object(CONTROL, "probe_gitlab", side_effect=AssertionError("unexpected probe")):
            result = CONTROL.select_mode("legacy")
        self.assertEqual(result["selected"], "legacy")

    def test_legacy_qualification_is_dependency_light(self):
        result = CONTROL.legacy_validate(ROOT)
        self.assertTrue(result["validated"])
        self.assertIn("postgresql_driver", result["execution_dependencies"])

    def test_packet_keeps_initial_review_small(self):
        packet = json.loads((ROOT / "spec/astra-adoption.json").read_text())
        self.assertLessEqual(len(packet["must_read"]), packet["review_budget"]["must_read_limit"])
        for relative in packet["must_read"]:
            self.assertTrue((ROOT / relative).is_file(), relative)

    def test_formal_and_persistence_failures_never_fallback(self):
        packet = json.loads((ROOT / "spec/astra-adoption.json").read_text())
        by_fault = {item["fault"]: item["action"] for item in packet["fault_matrix"]}
        self.assertEqual(by_fault["PostgreSQL/event persistence unavailable"], "block")
        self.assertEqual(by_fault["formal verifier or independent replay failure"], "block")
        self.assertEqual(by_fault["metatheory-verified is closed"], "block implementation")

    def test_unconfigured_auto_is_legacy_not_degraded_fault(self):
        result = CONTROL.select_mode(
            "auto",
            probe={"configured": False, "ready": False, "reason": "not configured"},
        )
        self.assertEqual(result["selected"], "legacy")
        self.assertFalse(result["degraded"])

    def test_failed_delegation_never_qualifies_legacy(self):
        # Exit 1 includes a failed remote pipeline; exit 2 includes an exact
        # SHA mismatch or an uncertain transport failure after dispatch.
        for mode in ("auto", "gitlab"):
            for code in (1, 2):
                with self.subTest(mode=mode, code=code), \
                     patch.dict(os.environ, {"AEGIS_CONTROL_PLANE_MODE": mode}), \
                     patch.object(CONTROL, "select_mode", return_value={"selected": "gitlab"}), \
                     patch.object(CONTROL, "run", return_value={"ok": False, "returncode": code}), \
                     patch.object(CONTROL, "legacy_validate") as fallback:
                    with self.assertRaisesRegex(RuntimeError, "cannot replace"):
                        CONTROL.ci(ROOT, prevalidated=True)
                    fallback.assert_not_called()

    def test_skipped_remote_pipeline_is_not_execution_success(self):
        spec = importlib.util.spec_from_file_location(
            "aegis_github_bridge_control", ROOT / "gitlab/github_actions_bridge.py")
        bridge = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(bridge)
        sha = "a" * 40
        env = {"AEGIS_GITLAB_URL": "https://gitlab.invalid",
               "AEGIS_GITLAB_PROJECT": "project", "AEGIS_GITLAB_API_TOKEN": "test",
               "AEGIS_GITLAB_REF": "main", "AEGIS_GITHUB_SHA": sha}
        replies = [{"id": 1, "sha": sha}, {"id": 1, "sha": sha, "status": "skipped"}]
        with patch.dict(os.environ, env), patch.object(bridge, "request", side_effect=replies):
            self.assertEqual(bridge.main(), 1)


if __name__ == "__main__":
    unittest.main()
