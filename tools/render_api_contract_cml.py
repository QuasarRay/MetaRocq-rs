#!/usr/bin/env python3
"""Render canonical API JSON as CakeML data consumed by ApiWrapperGenerator."""

from __future__ import annotations
import argparse, json, pathlib


def q(s: str) -> str:
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"').replace("\n", "\\n") + '"'



def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("contract", type=pathlib.Path)
    ap.add_argument("out", type=pathlib.Path)
    args = ap.parse_args()
    data = json.loads(args.contract.read_text())
    if data["summary"]["unsupported_count"]:
        raise SystemExit("refusing to render contract with unsupported declarations")

    rows = []
    for sig in data["signatures"]:
        for d in sig["declarations"]:
            if d["kind"] != "val":
                continue
            rows.append((
                sig.get("component", "hol4"),
                sig["signature"], d["name"], d["operation_id"],
                d["cake_name"], d["type"], d["lowering"],
            ))
    rows.sort(key=lambda r: r[2])
    body = ",\n    ".join(
        "(" + ",".join(q(x) for x in row) + ")" for row in rows
    )
    out = (
        "(* machine-generated canonical API data; do not edit *)\n"
        f"val generated_api_operation_count = {len(rows)};\n"
        "val generated_api_contract =\n  ["
        + body + "];\n"
    )
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
