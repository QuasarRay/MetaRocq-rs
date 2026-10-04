# Astra: fix, adopt, integrate, continue

Do not reread the entire GitLab PR stack.

## Start here

```sh
python3 -B scripts/control_plane.py review
python3 -B scripts/control_plane.py diagnose
python3 -B scripts/control_plane.py adopt
```

The packet limits initial review to five semantic files. `diagnose` names failing checks; inspect implementation only for those failures.

## Runtime choice

```text
auto
 ├─ GitLab readiness + dependent services OK
 │    └─ GitLab Rails + MCP + Dagger
 │
 └─ GitLab unavailable / delegation fault
      └─ existing Python + PostgreSQL + Git/GitHub controller
```

Both modes use the same roadmap, source, evidence and formal gates. Switching modes does not migrate or reinterpret proof state.

## Never fall back around

- PostgreSQL/event durability failure
- publication/commit identity mismatch
- formal verifier/replay failure
- missing theorem
- model/provider authorization requirement
- `metatheory-verified` gate

Those remain blocked.

## Continue work

```sh
python3 -B scripts/control_plane.py continue --root /path/to/MetaRocq-rs
```

If GitLab is healthy, use its existing Aegis MCP/supervision interface. If it is not, the command emits the exact legacy bootstrap/status/recovery commands.

The architecture change is an orchestration upgrade, not a reason to regenerate the formalization roadmap or redo preserved proof/extraction work.
