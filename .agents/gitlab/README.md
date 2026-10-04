# Aegis on GitLab CE/FOSS Rails

This directory defines a source overlay for a **single** Rails application: the pinned GitLab CE/FOSS tree. Aegis does not boot a second Rails app.

`runtime.lock.json` pins GitLab v19.4.1 to its exact commit and source anchors. `materialize.py` can fetch that source, and `assemble.py` verifies the clean host, installs the overlay, wires `config/routes.rb` and GitLab's built-in MCP manager, and writes an assembly manifest.

```sh
python3 gitlab/materialize.py /work/gitlab-aegis --source canonical
# or, when gitlab.com is unavailable:
python3 gitlab/materialize.py /work/gitlab-aegis --source github-mirror
```

The resulting GitLab process owns authentication, sessions, authorization, routing, PostgreSQL, UI rendering, and MCP transport. Aegis contributes:

- `/-/aegis/projects/:project_id`: read-only Rails/HAML supervision view generated from MetaRocq-rs roadmap/evidence data.
- `aegis_get_supervision_state`: read-only tool registered in GitLab's existing MCP server.
- `.gitlab/ci/aegis.gitlab-ci.yml`: Dagger-backed integration checks.

The UI intentionally distinguishes repository/process evidence from proof completion. `proof_complete` is never inferred from file presence or successful jobs; the existing independent replay gates remain authoritative.

## Optional GitHub website/control bridge

The assembled Rails application can expose GitHub state at `/-/aegis/projects/:project_id/github` and through `aegis_github_get_state` / `aegis_github_mutate` MCP tools.

The bridge is disabled unless a server credential and mapping are configured. Self-hosted GitLab/Aegis does not depend on GitHub.

```sh
export AEGIS_GITHUB_TOKEN='...'
export AEGIS_GITHUB_REPOSITORY_MAP='{"QuasarRay/MetaRocq-rs":{"repository":"QuasarRay/MetaRocq-rs","write":true}}'
# Optional read-only same-path mapping:
export AEGIS_GITHUB_AUTO_MAP=true
```

Supported direct GitHub operations include repository settings, branch protection/rulesets, branches, pull requests and merges, Actions workflow inspection/dispatch/retry, recent version-control state, and publishing commit statuses back to GitHub. The browser and MCP never receive the server credential.
