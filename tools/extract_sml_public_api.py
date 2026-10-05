#!/usr/bin/env python3
"""Extract HOL4-family public Standard ML interfaces into canonical API IR.

Trust policy:
- this extractor is NOT trusted proof evidence;
- production public API comes from HOL4's build-generated sigobj surface,
  unioned with explicitly mandatory proof-automation signatures;
- every src/**/*.sig file is still hashed into a source-interface audit;
- deterministic regeneration, source hashes and HOL4 kernel checks gate use.
"""

from __future__ import annotations

import argparse
import collections
import hashlib
import json
import pathlib
import re
from typing import Iterable

DECL = re.compile(r"^(val|type|eqtype|datatype|exception|include|structure|sharing)\b")
SIG = re.compile(r"\bsignature\s+([A-Za-z_][A-Za-z0-9_']*)\s*=\s*sig\b", re.S)
VAL = re.compile(r"^val\s+(?:op\s+)?([^\s:]+)\s*:\s*(.*)$", re.S)
TYPE = re.compile(r"^(?:eqtype|type)\s+(.*)$", re.S)

DEFAULT_OPAQUE = {
    "Thm.thm", "Term.term", "Type.hol_type", "Context.t",
    "tttSearch.searchtree", "mlTreeNeuralNetwork.tnn",
}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def cake_name(op_id: str) -> str:
    s = re.sub(r"[^A-Za-z0-9_']", "_", op_id).lower()
    if not s or not s[0].isalpha():
        s = "api_" + s
    return "generated_" + s


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


def classify_type(type_text: str, opaque: set[str]) -> str:
    t = " ".join(type_text.split())
    if len(split_top_level_arrows(t)) > 1:
        return "callback_handle"
    if re.search(r"\bref\b", t):
        return "remote_ref"
    if any(name in t for name in opaque):
        return "opaque_handle"
    direct = {"unit", "bool", "int", "string", "char", "real"}
    # word/word8/etc are kept direct when they are the complete named type.
    if t in direct or re.fullmatch(r"(?:Word\d*\.word|word\d*|word)", t, re.I):
        return "direct"
    if any(tok in t for tok in (" list", " option", " vector", " array", "*", "{", "}")):
        return "structural"
    # Type variables and named SML/HOL4 types are safe as typed opaque values.
    return "opaque_handle"


def classify_value(type_text: str, opaque: set[str]) -> tuple[str, int, list[str], str]:
    t = " ".join(type_text.split())
    parts = split_top_level_arrows(t)
    arity = max(0, len(parts) - 1)
    args = parts[:-1]
    result = parts[-1]
    arg_classes = [classify_type(x, opaque) for x in args]
    result_class = classify_type(result, opaque)
    if arity == 0 and result_class == "remote_ref":
        lowering = "mutable_ref"
    elif "callback_handle" in arg_classes or result_class == "callback_handle":
        lowering = "higher_order"
    elif "opaque_handle" in arg_classes or result_class == "opaque_handle":
        lowering = "opaque_handle"
    elif "structural" in arg_classes or result_class == "structural":
        lowering = "structural"
    else:
        lowering = "direct"
    return lowering, arity, arg_classes, result_class


def component_for(rel: str) -> str:
    rel = rel.replace("\\", "/")
    if rel.startswith("src/HolSmt/"):
        return "z3_tac"
    if rel.startswith("src/tactictoe/"):
        return "tactictoe"
    return "hol4"


def parse_signature(path: pathlib.Path, source_rel: str, opaque: set[str]) -> dict:
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
                normalized = " ".join(ty.split())
                lowering, arity, arg_classes, result_class = classify_value(
                    normalized, opaque
                )
                parts = split_top_level_arrows(normalized)
                operation_id = f"{sig_name}.{name}"
                item.update(
                    name=name,
                    type=normalized,
                    arguments=parts[:-1],
                    result_type=parts[-1],
                    argument_lowerings=arg_classes,
                    result_lowering=result_class,
                    lowering=lowering,
                    arity=arity,
                    original_symbol=operation_id,
                    operation_id=operation_id,
                    cake_name=cake_name(operation_id),
                )
        elif kind in {"type", "eqtype"}:
            m = TYPE.match(first)
            item.update(name=(m.group(1).split("=", 1)[0].strip() if m else first))
        elif kind in {"datatype", "exception", "include", "structure", "sharing"}:
            item.update(name=first.split(None, 1)[1] if " " in first else first)
        declarations.append(item)
    return {
        "signature": sig_name,
        "component": component_for(source_rel),
        "path": source_rel,
        "sha256": sha256(data),
        "declarations": declarations,
    }


