"""Identity, confinement, source and HOL4/OpenTheory primitives for the bridge."""
from __future__ import annotations
import hashlib, json, os, re, shutil, subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOCK_PATH = ROOT / "spec/hol4-opentheory-pcuic.lock.json"
REF_ROOT = ROOT / ".aegis/references/hol4-pcuic"
BUILD_ROOT = ROOT / ".aegis/build/hol4-pcuic"
EVIDENCE_ROOT = ROOT / ".metarocq/evidence/hol4-opentheory-pcuic"
IDENT = re.compile(r"^[A-Za-z][A-Za-z0-9_']*$")
QUALID = re.compile(r"^[A-Za-z][A-Za-z0-9_']*(?:\.[A-Za-z][A-Za-z0-9_']*)*$")


def load_lock(): return json.loads(LOCK_PATH.read_text())
def digest(data: bytes): return hashlib.sha256(data).hexdigest()


def confined(root: Path, path: Path, *, must_exist=False):
    root = root.resolve(strict=True); candidate = path if path.is_absolute() else root / path
    cursor = candidate
    while True:
        if cursor.exists() and cursor.is_symlink(): raise ValueError(f"symlink not allowed in bridge path: {cursor}")
        if cursor == root or cursor.parent == cursor: break
        cursor = cursor.parent
    resolved = candidate.resolve(strict=must_exist)
    if resolved != root and root not in resolved.parents: raise ValueError(f"path escapes bridge root: {path}")
    return resolved


def checked_name(value, *, qualified=False):
    if not (QUALID if qualified else IDENT).fullmatch(value):
        raise ValueError(f"invalid {'qualified ' if qualified else ''}identifier: {value!r}")
    return value


def run(argv, *, cwd, env=None, input_text=None, timeout=1800):
    if not argv or any(not isinstance(x, str) or "\x00" in x for x in argv): raise ValueError("invalid argv")
    p = subprocess.run(argv, cwd=cwd, env=env, input=input_text, text=True, stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE, timeout=timeout, check=False)
    result = {"argv": argv, "cwd": str(cwd), "returncode": p.returncode,
              "stdout_sha256": digest(p.stdout.encode()), "stderr_sha256": digest(p.stderr.encode()),
              "stdout_bytes": len(p.stdout.encode()), "stderr_bytes": len(p.stderr.encode())}
    if p.returncode: raise RuntimeError(json.dumps({**result, "stderr": p.stderr[-4000:]}, ensure_ascii=False))
    return result


def git(root, *args): return subprocess.check_output(["git", "-C", str(root), *args], text=True).strip()
def source_path(name): return REF_ROOT / name


def verify_source(name, pin):
    path = confined(ROOT, source_path(name), must_exist=True)
    if not path.is_dir() or Path(git(path, "rev-parse", "--show-toplevel")).resolve() != path:
        raise ValueError(f"not a repository root: {name}")
    if git(path, "rev-parse", "HEAD") != pin["commit"]: raise ValueError(f"wrong revision for {name}")
    if git(path, "status", "--porcelain", "--untracked-files=all"): raise ValueError(f"dirty pinned source: {name}")
    remote, expected = git(path, "remote", "get-url", "origin"), pin["repository"]
    aliases = {expected, expected.removesuffix(".git"), expected if expected.endswith(".git") else expected + ".git"}
    if remote not in aliases: raise ValueError(f"unexpected origin for {name}: {remote}")
    return path


def sources(lock):
    confined(ROOT, REF_ROOT).mkdir(parents=True, exist_ok=True)
    for name, pin in lock["repositories"].items():
        path = source_path(name)
        if not path.exists():
            subprocess.run(["git", "init", "-q", str(path)], check=True)
            subprocess.run(["git", "-C", str(path), "remote", "add", "origin", pin["repository"]], check=True)
            subprocess.run(["git", "-C", str(path), "fetch", "--depth", "1", "origin", pin["commit"]], check=True)
            subprocess.run(["git", "-C", str(path), "checkout", "--detach", "FETCH_HEAD"], check=True)
        verify_source(name, pin)
    return {"status":"SOURCES_MATCH", "commits":{k:v["commit"] for k,v in lock["repositories"].items()}}


