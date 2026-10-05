#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
: "${HOLDIR:?Set HOLDIR to the built .agents-pinned HOL4}"
GEN="$ROOT/generated/peregrine-selfhost/hol4"
mkdir -p "$GEN"
VENV="${ORIGINAL_PROOF_AUTOMATION_VENV:-$ROOT/.aegis/tools/original-proof-automation}"
if [[ ! -x "$VENV/bin/python" ]]; then
  interpreter="${ORIGINAL_PROOF_AUTOMATION_PYTHON:-python3}"
  "$interpreter" -c 'import sys; assert sys.version_info >= (3,11), "hol4-mcp requires Python 3.11 or newer"'
  "$interpreter" -m venv "$VENV"
fi
"$VENV/bin/python" - "$ROOT" <<'PY'
import importlib.metadata as metadata
import json, pathlib, subprocess, sys
root=pathlib.Path(sys.argv[1])
sys.path.insert(0,str(root/'.agents/infra'))
from agentinfra.hol4 import hol4_home, pins
hol4_home()  # The existing .agents identity/pin/clean-source gate.
pin=pins(); source=root/'.aegis/references/hol4-mcp'
if not source.exists():
 subprocess.run(['git','clone',pin['hol4_mcp_repo'],str(source)],check=True)
 subprocess.run(['git','-C',str(source),'checkout','--detach',pin['hol4_mcp_commit']],check=True)
if subprocess.check_output(['git','-C',str(source),'rev-parse','HEAD'],text=True).strip()!=pin['hol4_mcp_commit'] or subprocess.check_output(['git','-C',str(source),'diff','HEAD','--']):
 raise SystemExit('hol4-mcp source differs from the clean .agents pin')
lock=json.loads((root/'spec/original-proof-automation.lock.json').read_text())
requirements=[lock[k] for k in ('z3_solver_python_distribution','mcp_python_distribution','fastmcp_python_distribution')]
def matches():
 try:
  if any(metadata.version(r.split('==')[0])!=r.split('==')[1] for r in requirements): return False
  if metadata.version('hol4-mcp')!=pin['hol4_mcp_version']: return False
  import hol4_mcp
  installed=pathlib.Path(hol4_mcp.__file__).parent
  return all((installed/f.relative_to(source/'hol4_mcp')).read_bytes()==f.read_bytes()
             for f in (source/'hol4_mcp').rglob('*') if f.is_file() and f.suffix in ('.py','.ts'))
 except (metadata.PackageNotFoundError,ImportError,FileNotFoundError): return False
if not matches():
 try: import pip
 except ImportError:
  subprocess.run([sys.executable,'-m','ensurepip','--upgrade'],check=True)
 subprocess.run([sys.executable,'-m','pip','install',*requirements,str(source)],check=True)
if not matches(): raise SystemExit('Installed proof-search tools do not match their exact source inputs')
PY
export PATH="$VENV/bin:$PATH"
export HOL4_Z3_EXECUTABLE="$VENV/bin/z3"
"$VENV/bin/python" - "$ROOT" "$GEN" <<'PY'
import importlib.metadata as metadata
import json, pathlib, shlex, sys
root,gen=map(pathlib.Path,sys.argv[1:])
sys.path.insert(0,str(root/'.agents/infra'))
from agentinfra.hol4 import environment, identity
env=environment(root)  # Persistent cache and upstream shell-safe Z3 path checks.
(gen/'proof-automation.env').write_text(''.join('export '+k+'='+shlex.quote(v)+'\n' for k,v in env.items() if k!='HOME')+'export PATH='+shlex.quote(str(pathlib.Path(sys.executable).parent))+':"$PATH"\n')
(gen/'proof-automation-identity.json').write_text(json.dumps(identity(require_mcp=True),indent=2)+'\n')
(gen/'proof-automation-freeze.txt').write_text(''.join(
 name+'=='+version+'\n' for name,version in sorted(
 (d.metadata['Name'],d.version) for d in metadata.distributions())))
PY
sha256sum "$GEN/proof-automation.env" "$GEN/proof-automation-identity.json" \
  "$GEN/proof-automation-freeze.txt" spec/original-proof-automation.lock.json \
  tools/prepare_original_proof_automation.sh > "$GEN/proof-automation-inputs.sha256"
sha256sum --check "$GEN/proof-automation-inputs.sha256"
"$VENV/bin/python" .agents/scripts/check_hol4.py \
  > "$GEN/agents-hol4-automation-qualification.log" 2>&1
