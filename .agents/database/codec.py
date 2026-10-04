"""Pure deterministic encoding and hashing helpers shared by persistence and roadmap code."""
from __future__ import annotations

import hashlib
import json


def canonical(value):
    return json.dumps(
        value,
        sort_keys=True,
        separators=(",", ":"),
        ensure_ascii=False,
        allow_nan=False,
    )


def sha(data):
    return hashlib.sha256(data).hexdigest()
