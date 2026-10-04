# GitLab source overlay specialization

- Overlay files must map into the pinned GitLab Rails tree through `overlay.json`; no overlay file may replace `Gemfile`, `config/application.rb`, `config/environment.rb`, or `config/boot.rb`.
- New controllers and services must use GitLab authorization and feature-category conventions. MCP tools must use GitLab's existing MCP registry and authorization path.
- Keep supervision reads deterministic and repository-derived. Never convert file presence, hashes, process exit codes, or Dagger success into a formal-proof completion claim.
- Keep the overlay small enough to audit across GitLab upgrades. New integration points require a pinned source anchor or an explicit compatibility check.

- GitHub bridge code must reuse GitLab's pinned GitHub/Octokit client stack and keep GitHub network failures contained to bridge features.
- Remote GitHub writes must use explicit operation allowlists and optimistic identities where available; never expose a generic arbitrary GitHub HTTP method to agents.
- GitHub workflow/status observations are external process evidence only and cannot satisfy formal proof acceptance.
