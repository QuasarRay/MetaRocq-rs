#!/usr/bin/env python3
"""Render exact canonical API inventory into an HOL4 theory script.

The extractor is intentionally untrusted. This generated script binds the
operation inventory, source commit, source-file SHA-256 digests and canonical
contract digest into HOL4 values which the kernel subsequently checks.
"""

from __future__ import annotations
import argparse, hashlib, json, pathlib


def sml_string(s: str) -> str:
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'


def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument("contract", type=pathlib.Path)
    ap.add_argument("out", type=pathlib.Path)
    args=ap.parse_args()

    raw=args.contract.read_bytes()
    data=json.loads(raw)
    if data["summary"]["unsupported_count"]:
        raise SystemExit("refusing HOL4 contract with unsupported declarations")

    ops=sorted(
        d["operation_id"]
        for s in data["signatures"]
        for d in s["declarations"]
        if d["kind"] == "val"
    )
    files=sorted((s["path"],s["sha256"]) for s in data["signatures"])
    digest=hashlib.sha256(raw).hexdigest()
    commit=data["source_commit"]

    op_ml="[" + ",".join(sml_string(x) for x in ops) + "]"
    file_ml="[" + ",".join(
        "(" + sml_string(p) + "," + sml_string(h) + ")" for p,h in files
    ) + "]"

    script=f'''Theory GeneratedApiContract
Ancestors
  list
Libs
  preamble

val op_terms = map stringSyntax.fromMLstring {op_ml};
val ops_tm = listSyntax.mk_list (op_terms,stringSyntax.string_ty);
val generated_api_operations_def =
  Define `generated_api_operations = ^ops_tm`;

val source_file_terms =
  map (fn (p,h) => pairSyntax.mk_pair
        (stringSyntax.fromMLstring p,stringSyntax.fromMLstring h))
      {file_ml};
val pair_ty = pairSyntax.mk_prod
  (stringSyntax.string_ty,stringSyntax.string_ty);
val source_files_tm = listSyntax.mk_list (source_file_terms,pair_ty);
val generated_api_source_files_def =
  Define `generated_api_source_files = ^source_files_tm`;

val source_commit_tm = stringSyntax.fromMLstring {sml_string(commit)};
val generated_api_source_commit_def =
  Define `generated_api_source_commit = ^source_commit_tm`;

val contract_digest_tm = stringSyntax.fromMLstring {sml_string(digest)};
val generated_api_contract_digest_def =
  Define `generated_api_contract_digest = ^contract_digest_tm`;

Theorem generated_api_operation_count:
  LENGTH generated_api_operations = {len(ops)}
Proof
  EVAL_TAC
QED

Theorem generated_api_source_file_count:
  LENGTH generated_api_source_files = {len(files)}
Proof
  EVAL_TAC
QED

val _ = export_theory();
'''
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(script)
    return 0


if __name__=="__main__":
    raise SystemExit(main())
