#!/usr/bin/env python3
"""Extract public Standard ML signature declarations into a canonical API IR.

This tool is intentionally outside the trust base.  Its output is source-hashed,
coverage-counted, regenerated deterministically and then checked by HOL4-facing
proof/qualification stages.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import re
from typing import Iterable

DECL = re.compile(r"^(val|type|eqtype|datatype|exception|include|structure|sharing)\b")
SIG = re.compile(r"\bsignature\s+([A-Za-z_][A-Za-z0-9_']*)\s*=\s*sig\b", re.S)
VAL = re.compile(r"^val\s+([^\s:]+)\s*:\s*(.*)$", re.S)
TYPE = re.compile(r"^(?:eqtype|type)\s+(.*)$", re.S)

DEFAULT_OPAQUE = {
    "Thm.thm", "Term.term", "Type.hol_type", "Context.t",
    "tttSearch.searchtree", "mlTreeNeuralNetwork.tnn",
}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def strip_nested_comments(text: str) -> str:
    out: list[str] = []
    i = 0
    depth = 0
    while i < len(text):
        if text.startswith("(*", i):
            depth += 1
            i += 2
        elif depth and text.startswith("*)", i):
            depth -= 1
            i += 2
        elif depth:
            if text[i] == "\n":
                out.append("\n")
            i += 1
        else:
            out.append(text[i])
            i += 1
    if depth:
        raise ValueError("unterminated SML comment")
    return "".join(out)


def signature_body(text: str) -> tuple[str, str]:
    m = SIG.search(text)
    if not m:
        raise ValueError("no top-level signature declaration")
    tail = text[m.end():]
    end = tail.rfind("\nend")
    if end < 0:
        end = tail.rfind("end")
    if end < 0:
        raise ValueError("signature has no terminating end")
    return m.group(1), tail[:end]


def logical_declarations(body: str) -> Iterable[str]:
    current: list[str] = []
    current_indent = 10**9
    for raw in body.splitlines():
        if not raw.strip():
            continue
        stripped = raw.lstrip()
        indent = len(raw) - len(stripped)
        starts = DECL.match(stripped)
        if starts and current and indent <= current_indent:
            yield "\n".join(current).strip()
            current = []
            current_indent = indent
        elif starts and not current:
            current_indent = indent
        current.append(raw)
    if current:
        yield "\n".join(current).strip()


def split_top_level_arrows(type_text: str) -> list[str]:
    pieces: list[str] = []
    depth = 0
    start = 0
    i = 0
    while i < len(type_text) - 1:
        c = type_text[i]
        if c in "([{":
            depth += 1
        elif c in ")]}":
            depth = max(0, depth - 1)
        elif c == "-" and type_text[i + 1] == ">" and depth == 0:
            pieces.append(type_text[start:i].strip())
            start = i + 2
            i += 1
        i += 1
    pieces.append(type_text[start:].strip())
    return pieces


def classify_value(type_text: str, opaque: set[str]) -> tuple[str, int]:
    t = " ".join(type_text.split())
    parts = split_top_level_arrows(t)
    arity = max(0, len(parts) - 1)
    if re.search(r"\bref\b", t):
        return "mutable_ref", arity
    if any("->" in p for p in parts):
        return "higher_order", arity
    if any(name in t for name in opaque):
        return "opaque_handle", arity
    direct_tokens = {"unit", "bool", "int", "string", "char", "word", "real"}
    names = set(re.findall(r"[A-Za-z_][A-Za-z0-9_'.]*", t))
    structural_words = {"list", "option", "vector", "array"}
    unknown = {
        n for n in names
        if n not in direct_tokens
        and n not in structural_words
        and not n.startswith("'")
        and n not in {"NONE", "SOME"}
    }
    if unknown:
        # Unknown named SML values are represented opaquely by default.  This
        # is safe and complete; override metadata may later select a richer
        # structural codec.
        return "opaque_handle", arity
    if names & structural_words or any(c in t for c in "*{}"):
        return "structural", arity
    return "direct", arity


def parse_signature(path: pathlib.Path, root: pathlib.Path, opaque: set[str]) -> dict:
    data = path.read_bytes()
    text = strip_nested_comments(data.decode("utf-8"))
    sig_name, body = signature_body(text)
    declarations = []
    for index, raw in enumerate(logical_declarations(body)):
        first = raw.lstrip()
        kind_match = DECL.match(first)
        if not kind_match:
            declarations.append({
                "index": index, "kind": "unsupported", "raw": raw,
                "reason": "unrecognised top-level signature declaration",
            })
            continue
        kind = kind_match.group(1)
        item = {"index": index, "kind": kind, "raw": raw}
        if kind == "val":
            m = VAL.match(first)
            if not m:
                item.update(kind="unsupported", reason="malformed val declaration")
            else:
                name, ty = m.group(1), m.group(2).strip()
                lowering, arity = classify_value(ty, opaque)
                item.update(
                    name=name,
                    type=" ".join(ty.split()),
                    lowering=lowering,
                    arity=arity,
                    operation_id=f"{sig_name}.{name}",
                )
        elif kind in {"type", "eqtype"}:
            m = TYPE.match(first)
            item.update(name=(m.group(1).split("=", 1)[0].strip() if m else first))
        elif kind in {"datatype", "exception", "include", "structure", "sharing"}:
            item.update(name=first.split(None, 1)[1] if " " in first else first)
        declarations.append(item)
    return {
        "signature": sig_name,
        "path": str(path.relative_to(root)),
        "sha256": sha256(data),
        "declarations": declarations,
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--hol4-root", required=True, type=pathlib.Path)
    ap.add_argument("--config", required=True, type=pathlib.Path)
    ap.add_argument("--out", required=True, type=pathlib.Path)
    ap.add_argument("--strict", action="store_true")
    args = ap.parse_args()

    config = json.loads(args.config.read_text())
    root = args.hol4_root.resolve()
    opaque = set(DEFAULT_OPAQUE)
    opaque.update(config.get("opaque_types", []))

    paths: set[pathlib.Path] = set()
    for rel in config["inputs"]["public_roots"]:
        base = root / rel
        if base.is_file() and base.suffix == ".sig":
            paths.add(base)
        elif base.exists():
            paths.update(base.rglob("*.sig"))
    for rel in config["inputs"]["mandatory_signatures"]:
        p = root / rel
        if not p.exists():
            raise SystemExit(f"missing mandatory signature: {rel}")
        paths.add(p)

    signatures = []
    failures = []
    for p in sorted(paths):
        try:
            signatures.append(parse_signature(p, root, opaque))
        except Exception as exc:
            failures.append({"path": str(p.relative_to(root)), "error": str(exc)})

    declarations = [d for s in signatures for d in s["declarations"]]
    values = [d for d in declarations if d["kind"] == "val"]
    unsupported = [d for d in declarations if d["kind"] == "unsupported"]
    canonical = {
        "schema": 1,
        "source_root": str(root),
        "source_commit": config["inputs"]["hol4"]["commit"],
        "signatures": signatures,
        "failures": failures,
        "summary": {
            "signature_count": len(signatures),
            "declaration_count": len(declarations),
            "value_count": len(values),
            "unsupported_count": len(unsupported) + len(failures),
        },
    }
    args.out.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(canonical, indent=2, sort_keys=True) + "\n"
    args.out.write_text(payload)
    (args.out.with_suffix(args.out.suffix + ".sha256")).write_text(
        f"{sha256(payload.encode())}  {args.out.name}\n"
    )

    if args.strict and canonical["summary"]["unsupported_count"]:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
