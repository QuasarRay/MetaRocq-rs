import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]


class GithubBridgeOverlayTests(unittest.TestCase):
    def test_bridge_is_optional_and_writes_need_host_mapping(self):
        source = (ROOT / "gitlab/overlay/github_bridge_configuration.rb").read_text()
        self.assertIn("AEGIS_GITHUB_REPOSITORY_MAP", source)
        self.assertIn("AEGIS_GITHUB_AUTO_MAP", source)
        self.assertIn("writable: false, mapping_source: 'auto-map'", source)
        self.assertIn("writable?", source)

    def test_mutation_surface_is_explicit(self):
        source = (ROOT / "gitlab/overlay/github_bridge_mutation_service.rb").read_text()
        for operation in (
            "create_branch",
            "create_pull_request",
            "merge_pull_request",
            "rerun_failed_workflow",
            "dispatch_workflow",
            "update_repository_settings",
            "update_branch_protection",
            "update_ruleset",
            "publish_commit_status",
        ):
            self.assertIn(f"'{operation}'", source)
        self.assertIn("expected_head_sha", source)
        self.assertIn("configuration.writable?", source)

    def test_overlay_stays_inside_one_gitlab_rails_app(self):
        mapping = json.loads((ROOT / "gitlab/overlay/overlay.json").read_text())["files"]
        targets = set(mapping.values())
        self.assertIn("app/controllers/aegis/github_controller.rb", targets)
        self.assertIn("app/services/aegis/github_bridge/client.rb", targets)
        self.assertIn("app/services/mcp/tools/aegis/mutate_github_service.rb", targets)
        self.assertNotIn("config/application.rb", targets)
        self.assertNotIn("Gemfile", targets)

    def test_public_github_uses_gitlab_clients_default_api_endpoint(self):
        source = (ROOT / "gitlab/overlay/github_bridge_client.rb").read_text()
        self.assertIn("host == 'github.com' ? nil", source)

    def test_github_actions_bridge_requires_exact_mirror_sha(self):
        source = (ROOT / "gitlab/github_actions_bridge.py").read_text()
        self.assertIn("gitlab_sha != github_sha", source)
        self.assertIn("GitLab pipeline SHA changed during polling", source)

    def test_gitlab_github_client_is_pinned(self):
        lock = json.loads((ROOT / "gitlab/runtime.lock.json").read_text())
        anchors = lock["anchors"]
        self.assertEqual(
            anchors["lib/gitlab/github_import/client.rb"],
            "2928d0f30f7385014055081ad1b31e9d785a6ebc",
        )
        self.assertEqual(lock["github_bridge"]["authority"], "optional_external_forge_not_boot_dependency")


if __name__ == "__main__":
    unittest.main()
