"""Live read-only GitHub attestation, separate from committing/pushing user work."""
from __future__ import annotations

import json
import os
import urllib.request

from .contracts import git, require


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def github_pr(repository, number):
    require(type(number) is int and number > 0, "PR number must be positive")
    url = f"https://api.github.com/repos/{repository}/pulls/{number}"
    headers = {"Accept": "application/vnd.github+json", "User-Agent": "Aegis-MetaRocq/6"}
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = "Bearer " + token
    # Token is used only for this fixed GitHub API origin; never stored in evidence.
    opener = urllib.request.build_opener(NoRedirect)
    with opener.open(urllib.request.Request(url, headers=headers), timeout=30) as response:
        require(response.url == url, "unexpected GitHub API redirect")
        return json.load(response)


def validate_pr(data, repository, base, head):
    require(data.get("state") == "open", "checkpoint needs an open pull request")
    require(data.get("base", {}).get("repo", {}).get("full_name") == repository, "PR targets another repository")
    require(data.get("head", {}).get("repo", {}).get("full_name") == repository, "PR head must be in the configured repository")
    require(data["base"]["ref"] == base, "PR is not stacked on the required base")
    require(data["head"]["sha"] == head, "remote PR head differs from local commit")
    require(data["head"]["ref"] != base, "PR cannot target its own branch")
    return {"repository": repository, "pr": data["number"], "url": data["html_url"],
            "base": base, "branch": data["head"]["ref"], "head": head}


def attest(root, remote, number):
    head = git(root, "rev-parse", "HEAD").decode().strip()
    data = github_pr(remote["repository"], number)
    require(data.get("number") == number, "GitHub response is for another PR")
    receipt = validate_pr(data, remote["repository"], remote["base"], head)
    observed = git(root, "ls-remote", f"https://github.com/{remote['repository']}.git", "refs/heads/" + receipt["branch"]).decode().split()
    require(observed and observed[0] == head, "remote branch does not preserve the exact commit")
    require(git(root, "rev-parse", "HEAD").decode().strip() == head, "HEAD changed during remote checkpoint")
    require(not git(root, "status", "--porcelain", "--untracked-files=all"), "worktree changed during remote checkpoint")
    return receipt
