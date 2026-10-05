import copy
from pathlib import Path
import subprocess
import tempfile
import unittest

from materialize_original_source_bundle import materialize, git


class OriginalSourceBundleTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.refs = self.root / "references"
        self.output = self.root / "bundle"
        self.lock = {"repositories": {}}
        for name, prefix, destination in [("metarocq", "MetaRocq.Core", "."),
                                          ("rocq", "Corelib", "vendor/rocq"),
                                          ("peregrine", "Peregrine", "vendor/peregrine")]:
            source = self.refs / name
            (source / "theories").mkdir(parents=True)
            (source / "theories/Test.v").write_text("Definition test : nat := 0.\n")
            (source / "kernel.ml").write_text("let source_only = 0\n")
            (source / "LICENSE").write_text("Fixture license, not a proof.\n")
            (source / "_CoqProject").write_text(f"-Q theories {prefix}\ntheories/Test.v\n")
            (source / "source-link").symlink_to("LICENSE")
            subprocess.run(["git", "init", "-q", str(source)], check=True)
            subprocess.run(["git", "-C", str(source), "add", "."], check=True)
            subprocess.run(["git", "-C", str(source), "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
                            "commit", "-qm", "source fixture"], check=True)
            self.lock["repositories"][name] = {"repository": "https://github.com/example/fixture.git",
                                               "commit": git(source, "rev-parse", "HEAD"), "destination": destination,
                                               "module_projects": "_CoqProject"}

    def test_complete_physical_nested_sources_and_idempotent_receipt(self):
        first = materialize(self.lock, self.refs, self.output)
        second = materialize(self.lock, self.refs, self.output)
        self.assertEqual(first, second)
        self.assertEqual(first["module_count"], 3)
        self.assertEqual(first["unmapped_gallina_count"], 0)
        for name, pin in self.lock["repositories"].items():
            target = self.output / pin["destination"]
            self.assertTrue((target / "LICENSE").is_file())
            self.assertTrue((target / "source-link").is_symlink())
            self.assertEqual(first["repositories"][name]["counts"], {"tracked": 5, "Gallina": 1, "OCaml": 1, "other": 3})
            self.assertEqual(git(self.refs / name, "status", "--porcelain"), "")

    def test_dirty_reference_is_not_overwritten(self):
        source = self.refs / "rocq" / "kernel.ml"
        source.write_text("preserve this progress\n")
        with self.assertRaisesRegex(ValueError, "tracked source changes"):
            materialize(self.lock, self.refs, self.output)
        self.assertEqual(source.read_text(), "preserve this progress\n")

    def test_dirty_vendored_source_is_not_overwritten(self):
        materialize(self.lock, self.refs, self.output)
        source = self.output / "vendor/peregrine/theories/Test.v"
        source.write_text("preserve this progress\n")
        with self.assertRaisesRegex(ValueError, "tracked source changes"):
            materialize(self.lock, self.refs, self.output)
        self.assertEqual(source.read_text(), "preserve this progress\n")

    def test_unmapped_gallina_is_counted_and_preserved(self):
        source = self.refs / "rocq"
        (source / "outside.v").write_text("Fail Check absent.\n")
        subprocess.run(["git", "-C", str(source), "add", "."], check=True)
        subprocess.run(["git", "-C", str(source), "-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid",
                        "commit", "-qm", "unmapped fixture"], check=True)
        self.lock["repositories"]["rocq"]["commit"] = git(source, "rev-parse", "HEAD")
        result = materialize(self.lock, self.refs, self.output)
        self.assertEqual(result["unmapped_gallina_count"], 1)
        self.assertEqual(result["repositories"]["rocq"]["unmapped_gallina"], ["outside.v"])
        self.assertTrue((self.output / "vendor/rocq/outside.v").is_file())

    def test_namespace_collision_is_reported(self):
        self.lock["repositories"]["rocq"].pop("module_projects")
        self.lock["repositories"]["rocq"]["module_roots"] = {"theories": "MetaRocq.Core"}
        with self.assertRaisesRegex(ValueError, "namespace collision"):
            materialize(self.lock, self.refs, self.output)

    def test_escaping_vendor_destination_is_rejected(self):
        self.lock["repositories"]["rocq"]["destination"] = "../escape"
        with self.assertRaisesRegex(ValueError, "escapes"):
            materialize(self.lock, self.refs, self.output)
        self.assertFalse((self.root / "escape").exists())

    def test_edited_generated_manifest_is_preserved(self):
        materialize(self.lock, self.refs, self.output)
        manifest = self.output / "selfhost/generated/UnifiedModuleManifest.v"
        manifest.write_text("preserve this progress\n")
        with self.assertRaisesRegex(ValueError, "refusing to overwrite"):
            materialize(self.lock, self.refs, self.output)
        self.assertEqual(manifest.read_text(), "preserve this progress\n")


if __name__ == "__main__":
    unittest.main()
