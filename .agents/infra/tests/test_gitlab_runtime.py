import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "aegis_gitlab_assemble", ROOT / "gitlab" / "assemble.py"
)
ASSEMBLE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(ASSEMBLE)


class GitLabRuntimeTests(unittest.TestCase):
    def test_overlay_is_small_and_does_not_define_a_second_rails_app(self):
        spec = ASSEMBLE.validate_overlay()
        targets = set(spec["files"].values())
        self.assertTrue(targets)
        self.assertFalse(targets & ASSEMBLE.FORBIDDEN_TARGETS)
        self.assertIn("config/routes/aegis.rb", targets)
        self.assertIn(
            "app/services/mcp/tools/aegis/get_supervision_state_service.rb", targets
        )

    def test_lock_pins_gitlab_and_dagger(self):
        lock = json.loads((ROOT / "gitlab" / "runtime.lock.json").read_text())
        self.assertEqual(lock["host"]["tag"], "v19.4.1")
        self.assertEqual(
            lock["host"]["commit"],
            "191678a37648bc14466c2bed346ed60eee7ddec6",
        )
        self.assertEqual(lock["dagger"]["version"], "v0.21.10")
        self.assertEqual(
            lock["dagger"]["commit"],
            "02b2558d9997a77bf5d357032c45cdf5bf7d5ce1",
        )

    def test_patch_once_is_single_application_fail_closed(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "routes.rb"
            path.write_text(ASSEMBLE.ROUTES_NEEDLE)
            ASSEMBLE.patch_once(
                path,
                ASSEMBLE.ROUTES_NEEDLE,
                ASSEMBLE.ROUTES_INSERT,
                "draw :aegis",
            )
            self.assertEqual(path.read_text().count("draw :aegis"), 1)
            with self.assertRaises(ValueError):
                ASSEMBLE.patch_once(
                    path,
                    ASSEMBLE.ROUTES_NEEDLE,
                    ASSEMBLE.ROUTES_INSERT,
                    "draw :aegis",
                )


if __name__ == "__main__":
    unittest.main()
