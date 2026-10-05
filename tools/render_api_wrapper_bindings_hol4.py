#!/usr/bin/env python3
"""Generate HOL4 CF proofs for every public generated wrapper.

The emitted theory is untrusted source text until HOL4 accepts it.
"""

from __future__ import annotations
import argparse
import json
import pathlib
import re


def hol_mlstring(s: str) -> str:
    if "«" in s or "»" in s:
        raise ValueError("operation id contains HOL quotation delimiter")
    return "«" + s + "»"


def theorem_name(cake_name: str) -> str:
    return re.sub(r"[^A-Za-z0-9_']", "_", cake_name) + "_spec"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("contract", type=pathlib.Path)
    ap.add_argument("out", type=pathlib.Path)
    args = ap.parse_args()

    data = json.loads(args.contract.read_text())
    if data["summary"]["unsupported_count"]:
        raise SystemExit("refusing to emit CF proofs with unsupported declarations")

    bindings = []
    for sig in data["signatures"]:
        for d in sig["declarations"]:
            if d["kind"] == "val":
                bindings.append((d["operation_id"], d["cake_name"]))
    bindings.sort()

    lines = [
        "Theory GeneratedApiWrapperBindings",
        "Ancestors",
        "  GeneratedApiWrapperSource",
        "Libs",
        "  preamble basis cfLib ml_progLib cfTacticsLib",
        "",
        "fun require_env name =",
        "  case OS.Process.getEnv name of",
        '    SOME s => s | NONE => raise Fail ("missing required environment variable: " ^ name);',
        "",
        'val source_path = require_env "GENERATED_API_WRAPPER_CML";',
        "val ins = TextIO.openIn source_path;",
        "val generated_source = TextIO.inputAll ins;",
        "val _ = TextIO.closeIn ins;",
        'val _ = translation_extends "basisProg";',
        "val generated_topdecs = cfTacticsLib.process_topdecs [QUOTE generated_source];",
        "val _ = ml_translatorLib.ml_prog_update (ml_progLib.add_prog generated_topdecs I);",
        "val generated_binding_st = ml_translatorLib.get_ml_prog_state();",
        "",
    ]

    for op, cake in bindings:
        thm = theorem_name(cake)
        lines.extend([
            f"Theorem {thm}:",
            "  !p av input s u s' output.",
            "    generated_api_frame_wf input /\\",
            f"    generated_api_bridge_transition u s {hol_mlstring(op)} input s' output ==>",
            "    app (p:'ffi ffi_proj)",
            f'      ^(fetch_v "{cake}" generated_binding_st)',
            "      [av]",
            "      (W8ARRAY av input * generated_api_io s u)",
            "      (POSTv v.",
            "        &(v = av) * W8ARRAY av output * generated_api_io s' u)",
            "Proof",
            "  rpt strip_tac",
            f'  \\ xcf "{cake}" generated_binding_st',
            "  \\ xapp_spec generated_api_call_spec",
            "  \\ xsimpl",
            "  \\ fs [STRING_TYPE_def]",
            "QED",
            "",
        ])

    lines.extend([
        "Theorem generated_api_binding_proof_count:",
        f"  {len(bindings)} = LENGTH generated_api_operations",
        "Proof",
        "  fs [generated_api_operation_count]",
        "QED",
        "",
        "val _ = export_theory();",
        "",
    ])

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text("\n".join(lines))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
