#!/usr/bin/env python3
"""Generate HOL4 characteristic-formula proofs for every CakeML API wrapper.

The generated theory reads the exact generated CakeML source, installs it in
CakeML's proof-producing program state, and proves each wrapper is precisely one
#(custom) call whose configuration bytes encode the original operation id.
"""

from __future__ import annotations

import argparse
import json
import pathlib
import re


def hol_string(value: str) -> str:
    return '"' + value.replace('\\', '\\\\').replace('"', '\\"') + '"'


def theorem_name(cake_name: str) -> str:
    return re.sub(r"[^A-Za-z0-9_]", "_", cake_name) + "_ffi_spec"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("contract", type=pathlib.Path)
    ap.add_argument("out", type=pathlib.Path)
    args = ap.parse_args()

    data = json.loads(args.contract.read_text())
    if data["summary"]["unsupported_count"]:
        raise SystemExit("refusing FFI proofs for incomplete API contract")

    values = sorted(
        (
            d["operation_id"],
            d["cake_name"],
        )
        for sig in data["signatures"]
        for d in sig["declarations"]
        if d["kind"] == "val"
    )

    proofs = []
    theorem_ids = []
    for op, cake in values:
        tid = theorem_name(cake)
        theorem_ids.append(tid)
        proofs.append(f"""
Theorem {tid}:
  !p original foreign events av input.
    limited_parts generated_api_names p /\\
    generated_foreign_bytes_refines_original original foreign ==>
    app (p:'ffi ffi_proj) ^(fetch_v {hol_string(cake)} st) [av]
      (W8ARRAY av input * generated_api_ffi foreign events)
      (POSTv v. &(v = av) *
                W8ARRAY av (original {hol_string(op)} input) *
                SEP_EXISTS events'. generated_api_ffi foreign events')
Proof
  rpt strip_tac
  \\ xcf {hol_string(cake)} st
  \\ xlet `POSTv uv. &UNIT_TYPE () uv *
                W8ARRAY av (original {hol_string(op)} input) *
                SEP_EXISTS events'. generated_api_ffi foreign events'`
  THEN1 (
    xffi \\ xsimpl
    \\ fs [generated_api_ffi_def, generated_api_update_def,
             generated_api_names_def,
             generated_foreign_bytes_refines_original_def,
             generated_api_conf_def]
    \\ MAP_EVERY qexists_tac
         [`generated_api_conf {hol_string(op)}`, `emp`,
          `cfFFIType$List []`, `generated_api_update foreign`,
          `generated_api_names`, `events`]
    \\ fs [generated_api_update_def, generated_api_names_def,
             generated_foreign_bytes_refines_original_def,
             generated_api_conf_def]
    \\ xsimpl)
  \\ xvar \\ xsimpl
QED
""")

    thm_list = ",\n       ".join(theorem_ids)
    script = f"""Theory GeneratedApiWrapperFfi
Ancestors
  GeneratedApiContract GeneratedApiWrapperModel basis_ffi Word8ArrayProof
Libs
  preamble basis

val _ = translation_extends "basisProg";

fun require_env name =
  case OS.Process.getEnv name of
    SOME s => s
  | NONE => raise Fail ("missing required environment variable: " ^ name);

val generated_source_path = require_env "GENERATED_API_WRAPPER_CML";
val generated_source_stream = TextIO.openIn generated_source_path;
val generated_source = TextIO.inputAll generated_source_stream;
val _ = TextIO.closeIn generated_source_stream;

(* Parse and install the exact generated wrapper source into CakeML's
   characteristic-formula program state. *)
val _ = add_cakeml [QUOTE generated_source];
val st = get_ml_prog_state();

Definition generated_api_names_def:
  generated_api_names = [«custom»]
End

Definition generated_api_update_def:
  generated_api_update
    (foreign:word8 list -> word8 list -> word8 list option)
    name conf bytes state =
      if name = «custom» then
        case foreign conf bytes of
          NONE => NONE
        | SOME out => SOME (FFIreturn out state)
      else NONE
End

Definition generated_api_ffi_def:
  generated_api_ffi foreign events =
    one (FFI_part (cfFFIType$List [])
         (generated_api_update foreign)
         generated_api_names events)
End

{"".join(proofs)}

val generated_api_wrapper_specs =
      [{thm_list}];

fun generated_spec_clean th =
  let val (oracles,axioms) = Tag.dest_tag (Thm.tag th)
  in null (Thm.hyp th) andalso
     List.all (fn s => s = "DISK_THM") oracles andalso
     null axioms
  end;

val _ =
  if List.length generated_api_wrapper_specs = {len(values)} andalso
     List.all generated_spec_clean generated_api_wrapper_specs
  then ()
  else raise Fail "generated wrapper FFI specification qualification failed";

fun conj_all [] = TRUTH
  | conj_all [th] = th
  | conj_all (th::ths) = CONJ th (conj_all ths);

val generated_api_wrapper_all_ffi_specs =
  conj_all generated_api_wrapper_specs |> check_thm;

val _ = save_thm
  ("generated_api_wrapper_all_ffi_specs",
   generated_api_wrapper_all_ffi_specs);

Theorem generated_api_wrapper_ffi_spec_count:
  LENGTH generated_api_bindings = {len(values)}
Proof
  EVAL_TAC
QED

val _ = export_theory();
"""
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(script)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
