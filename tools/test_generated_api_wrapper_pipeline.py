#!/usr/bin/env python3
import json
import pathlib
import tempfile
import unittest
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[1]
EXTRACT = ROOT / "tools/extract_sml_public_api.py"
RENDER = ROOT / "tools/render_api_contract_cml.py"
SPEC = ROOT / "spec/generated-sml-api-wrapper-pipeline.json"


class GeneratedApiWrapperTests(unittest.TestCase):
    def fixture(self, root: pathlib.Path) -> pathlib.Path:
        (root / "src/HolSmt").mkdir(parents=True)
        (root / "src/tactictoe/src").mkdir(parents=True)
        (root / "src/1").mkdir(parents=True)
        (root / "src/0").mkdir(parents=True)
        (root / "src/HolSmt/HolSmtLib.sig").write_text(
            "signature HolSmtLib = sig\n"
            "  val Z3_PROVE : term -> thm\n"
            "  val include_theorems : bool ref\nend\n")
        (root / "src/tactictoe/src/tacticToe.sig").write_text(
            "signature tacticToe = sig\n"
            "  val tactictoe : term -> thm\nend\n")
        (root / "src/1/Abbrev.sig").write_text(
            "signature Abbrev = sig\n type thm = Thm.thm\nend\n")
        (root / "src/0/Term.sig").write_text(
            "signature Term = sig\n val kernelid : string\nend\n")
        cfg = json.loads(SPEC.read_text())
        cfg["inputs"]["public_roots"] = ["src"]
        cfg["inputs"]["hol4"]["commit"] = "test"
        local = root / "config.json"
        local.write_text(json.dumps(cfg))
        return local

    def test_signature_extraction_partition_and_render(self):
        with tempfile.TemporaryDirectory() as td:
            root = pathlib.Path(td)
            local = self.fixture(root)
            out = root / "api.json"
            subprocess.run([
                "python3", str(EXTRACT), "--hol4-root", str(root),
                "--config", str(local), "--out", str(out), "--strict"
            ], check=True)

            api = json.loads(out.read_text())
            self.assertEqual(api["summary"]["unsupported_count"], 0)
            self.assertEqual(api["components"]["z3_tac"]["value_count"], 2)
            self.assertEqual(api["components"]["tactictoe"]["value_count"], 1)
            self.assertEqual(api["components"]["hol4"]["value_count"], 1)

            vals = [d for s in api["signatures"] for d in s["declarations"]
                    if d["kind"] == "val"]
            by_id = {d["operation_id"]: d for d in vals}
            self.assertEqual(
                by_id["HolSmtLib.include_theorems"]["lowering"],
                "mutable_ref")
            self.assertIn(
                by_id["HolSmtLib.Z3_PROVE"]["lowering"],
                {"opaque_handle", "higher_order"})

            z3 = json.loads((root / "api.z3_tac.json").read_text())
            ttt = json.loads((root / "api.tactictoe.json").read_text())
            hol = json.loads((root / "api.hol4.json").read_text())
            self.assertEqual({s["component"] for s in z3["signatures"]}, {"z3_tac"})
            self.assertEqual({s["component"] for s in ttt["signatures"]}, {"tactictoe"})
            self.assertEqual({s["component"] for s in hol["signatures"]}, {"hol4"})

            cml = root / "Contract.cml"
            subprocess.run(["python3", str(RENDER), str(out), str(cml)], check=True)
            text = cml.read_text()
            self.assertIn('"z3_tac","HolSmtLib","Z3_PROVE"', text)
            self.assertIn('"tactictoe","tacticToe","tactictoe"', text)

    def test_unterminated_comment_fails_closed(self):
        with tempfile.TemporaryDirectory() as td:
            root = pathlib.Path(td)
            (root / "src/HolSmt").mkdir(parents=True)
            bad = root / "src/HolSmt/HolSmtLib.sig"
            bad.write_text("signature HolSmtLib = sig\n (* never closed\n")
            cfg = json.loads(SPEC.read_text())
            cfg["inputs"]["public_roots"] = ["src/HolSmt"]
            cfg["inputs"]["mandatory_signatures"] = ["src/HolSmt/HolSmtLib.sig"]
            cfg["inputs"]["hol4"]["commit"] = "test"
            local = root / "config.json"
            local.write_text(json.dumps(cfg))
            out = root / "api.json"
            proc = subprocess.run([
                "python3", str(EXTRACT), "--hol4-root", str(root),
                "--config", str(local), "--out", str(out), "--strict"
            ])
            self.assertNotEqual(proc.returncode, 0)


if __name__ == "__main__":
    unittest.main()