def signature_paths(root: pathlib.Path, roots: list[str]) -> list[pathlib.Path]:
    paths: set[pathlib.Path] = set()
    for rel in roots:
        base = root / rel
        if base.is_file() and base.suffix == ".sig":
            paths.add(base)
        elif base.exists():
            paths.update(p for p in base.rglob("*.sig") if p.is_file() or p.is_symlink())
    return sorted(paths)


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
    inputs = config["inputs"]

    audit_paths = signature_paths(root, inputs.get("audit_roots", ["src"]))
    audit_inventory = []
    audit_by_hash: dict[str, list[str]] = collections.defaultdict(list)
    for p in audit_paths:
        data = p.read_bytes()
        rel = str(p.relative_to(root))
        digest = sha256(data)
        audit_inventory.append({"path": rel, "sha256": digest})
        audit_by_hash[digest].append(rel)

    public_dir = root / inputs.get("public_interface_dir", "sigobj")
    if not public_dir.exists():
        raise SystemExit(
            f"missing HOL4 public interface directory {public_dir}; build HOL4 first"
        )

    public_candidates = [
        p for p in public_dir.rglob("*.sig") if p.is_file() or p.is_symlink()
    ]
    mandatory = []
    for rel in inputs["mandatory_signatures"]:
        p = root / rel
        if not p.exists():
            raise SystemExit(f"missing mandatory signature: {rel}")
        mandatory.append((p, rel))

    # Resolve sigobj entries back to their source identities by content hash.
    selected: dict[tuple[str, str], tuple[pathlib.Path, str, str]] = {}
    for p in sorted(public_candidates):
        data = p.read_bytes()
        digest = sha256(data)
        matches = sorted(audit_by_hash.get(digest, []))
        source_rel = matches[0] if len(matches) == 1 else str(p.relative_to(root))
        selected[(source_rel, digest)] = (p, source_rel, "sigobj")
    for p, rel in mandatory:
        digest = sha256(p.read_bytes())
        selected[(rel, digest)] = (p, rel, "mandatory")

    signatures = []
    failures = []
    for _, (p, source_rel, origin) in sorted(selected.items()):
        try:
            parsed = parse_signature(p, source_rel, opaque)
            parsed["public_origin"] = origin
            signatures.append(parsed)
        except Exception as exc:
            failures.append({"path": source_rel, "error": str(exc)})

    declarations = [d for s in signatures for d in s["declarations"]]
    values = [d for d in declarations if d["kind"] == "val"]
    unsupported = [d for d in declarations if d["kind"] == "unsupported"]

    operation_locations: dict[str, list[str]] = collections.defaultdict(list)
    cake_name_locations: dict[str, list[str]] = collections.defaultdict(list)
    for s in signatures:
        for d in s["declarations"]:
            if d["kind"] == "val":
                operation_locations[d["operation_id"]].append(s["path"])
                cake_name_locations[d["cake_name"]].append(d["operation_id"])
    duplicates = {
        op: sorted(paths) for op, paths in operation_locations.items()
        if len(paths) > 1
    }
    cake_name_collisions = {
        name: sorted(set(ops)) for name, ops in cake_name_locations.items()
        if len(set(ops)) > 1
    }

    canonical = {
        "schema": 2,
        "public_interface": "HOL4 sigobj plus mandatory proof-automation signatures",
        "source_root": str(root),
        "source_commit": inputs["hol4"]["commit"],
        "signatures": signatures,
        "failures": failures,
        "duplicate_operation_ids": duplicates,
        "cake_name_collisions": cake_name_collisions,
        "source_interface_audit": {
            "signature_count": len(audit_inventory),
            "files": audit_inventory,
        },
        "summary": {
            "signature_count": len(signatures),
            "declaration_count": len(declarations),
            "value_count": len(values),
            "unsupported_count": (
                len(unsupported) + len(failures) + len(duplicates)
                + len(cake_name_collisions)
            ),
        },
        "components": {
            name: {
                "signature_count": sum(1 for s in signatures if s["component"] == name),
                "value_count": sum(
                    1 for s in signatures if s["component"] == name
                    for d in s["declarations"] if d["kind"] == "val"
                ),
            }
            for name in ("hol4", "z3_tac", "tactictoe")
        },
    }

    args.out.parent.mkdir(parents=True, exist_ok=True)
    payload = json.dumps(canonical, indent=2, sort_keys=True) + "\n"
    args.out.write_text(payload)
    (args.out.with_suffix(args.out.suffix + ".sha256")).write_text(
        f"{sha256(payload.encode())}  {args.out.name}\n"
    )

    for component in ("hol4", "z3_tac", "tactictoe"):
        subset = dict(canonical)
        subset["signatures"] = [
            s for s in signatures if s["component"] == component
        ]
        subset_decls = [
            d for s in subset["signatures"] for d in s["declarations"]
        ]
        subset["summary"] = {
            "signature_count": len(subset["signatures"]),
            "declaration_count": len(subset_decls),
            "value_count": sum(1 for d in subset_decls if d["kind"] == "val"),
            "unsupported_count": sum(
                1 for d in subset_decls if d["kind"] == "unsupported"
            ),
        }
        component_path = args.out.with_name(
            args.out.stem + "." + component + args.out.suffix
        )
        component_path.write_text(
            json.dumps(subset, indent=2, sort_keys=True) + "\n"
        )

    if args.strict and canonical["summary"]["unsupported_count"]:
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
