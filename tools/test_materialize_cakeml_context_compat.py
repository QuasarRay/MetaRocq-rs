#!/usr/bin/env python3
"""Verify exact worktree mutation boundaries, not HOL theorem validity."""
from pathlib import Path
import subprocess
import tempfile
import unittest

from materialize_cakeml_context_compat import git, materialize, compatible_theory, compatibility_key, MOD_PREFIX

ORIGINAL = "(*Temporary workaround for cache being slow on long files*)\nfun clear_cache_prover gtac  =\n let val res = TAC_PROOF gtac in res end\n"


class ContextWorktreeTests(unittest.TestCase):
    def test_grammar_is_restored_after_complete_theory_header(self):
        text = 'Theory test\nAncestors\n  arithmetic\nLibs\n  preamble\n\nTheorem example:\n  n * p MOD q = n * (p MOD q)\n'
        adapted = compatible_theory(text)
        self.assertEqual(adapted.replace(MOD_PREFIX, ''), text)
        self.assertIn('  preamble\n' + MOD_PREFIX + '\nTheorem', adapted)
        self.assertEqual(compatible_theory('Theory untouched\nAncestors arithmetic\n\nval x = 1;\n'), 'Theory untouched\nAncestors arithmetic\n\nval x = 1;\n')
        with self.assertRaises(ValueError):
            compatible_theory('unknown header\nval term = ``p MOD q``;')

    def test_theory_patch_is_part_of_worktree_recipe_and_preserves_source(self):
        old_key = compatibility_key(self.source)
        script = self.source / 'exampleScript.sml'
        original = 'Theory example\nAncestors arithmetic\n\nval x = ``p MOD q``;\n'
        script.write_text(original)
        git(self.source, 'add', '.')
        git(self.source, 'commit', '-qm', 'theory fixture')
        pin = git(self.source, 'rev-parse', 'HEAD')
        self.assertNotEqual(compatibility_key(self.source), old_key)
        receipt = materialize(self.source, self.target, pin)
        self.assertEqual(receipt['modified_files'], ['exampleScript.sml', 'misc/preamble.sml'])
        self.assertEqual(script.read_text(), original)
        self.assertEqual((self.target / 'exampleScript.sml').read_text(), compatible_theory(original))

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.source = Path(self.tmp.name) / "source"
        self.target = Path(self.tmp.name) / "derived"
        self.source.mkdir()
        subprocess.run(["git", "init", "-q", str(self.source)], check=True)
        git(self.source, "config", "user.name", "Fixture")
        git(self.source, "config", "user.email", "fixture@example.invalid")
        (self.source / "misc").mkdir()
        self.original = self.source / "misc/preamble.sml"
        self.original.write_text(ORIGINAL)
        (self.source / "other.sml").write_text("unchanged\n")
        git(self.source, "add", ".")
        git(self.source, "commit", "-qm", "fixture")
        self.pin = git(self.source, "rev-parse", "HEAD")

    def test_source_unchanged_and_exact_patch_is_idempotent(self):
        first = materialize(self.source, self.target, self.pin)
        second = materialize(self.source, self.target, self.pin)
        self.assertEqual(first, second)
        self.assertEqual(self.original.read_text(), ORIGINAL)
        self.assertEqual(git(self.source, "status", "--porcelain"), "")
        self.assertIn("Tactical.TAC_PROOF_in ctxt gtac", (self.target / "misc/preamble.sml").read_text())
        self.assertIn('Parse.set_fixity "MOD" (Infixl 650)', (self.target / "misc/preamble.sml").read_text())
        self.assertEqual(git(self.target, "diff", "HEAD", "--name-only"), "misc/preamble.sml")

    def test_unexpected_derived_progress_is_never_overwritten(self):
        materialize(self.source, self.target, self.pin)
        other = self.target / "other.sml"
        other.write_text("existing additional progress\n")
        with self.assertRaises(ValueError):
            materialize(self.source, self.target, self.pin)
        self.assertEqual(other.read_text(), "existing additional progress\n")

    def test_dirty_pinned_source_is_rejected(self):
        self.original.write_text(ORIGINAL + "changed\n")
        with self.assertRaises(ValueError):
            materialize(self.source, self.target, self.pin)
        self.assertFalse(self.target.exists())

    def test_wrong_pin_is_rejected(self):
        with self.assertRaises(ValueError):
            materialize(self.source, self.target, "0" * 40)
        self.assertFalse(self.target.exists())

    def test_link_cannot_modify_the_original_wrapper(self):
        materialize(self.source, self.target, self.pin)
        wrapper = self.target / "misc/preamble.sml"
        wrapper.unlink()
        wrapper.symlink_to(self.original)
        with self.assertRaises(ValueError):
            materialize(self.source, self.target, self.pin)
        self.assertEqual(self.original.read_text(), ORIGINAL)


if __name__ == "__main__":
    unittest.main()
