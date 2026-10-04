# GitLab runtime specialization

- GitLab CE/FOSS is the only Rails application. Never create a second Rails app, authentication system, session store, or parallel web database.
- Treat `runtime.lock.json` as the host/source authority. Assembly must fail closed if the exact GitLab commit or anchored source blobs drift.
- Human supervision UI and MCP surfaces are read-only by default and derive claims from MetaRocq-rs/Aegis repository evidence. Process success is not formal proof acceptance.
- Reuse GitLab authorization, routing, Rails autoloading, PostgreSQL access, and the built-in MCP server rather than reproducing them in Aegis.
- Keep the `metatheory-verified` implementation gate visible in every generated supervision surface.
- Prefer schema-driven Rails views/presenters over a second frontend state machine. Generated UI must retain links to underlying evidence and blockers.
- Ruby-to-Rust boundaries are allowed only for isolated, measurable kernels with explicit contracts; do not move Rails orchestration into Rust merely for language uniformity.

- GitHub is an optional external forge. Aegis/GitLab must boot and retain local source hosting, CI, MCP, supervision and proof workflows with all GitHub configuration absent or the remote unreachable.
- Never expose GitHub credentials to project files, browser responses, MCP results, agent prompts, or generated evidence. GitHub write mappings are host-admin configuration only.
- Automatic GitHub repository mapping is read-only. GitHub mutations require GitLab `:admin_project` plus an explicit host-admin mapping with `"write": true`.