def verify_bound_files(lock):
    seen = {}
    for spec, expected in lock["bound_files"].items():
        repo, rel = spec.split(":", 1); root = verify_source(repo, lock["repositories"][repo])
        observed = git(root, "rev-parse", f"HEAD:{rel}")
        if observed != expected: raise ValueError(f"bound upstream file changed: {spec}: {observed} != {expected}")
        seen[spec] = observed
    return seen


def preflight(lock):
    return {"status":"PREFLIGHT_OK", "bound_files":verify_bound_files(lock),
            "available":{x:bool(shutil.which(x)) for x in ("git","make","opam","rocq","lambdapi")},
            "claim":"identity and architecture preflight only; no theorem translated"}


def build_holide(lock):
    src = verify_source("holide", lock["repositories"]["holide"]); dst = confined(ROOT, BUILD_ROOT / "holide")
    if dst.exists(): shutil.rmtree(dst)
    dst.parent.mkdir(parents=True, exist_ok=True); shutil.copytree(src, dst, symlinks=False, ignore=shutil.ignore_patterns(".git"))
    run(["make"], cwd=dst); binary = dst / "holide"
    if not binary.is_file(): raise ValueError("Holide build did not produce holide")
    return binary


def resolve_tool(name, env_name, default=None):
    explicit, discovered = os.environ.get(env_name), shutil.which(name)
    if explicit: candidate = Path(explicit)
    elif default is not None and default.is_file(): candidate = default
    elif discovered: candidate = Path(discovered)
    else: raise ValueError(f"missing tool {name}; set {env_name}")
    candidate = candidate.resolve(strict=True)
    if not candidate.is_file() or not os.access(candidate, os.X_OK): raise ValueError(f"tool is not executable: {candidate}")
    return candidate


def verify_hol4_home(lock):
    if not os.environ.get("HOLDIR"): raise ValueError("HOLDIR must point at the built pinned HOL4 checkout")
    path = Path(os.environ["HOLDIR"]).resolve(strict=True); pin = lock["repositories"]["hol4"]
    if git(path, "rev-parse", "HEAD") != pin["commit"]: raise ValueError("HOLDIR revision mismatch")
    subprocess.run(["git","-C",str(path),"diff","--exit-code","HEAD","--"], check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for rel in ("bin/hol","bin/Holmake"):
        if not (path/rel).is_file(): raise ValueError(f"HOLDIR not built: missing {rel}")
    return path


def export_article(lock, *, theory_dir, theory, theorem, article, timeout):
    theory, theorem = checked_name(theory), checked_name(theorem); holdir = verify_hol4_home(lock)
    theory_dir, article = confined(ROOT, theory_dir, must_exist=True), confined(ROOT, article)
    article.parent.mkdir(parents=True, exist_ok=True)
    run([str(holdir/"bin/Holmake"),"--qof","--no-cache"], cwd=theory_dir, timeout=timeout)
    driver = (f'open HolKernel boolLib bossLib;\nval _ = load "OpenTheoryIO";\n'
              f'val th = DB.fetch "{theory}" "{theorem}";\nval out = TextIO.openOut "{article}";\n'
              'val _ = OpenTheoryIO.thm_to_article out (fn () => th);\nval _ = TextIO.closeOut out;\n'
              'val _ = OS.Process.exit OS.Process.success;\n')
    process = run([str(holdir/"bin/hol")], cwd=theory_dir, input_text=driver, timeout=timeout)
    if not article.is_file() or not article.stat().st_size: raise ValueError("HOL4 produced no OpenTheory article")
    return {"status":"ARTICLE_EXPORTED","article":str(article),"sha256":digest(article.read_bytes()),"process":process}


def write_evidence(kind, payload):
    EVIDENCE_ROOT.mkdir(parents=True, exist_ok=True); path = EVIDENCE_ROOT / f"{kind}.json"
    path.write_text(json.dumps(payload, indent=2, sort_keys=True)+"\n"); return path
