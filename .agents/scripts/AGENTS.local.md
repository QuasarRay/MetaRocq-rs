# Architecture adoption and fallback specialization

- `scripts/control_plane.py` is the bounded entrypoint for Astra to review, diagnose, adopt and continue the GitLab architecture.
- Keep `AEGIS_CONTROL_PLANE_MODE=auto` as GitLab-primary with legacy fallback. Explicit `gitlab` must fail closed; explicit `legacy` must not contact GitLab.
- Fallback may replace unavailable orchestration/UI/CI mechanics only. It must never bypass PostgreSQL persistence, publication identity, formal replay/verifier failures, provider authorization, or `metatheory-verified`.
- Both modes must consume the same roadmap/evidence. Never create a fallback-only roadmap, proof database or completion marker.
- Diagnostics must return compact machine-readable results and point Astra at failing files/checks rather than requiring whole-repository rereads.
