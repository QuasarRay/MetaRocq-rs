# ADR 0011: GitHub is a deeply integrated optional forge, not Aegis's root of availability

## Status

Accepted for the GitLab/Aegis supervision runtime.

## Goal

Aegis must be able to control and inspect the GitHub website directly for the repositories it supervises while retaining full self-hosting capability. GitHub integration therefore adds a second forge/control surface; it does not become a boot dependency, database of record, proof oracle, or mandatory CI executor.

## Reuse

The pinned GitLab CE/FOSS tree already contains `Gitlab::GithubImport::Client`, Octokit 9.x, URL-validation middleware, rate-limit handling, retry logic and GitHub Enterprise host support. Aegis reuses that stack rather than adding another HTTP client.

The exact GitLab source anchors are recorded in `gitlab/runtime.lock.json`.

## Configuration and confused-deputy boundary

Secrets are never stored in a project repository.

- `AEGIS_GITHUB_TOKEN`: server-side GitHub credential.
- `AEGIS_GITHUB_HOST`: defaults to `https://github.com`.
- `AEGIS_GITHUB_ALLOWED_HOSTS`: explicit additional HTTPS hosts for GitHub Enterprise.
- `AEGIS_GITHUB_REPOSITORY_MAP`: host-admin JSON mapping from GitLab project full path to GitHub repository.
- `AEGIS_GITHUB_AUTO_MAP=true`: optionally maps two-component GitLab paths to the same GitHub path, **read-only**.

A GitHub write is permitted only when all of these are true:

1. GitLab authorizes the caller with `:admin_project`;
2. a server credential exists;
3. the repository comes from the host-admin mapping;
4. that mapping explicitly sets `"write": true`.

Automatic same-name mapping can never enable writes. A repository commit therefore cannot redirect a privileged server credential to a different GitHub repository.

## Direct GitHub surface

The Rails page and MCP tools can inspect:

- repository/project settings;
- branches and default-branch protection;
- repository rulesets;
- GitHub Actions permissions and recent workflow runs;
- open pull requests;
- recent commits and combined status.

Explicit mutation operations cover:

- create branch;
- create pull request;
- merge pull request using an expected 40-hex head SHA;
- re-run failed GitHub Actions jobs;
- workflow dispatch;
- repository settings updates through a strict allowlist;
- branch-protection updates through a strict allowlist;
- repository-ruleset updates through a strict allowlist;
- publishing commit statuses back to the GitHub website.

The server-side token never enters the browser or MCP result.

## Independence invariant

With every `AEGIS_GITHUB_*` variable absent, GitLab must still boot and all local Aegis functions must remain available:

- source hosting and version control;
- Rails supervision UI;
- GitLab MCP;
- GitLab CI and Dagger;
- PostgreSQL persistence;
- formalization roadmaps;
- HOL4/Rocq/Kani replay and all proof gates.

The bridge reports itself disabled/unavailable instead of failing local operations. GitLab remains the canonical self-hosted control plane.

## Consistency model

This checkpoint does not claim transparent two-master consistency between GitLab and GitHub. Remote mutations are explicit and GitHub API responses are observations. GitHub workflow/status data is not formal proof evidence.

A later checkpoint may add signed GitHub webhooks and deterministic mirror reconciliation. Such synchronization must preserve the same independence invariant and must not allow GitHub outages to stall formalization.
