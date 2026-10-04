#!/usr/bin/env python3
"""Optionally delegate a GitHub Actions run to the self-hosted GitLab/Aegis pipeline.

GitHub is a public/control surface only. When GitLab credentials are not configured,
this script is not required for local Aegis operation.
"""
from __future__ import annotations

import json
import os
import sys
import time
from urllib.parse import quote
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

TERMINAL = {"success", "failed", "canceled", "skipped", "manual"}
SUCCESS = {"success"}


def required(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise ValueError(f"missing required environment variable: {name}")
    return value


def request(method: str, url: str, token: str, payload: dict | None = None) -> dict:
    data = None
    headers = {"PRIVATE-TOKEN": token, "Accept": "application/json"}
    if payload is not None:
        data = json.dumps(payload, separators=(",", ":")).encode()
        headers["Content-Type"] = "application/json"
    req = Request(url, data=data, headers=headers, method=method)
    try:
        with urlopen(req, timeout=30) as response:
            body = response.read()
    except HTTPError as error:
        detail = error.read().decode("utf-8", "replace")[:1000]
        raise RuntimeError(f"GitLab API {error.code}: {detail}") from error
    except URLError as error:
        raise RuntimeError(f"GitLab API unavailable: {error.reason}") from error
    return json.loads(body) if body else {}


def main() -> int:
    base = required("AEGIS_GITLAB_URL").rstrip("/")
    project = quote(required("AEGIS_GITLAB_PROJECT"), safe="")
    token = required("AEGIS_GITLAB_API_TOKEN")
    ref = required("AEGIS_GITLAB_REF")
    github_sha = required("AEGIS_GITHUB_SHA")
    timeout_seconds = int(os.environ.get("AEGIS_GITLAB_PIPELINE_TIMEOUT", "3600"))
    poll_seconds = max(5, int(os.environ.get("AEGIS_GITLAB_POLL_SECONDS", "10")))

    variables = [
        {"key": "AEGIS_GITHUB_SHA", "value": github_sha},
        {"key": "AEGIS_GITHUB_REPOSITORY", "value": os.environ.get("GITHUB_REPOSITORY", "")},
        {"key": "AEGIS_GITHUB_RUN_ID", "value": os.environ.get("GITHUB_RUN_ID", "")},
        {"key": "AEGIS_GITHUB_EVENT_NAME", "value": os.environ.get("GITHUB_EVENT_NAME", "")},
    ]
    pipeline = request(
        "POST",
        f"{base}/api/v4/projects/{project}/pipeline",
        token,
        {"ref": ref, "variables": variables},
    )
    pipeline_id = pipeline["id"]
    gitlab_sha = pipeline.get("sha")
    if gitlab_sha != github_sha:
        raise RuntimeError(
            f"GitLab mirror head {gitlab_sha!r} does not match GitHub head {github_sha!r}; "
            "refuse to validate a different commit"
        )

    deadline = time.monotonic() + timeout_seconds
    while True:
        state = request(
            "GET",
            f"{base}/api/v4/projects/{project}/pipelines/{pipeline_id}",
            token,
        )
        status = state.get("status")
        print(
            json.dumps(
                {
                    "pipeline_id": pipeline_id,
                    "status": status,
                    "sha": state.get("sha"),
                    "web_url": state.get("web_url"),
                },
                sort_keys=True,
            ),
            flush=True,
        )
        if state.get("sha") != github_sha:
            raise RuntimeError("GitLab pipeline SHA changed during polling")
        if status in TERMINAL:
            return 0 if status in SUCCESS else 1
        if time.monotonic() >= deadline:
            raise TimeoutError(f"GitLab pipeline {pipeline_id} exceeded timeout")
        time.sleep(poll_seconds)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print(f"aegis-gitlab-bridge: {error}", file=sys.stderr)
        raise SystemExit(2)
