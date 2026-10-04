import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]


class AstraReviewPacketTests(unittest.TestCase):
    def test_must_read_paths_exist(self):
        packet = json.loads((ROOT / "spec/astra-architecture-review.json").read_text())
        for relative in packet["must_read"]:
            self.assertTrue((ROOT / relative).is_file(), relative)

    def test_review_surface_is_bounded(self):
        packet = json.loads((ROOT / "spec/astra-architecture-review.json").read_text())
        self.assertLessEqual(len(packet["must_read"]), 8)
        self.assertLessEqual(len(packet["review_questions"]), 4)

    def test_registry_prefers_native_gitlab_rails_vocabulary(self):
        registry = json.loads((ROOT / "research/ruby-metaprogramming/registry.json").read_text())
        by_name = {item["name"]: item for item in registry["candidates"]}
        self.assertEqual(
            by_name["Rails / ActiveSupport + ActiveModel + ActiveRecord DSLs"]["decision"],
            "prefer",
        )
        self.assertEqual(by_name["GitLab DeclarativePolicy"]["decision"], "prefer")
        self.assertEqual(by_name["ActiveAdmin"]["decision"], "reject_for_aegis_runtime")
        self.assertEqual(by_name["Trailblazer"]["decision"], "reject_for_core")

    def test_hidden_generated_behavior_requires_expansion_index(self):
        registry = json.loads((ROOT / "research/ruby-metaprogramming/registry.json").read_text())
        self.assertIn("machine-readable expansion", registry["policy"]["expansion_rule"])


if __name__ == "__main__":
    unittest.main()
