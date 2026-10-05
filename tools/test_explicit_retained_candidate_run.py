#!/usr/bin/env python3
"""Exercise real trace/exit propagation; fixture programs are not proof engines."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class ExplicitRetainedCandidateRun(unittest.TestCase):
    def run_case(self, controller_status, retained_status, tactician_status=0):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "tools").mkdir()
            for name in ("run_unified_e2e_with_traces.sh", "o11y_observe.sh"):
                shutil.copy2(REPO / "tools" / name, root / "tools" / name)
            controller = root / "fixture-controller"
            controller.write_text(
                '#!/usr/bin/env bash\n'
                'printf "controller\\n" >> "$FIXTURE_ROOT/calls.txt"\n'
                'exit "$FIXTURE_CONTROLLER_STATUS"\n')
            controller.chmod(0o755)
            (root / "tools/build_original_three_project_lambdabox.sh").write_text(
                '#!/usr/bin/env bash\n'
                'printf "retained\\n" >> "$FIXTURE_ROOT/calls.txt"\n'
                'exit "$FIXTURE_RETAINED_STATUS"\n')
            (root / "tools/run_original_tactician_probe.sh").write_text(
                '#!/usr/bin/env bash\n'
                'printf "tactician\\n" >> "$FIXTURE_ROOT/calls.txt"\n'
                'exit "$FIXTURE_TACTICIAN_STATUS"\n')
            trace = root / "trace"
            env = dict(os.environ, FIXTURE_ROOT=str(root),
                       FIXTURE_CONTROLLER_STATUS=str(controller_status),
                       FIXTURE_RETAINED_STATUS=str(retained_status),
                       FIXTURE_TACTICIAN_STATUS=str(tactician_status),
                       UNIFIED_E2E_CONTROLLER=str(controller),
                       E2E_TRACE_DIR=str(trace))
            env.pop("CAKEML_REGRESSION_DIR", None)
            result = subprocess.run(
                ["bash", "tools/run_unified_e2e_with_traces.sh"], cwd=root,
                env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, controller_status or tactician_status or retained_status,
                             result.stdout + result.stderr)
            self.assertEqual((root / "calls.txt").read_text().splitlines(),
                             ["controller", "tactician", "retained"])
            self.assertEqual((trace / "explicit-producer-statuses.txt").read_text(),
                             f"controller={controller_status}\n"
                             f"tactician_qualification={tactician_status}\n"
                             f"retained_candidate={retained_status}\n")
            for name, status in (("cake-controller", controller_status),
                                 ("original-tactician-qualification", tactician_status),
                                 ("three-project-retained-candidate", retained_status)):
                observed = trace / "preflight" / name
                self.assertIn(f"exit={status}\n", (observed / "status.txt").read_text())
                self.assertTrue((observed / "time-memory.txt").is_file())
                self.assertEqual((observed / "complete").read_text().startswith("SUCCESS"),
                                 status == 0)

    def test_controller_failure_still_collects_distinct_candidate(self):
        self.run_case(17, 0)

    def test_candidate_failure_does_not_report_success(self):
        self.run_case(0, 19)

    def test_two_failures_retain_original_controller_failure(self):
        self.run_case(17, 19)

    def test_two_successful_processes_record_both_statuses(self):
        self.run_case(0, 0)

    def test_tactician_failure_still_runs_distinct_image_and_fails_the_run(self):
        self.run_case(0, 0, 23)

    def test_three_failures_preserve_all_statuses_and_the_controller_exit(self):
        self.run_case(17, 19, 23)


if __name__ == "__main__":
    unittest.main()
