#!/usr/bin/env python3
import json
import pathlib
import shutil
import tempfile
import unittest
import subprocess

ROOT = pathlib.Path(__file__).resolve().parents[1]
EXTRACT = ROOT / "tools/extract_sml_public_api.py"
RENDER = ROOT / "tools/render_api_contract_cml.py"
SPEC = ROOT / "spec/generated-sml-api-wrapper-pipeline.json"


class GeneratedApiWrapperTests(unittest.TestCase):
    def fixture(self, root: pathlib.Path) -> pathlib.Path:
        files = {
            "src/HolSmt/HolSmtLib.sig":
                "signature HolSmtLib = sig\n"
                "  val Z3_PROVE : term -> thm\n"
                "  val include_theorems : bool ref\nend\n",
            "src/tactictoe/src/tacticToe.sig":
                "signature tacticToe = sig\n"
                "  val tactictoe : term -> thm\nend\n",
            "src/1/Abbrev.sig":
                "signature Abbrev = sig\n type thm = Thm.thm\nend\n",
            "src/0/Term.sig":
                "signature Term = sig\n val kernelid : string\nend\n",
            # Audited but intentionally not public.
            "src/internal/Hidden.sig":
                "signature Hidden = sig\n val secret : int\nend\n",
        }
        for rel, content in files.items():
            p = root / rel
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(content)

        sigobj = root / "sigobj"
        sigobj.mkdir()
        # Simulate HOL4's public interface links with copied content; extractor
        # maps these back to source identities by SHA-256.
        for rel in ("src/0/Term.sig", "src/1/Abbrev.sig",
                    "src/HolSmt/HolSmtLib.sig",
                    "src/tactictoe/src/tacticToe.sig"):
            shutil.copyfile(root / rel, sigobj / pathlib.Path(rel).name)

        cfg = json.loads(SPEC.read_text())
        cfg["inputs"]["audit_roots"] = ["src"]
        cfg["inputs"]["public_interface_dir"] = "sigobj"
        cfg["inputs"]["hol4"]["commit"] = "test"
        local = root / "config.json"
        local.write_text(json.dumps(cfg))
        return local

    def test_public_partition_audit_and_render(self):
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
            self.assertEqual(api["source_interface_audit"]["signature_count"], 5)
            self.assertNotIn(
                "Hidden.secret",
                {d["operation_id"] for s in api["signatures"]
                 for d in s["declarations"] if d["kind"] == "val"})
            self.assertEqual(api["components"]["z3_tac"]["value_count"], 2)
            self.assertEqual(api["components"]["tactictoe"]["value_count"], 1)
            self.assertEqual(api["components"]["hol4"]["value_count"], 1)

            vals = [d for s in api["signatures"] for d in s["declarations"]
                    if d["kind"] == "val"]
            by_id = {d["operation_id"]: d for d in vals}
            self.assertEqual(
                by_id["HolSmtLib.include_theorems"]["lowering"],
                "mutable_ref")
            self.assertEqual(
                by_id["HolSmtLib.Z3_PROVE"]["arguments"], ["term"])
            self.assertEqual(
                by_id["HolSmtLib.Z3_PROVE"]["result_type"], "thm")

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

    def test_unterminated_public_signature_fails_closed(self):
        with tempfile.TemporaryDirectory() as td:
            root = pathlib.Path(td)
            (root / "src/HolSmt").mkdir(parents=True)
            bad = root / "src/HolSmt/HolSmtLib.sig"
            bad.write_text("signature HolSmtLib = sig\n (* never closed\n")
            (root / "sigobj").mkdir()
            shutil.copyfile(bad, root / "sigobj/HolSmtLib.sig")
            cfg = json.loads(SPEC.read_text())
            cfg["inputs"]["audit_roots"] = ["src/HolSmt"]
            cfg["inputs"]["public_interface_dir"] = "sigobj"
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

    def test_generator_uses_bounded_api_bridge(self):
        text = (ROOT / "pipeline/cakeml/api-wrapper/ApiWrapperGenerator.cml").read_text()
        self.assertIn("#(api_bridge)", text)
        self.assertIn("Word8Array.length buffer < 16", text)
        self.assertIn("generated_error 1", text)
        self.assertNotIn("#(custom)", text)

    def test_spec_declares_handle_envelope(self):
        spec = json.loads(SPEC.read_text())
        self.assertEqual(spec["abi"]["ffi_name"], "api_bridge")
        self.assertEqual(spec["abi"]["minimum_frame_bytes"], 16)
        self.assertIn("opaque", spec["abi"]["complex_values"].lower())


if __name__ == "__main__":
    unittest.main()
