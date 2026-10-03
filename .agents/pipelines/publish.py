"""Automated non-forcing Git publication barrier; no model-generated commit text."""
from pathlib import Path
import subprocess


def git(root, *args):
    return subprocess.check_output(['git', '-C', str(root), *args], text=True).strip()


def publish(framework, target, output_paths):
    framework, target = Path(framework).resolve(), Path(target).resolve()
    repo = Path(git(framework, 'rev-parse', '--show-toplevel')).resolve()
    # In production the deployment and target share the exact Git publication.
    if repo != target:
        raise ValueError('bootstrap publication requires deployment under target/.agents')
    prefix = framework.relative_to(repo).as_posix()
    data_path = (Path(prefix) / 'data').as_posix()
    paths = [data_path, *output_paths]
    for generator in (framework / 'scripts/generate.py', target / 'tools/sync_instructions.py'):
        subprocess.run(['python3', '-B', str(generator)], cwd=repo, check=True, stdout=subprocess.DEVNULL)
    # Stage data and generated directory instructions, never unrelated agent edits.
    instruction_paths = sorted({p for p in git(repo, 'ls-files', '--cached', '--others', '--exclude-standard').splitlines()
                                if p == 'AGENTS.md' or p.endswith('/AGENTS.md')})
    git(repo, 'add', '--', *paths, *instruction_paths)
    if git(repo, 'diff', '--name-only') or git(repo, 'ls-files', '--others', '--exclude-standard'):
        raise ValueError('uncommitted implementation changes must be checkpointed before automatic publication')
    staged = git(repo, 'diff', '--cached', '--name-only').splitlines()
    permitted = lambda p: p.startswith(data_path + '/') or p in output_paths or p.endswith('/AGENTS.md') or p == 'AGENTS.md'
    if any(not permitted(p) for p in staged):
        raise ValueError('unrelated staged changes would enter automatic persistence commit')
    if staged:
        git(repo, 'commit', '-m', 'Persist automatic metatheory execution records')
    branch = git(repo, 'symbolic-ref', '--short', 'HEAD')
    head = git(repo, 'rev-parse', 'HEAD')
    observed = git(repo, 'ls-remote', 'origin', f'refs/heads/{branch}').split()
    if not observed or observed[0] != head:
        git(repo, 'push', 'origin', f'HEAD:refs/heads/{branch}')
    remote = git(repo, 'ls-remote', '--exit-code', 'origin', f'refs/heads/{branch}').split()[0]
    if remote != head:
        raise ValueError('remote publication does not match the exact local commit')
    # No receipt event is appended here: that would itself require another push.
    return {'commit': head, 'branch': branch, 'status': 'PUBLISHED'}
