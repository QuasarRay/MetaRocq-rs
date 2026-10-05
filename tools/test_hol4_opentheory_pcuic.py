#!/usr/bin/env python3
from pathlib import Path
import tempfile
import unittest

HERE = Path(__file__).resolve().parent
import sys
sys.path.insert(0, str(HERE))
import hol4_pcuic_core as core
import hol4_pcuic_translate as bridge


class BridgePolicyTests(unittest.TestCase):
    def test_identifiers_fail_closed(self):
        self.assertEqual(core.checked_name("PCUICTheory"), "PCUICTheory")
        self.assertEqual(core.checked_name("Hol4Imported.imported.thm_x", qualified=True), "Hol4Imported.imported.thm_x")
        for bad in ("x; rm -rf /", "../x", "A B", ""):
            with self.assertRaises(ValueError):
                core.checked_name(bad, qualified=True)

    def test_generated_rocq_rejects_unproved_holes_and_packaged_axioms(self):
        bridge.scan_rocq("Theorem t : True. Proof. exact I. Qed.\n")
        for text in (
            "Theorem t : True. Admitted.\n",
            "Axiom t : True.\n",
            "Parameter t : Prop.\n",
            "Require Import HOLLight.theorems.\n",
        ):
            with self.assertRaises(ValueError):
                bridge.scan_rocq(text)

    def test_mapping_parser(self):
        text = 'builtin "Type" ≔ hol.typ;\nbuiltin "@eq" ≔ hol.eq;\n'
        self.assertEqual(bridge.parse_mapping_sources(text), {"hol.typ", "hol.eq"})

    def test_require_qualification_rejects_unknown_modules(self):
        text = bridge.qualify_require_lines("Require coq.\nRequire Import hol.\n", {"coq", "hol"})
        self.assertIn("From Hol4Imported Require coq.", text)
        self.assertIn("From Hol4Imported Require Import hol.", text)
        with self.assertRaises(ValueError):
            bridge.qualify_require_lines("Require Evil.\n", {"coq", "hol"})

    def test_quote_rendering(self):
        t = "Require Import @IMPORT_MODULE@. Check @IMPORT_SYMBOL@. Definition @OUTPUT_NAME@ := 0."
        out = bridge.render_quote(t, import_module="Hol4Imported.imported",
                                  import_symbol="Hol4Imported.imported.thm_x",
                                  output_name="quoted")
        self.assertNotIn("@IMPORT", out)
        self.assertIn("Hol4Imported.imported.thm_x", out)

    def test_confined_rejects_escape_and_symlink(self):
        with tempfile.TemporaryDirectory() as td:
            root = Path(td).resolve()
            inside = root / "ok"
            inside.mkdir()
            self.assertEqual(core.confined(root, inside, must_exist=True), inside)
            with self.assertRaises(ValueError):
                core.confined(root, root / ".." / "escape")
            target = root / "target"
            target.mkdir()
            link = root / "link"
            link.symlink_to(target, target_is_directory=True)
            with self.assertRaises(ValueError):
                core.confined(root, link, must_exist=True)


if __name__ == "__main__":
    unittest.main()
