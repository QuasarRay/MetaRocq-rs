#!/usr/bin/env python3
"""Build orchestration regressions; the fixture is not a HOL kernel substitute."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class ExactCompileInputs(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        for name in (
            "tools/build_peregrine_hol4_compile.sh", "tools/hol4_artifacts.sh",
            "formal/hol4/PeregrineGeneratedCompileScript.sml",
            "formal/hol4/CompilerOutputAutomationLib.sml",
            "formal/hol4/CompilerOutputAutomationLib.sig",
            "tools/prepare_original_proof_automation.sh",
            "spec/original-proof-automation.lock.json",
            "formal/hol4/Holmakefile", "spec/toolchain.lock.json",
        ):
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(REPO / name, target)
        self.gen = self.root / "generated/peregrine-selfhost"
        self.gen.mkdir(parents=True)
        (self.gen / "hol4").mkdir()
        for name in ("cakeml-context-compat.json", "toolchain.env"):
            (self.gen / "hol4" / name).write_text("orchestration fixture only\n")
        preparation = subprocess.check_output([
            "sha256sum", str(self.gen / "hol4/cakeml-context-compat.json"),
            str(self.gen / "hol4/toolchain.env"),
        ], text=True)
        (self.gen / "hol4/compiler-preparation-inputs.sha256").write_text(preparation)
        self.input = self.gen / "peregrine-selfhost.checked.cakeml"
        self.input.write_bytes(b"first serialized program\n")
        runner = self.root / "fixture-hol/bin/Holmake"
        runner.parent.mkdir(parents=True)
        runner.write_text('''#!/usr/bin/env bash
set -eu
mkdir -p .hol/objs
printf 'build\n' >> ../../build-count.txt
cp ../../generated/peregrine-selfhost/hol4/compiler-input.sexp \\
  .hol/objs/PeregrineGeneratedCompileTheory.dat
if [[ "${FIXTURE_FAIL:-}" == yes ]]; then exit 17; fi
cp ../../generated/peregrine-selfhost/hol4/compiler-input.sexp "$PEREGRINE_MACHINE_ASM"
''')
        runner.chmod(0o755)
        self.env = dict(os.environ, HOL4_DIR=str(runner.parent.parent))

    def build(self, **env):
        return subprocess.run(
            ["bash", "tools/build_peregrine_hol4_compile.sh"],
            cwd=self.root, env=dict(self.env, **env), capture_output=True, text=True,
        )

    def count(self):
        return (self.root / "build-count.txt").read_text().count("build\n")

    def test_identical_inputs_reuse_actual_hashed_outputs(self):
        self.assertEqual(self.build().returncode, 0)
        self.assertEqual(self.build().returncode, 0)
        self.assertEqual(self.count(), 1)

    def test_changed_bytes_with_same_mtime_invalidate_and_preserve(self):
        self.assertEqual(self.build().returncode, 0)
        timestamp = self.input.stat().st_mtime_ns
        self.input.write_bytes(b"different serialized program\n")
        os.utime(self.input, ns=(timestamp, timestamp))
        self.assertEqual(self.build().returncode, 0)
        self.assertEqual(self.count(), 2)
        prior = self.gen / "hol4/previous-compilations"
        snapshots = list(prior.glob("*/compiler-input.sexp"))
        self.assertEqual(len(snapshots), 1)
        self.assertEqual(snapshots[0].read_bytes(), b"first serialized program\n")

    def test_modified_theory_is_not_reused(self):
        self.assertEqual(self.build().returncode, 0)
        theory = self.root / "formal/hol4/.hol/objs/PeregrineGeneratedCompileTheory.dat"
        theory.write_bytes(b"unrelated theory")
        self.assertEqual(self.build().returncode, 0)
        self.assertEqual(self.count(), 2)
        self.assertEqual(theory.read_bytes(), self.input.read_bytes())

    def test_missing_assembler_is_regenerated(self):
        self.assertEqual(self.build().returncode, 0)
        (self.gen / "hol4/peregrine-selfhost.S").unlink()
        self.assertEqual(self.build().returncode, 0)
        self.assertEqual(self.count(), 2)

    def test_modified_automation_library_invalidates_previous_output_receipt(self):
        self.assertEqual(self.build().returncode, 0)
        library = self.root / "formal/hol4/CompilerOutputAutomationLib.sml"
        library.write_text(library.read_text() + '\n(* changed search recipe *)\n')
        self.assertEqual(self.build().returncode, 0)
        self.assertEqual(self.count(), 2)

    def test_failed_compilation_has_no_receipt(self):
        result = self.build(FIXTURE_FAIL="yes")
        self.assertEqual(result.returncode, 17)
        self.assertFalse((self.gen / "hol4/compile-artifacts.sha256").exists())
        self.assertEqual(self.build().returncode, 0)
        self.assertEqual(self.count(), 2)

    def test_ambiguous_flat_and_munged_artifacts_are_rejected(self):
        self.assertEqual(self.build().returncode, 0)
        logical = self.root / "formal/hol4/PeregrineGeneratedCompileTheory.dat"
        logical.write_bytes(b"stale flat artifact")
        result = subprocess.run(
            ["bash", "-c", 'source tools/hol4_artifacts.sh; hol4_artifact_path "$1"',
             "fixture", str(logical)], cwd=self.root, capture_output=True, text=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Ambiguous HOL artifact", result.stderr)


if __name__ == "__main__":
    unittest.main()
