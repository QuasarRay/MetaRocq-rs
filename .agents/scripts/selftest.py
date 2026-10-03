from pathlib import Path
import subprocess
import sys
root = Path(__file__).resolve().parents[1]
for argv in ([sys.executable, "-B", "scripts/generate.py", "--check"],
             [sys.executable, "-B", "-m", "unittest", "discover", "-s", "infra/tests", "-q"]):
    result = subprocess.run(argv, cwd=root)
    if result.returncode:
        raise SystemExit(result.returncode)
