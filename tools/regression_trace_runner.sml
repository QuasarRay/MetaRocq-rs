(*
  Trace worker for the unified E2E pipeline.

  Directly reuses utilLib.sml from the exact pinned CakeML/regression checkout,
  and follows worker.sml's model: one task at a time, combined stdout/stderr,
  /usr/bin/time resource capture, explicit success/failure, and fail-closed
  downstream blocking.  Stage 23 is policy=always and therefore still records
  provenance/open obligations after an earlier semantic stage blocks.
*)

use ".aegis/references/cakeml-regression/utilLib.sml";
open utilLib;

type stage = string * string * string * string * string * string;

fun die msg =
  (TextIO.output (TextIO.stdErr, msg ^ "\n");
   OS.Process.exit OS.Process.failure);

fun ensure_dir p =
  if OS.FileSys.access (p, []) then ()
  else OS.FileSys.mkDir p;

fun write_file path body = output_to_file (path, body);

fun copy_file src dst = write_file dst (file_to_string src);

fun split_tab line = String.tokens (fn c => c = #"\t") (trimr line);

fun read_plan path =
  let
    val inp = TextIO.openIn path
    fun loop acc =
      case TextIO.inputLine inp of
        NONE => (TextIO.closeIn inp; List.rev acc)
      | SOME line =>
          (case split_tab line of
             [id, name, instruction, digest, policy, command] =>
               loop ((id, name, instruction, digest, policy, command) :: acc)
           | _ => die ("invalid six-field pipeline TSV record: " ^ line))
  in loop [] end;

(* All generated commands and repository paths are controlled by the checked-in
   CakeML plan.  Single-quote escaping is still implemented so trace paths are
   safe if a runner workspace ever contains apostrophes. *)
fun shell_quote s =
  let
    fun esc [] = []
      | esc (#"'" :: cs) = #"'" :: #"\\" :: #"'" :: #"'" :: esc cs
      | esc (c :: cs) = c :: esc cs
  in "'" ^ String.implode (esc (String.explode s)) ^ "'" end;

fun stage_dir root id name = OS.Path.concat (root, id ^ "-" ^ name);

fun stage_fields ((id, name, instruction, digest, policy, command):stage) =
  (id, name, instruction, digest, policy, command);

fun write_stage_metadata dir stage =
  let val (id, name, instruction, digest, policy, command) = stage_fields stage in
    write_file (OS.Path.concat (dir, "stage-id.txt")) (id ^ "\n");
    write_file (OS.Path.concat (dir, "stage-name.txt")) (name ^ "\n");
    write_file (OS.Path.concat (dir, "instruction-source.txt")) (instruction ^ "\n");
    write_file (OS.Path.concat (dir, "instruction-sha256.expected")) (digest ^ "\n");
    write_file (OS.Path.concat (dir, "policy.txt")) (policy ^ "\n");
    write_file (OS.Path.concat (dir, "command.txt")) (command ^ "\n")
  end;

fun compact_trace () =
  case OS.Process.getEnv "UNIFIED_E2E_TRACE_COMPACT" of
    SOME "1" => true
  | SOME "true" => true
  | SOME "TRUE" => true
  | _ => false;

fun materialize_instruction dir instruction =
  if compact_trace () then ()
  else if OS.FileSys.access (instruction, [OS.FileSys.A_READ]) then
    copy_file instruction (OS.Path.concat (dir, "instruction.md"))
  else ();

fun verify_instruction dir instruction digest =
  let
    val actual_file = OS.Path.concat (dir, "instruction-sha256.actual")
    val cmd = String.concat
      ["sha256sum ", shell_quote instruction, " >", shell_quote actual_file, " 2>&1"]
    val hashed = OS.Process.isSuccess (OS.Process.system cmd)
    val actual = if hashed then until_space (file_to_string actual_file) else ""
    val _ = write_file (OS.Path.concat (dir, "instruction-sha256.match"))
              ((if actual = digest then "true" else "false") ^ "\n")
  in hashed andalso actual = digest end;

fun mark_skipped root blocker stage =
  let
    val (id, name, instruction, _, _, _) = stage_fields stage
    val dir = stage_dir root id name
    val _ = ensure_dir dir
    val _ = write_stage_metadata dir stage
    val _ = materialize_instruction dir instruction
    val _ = write_file (OS.Path.concat (dir, "status.txt")) "SKIPPED\n"
    val _ = write_file (OS.Path.concat (dir, "blocked-by.txt")) (blocker ^ "\n")
  in () end;

fun env_true name =
  case OS.Process.getEnv name of
    SOME "1" => true
  | SOME "true" => true
  | SOME "TRUE" => true
  | _ => false;

fun run_stage root stage =
  let
    val (id, name, instruction, digest, _, command) = stage_fields stage
    val dir = stage_dir root id name
    val _ = ensure_dir dir
    val _ = write_stage_metadata dir stage
    val _ = materialize_instruction dir instruction
    val capture = OS.Path.concat (dir, "regression.log")
    val timing = OS.Path.concat (dir, "timing.log")
    val statusf = OS.Path.concat (dir, "status.txt")
    val injected =
      case OS.Process.getEnv "UNIFIED_E2E_FAIL_STAGE" of
        SOME x => x = id
      | NONE => false
    val dry = env_true "UNIFIED_E2E_TRACE_DRY_RUN"
    val actual =
      if injected then "echo injected-failure-for-stage-" ^ id ^ "; false"
      else if dry then "echo dry-run-success-for-stage-" ^ id ^ "; true"
      else command
    val _ = write_file statusf "RUNNING\n"
    val _ = if injected then write_file (OS.Path.concat (dir, "failure-injected.txt")) "true\n" else ()
    val _ = if dry then write_file (OS.Path.concat (dir, "trace-dry-run.txt")) "true\n" else ()
    val instruction_ok = verify_instruction dir instruction digest
    val _ = if instruction_ok then () else
              write_file (OS.Path.concat (dir, "instruction-integrity-failure.txt"))
                "The checked-in instruction does not match the digest emitted by the CakeML pipeline.\n"
    val wrapped = String.concat
      ["/usr/bin/time --format='%e %M %x' --output=", shell_quote timing,
       " sh -c ", shell_quote actual,
       " >", shell_quote capture, " 2>&1"]
    val ok = instruction_ok andalso OS.Process.isSuccess (OS.Process.system wrapped)
    val _ = write_file statusf (if ok then "SUCCESS\n" else "FAILED\n")
  in ok end;

fun finish_manifest root result blocker =
  let
    val body =
      "result=" ^ result ^ "\n" ^
      "blocked_by=" ^ blocker ^ "\n" ^
      "regression_commit=23cfeba74d0cef77f7274ab41a2e8e87d4032995\n"
  in write_file (OS.Path.concat (root, "run-status.txt")) body end;

fun run_after_failure root blocker [] always_ok = always_ok
  | run_after_failure root blocker (stage :: rest) always_ok =
      let val (id, _, _, _, policy, _) = stage_fields stage in
        if policy = "always" then
          run_after_failure root blocker rest (run_stage root stage andalso always_ok)
        else
          (mark_skipped root blocker stage;
           run_after_failure root blocker rest always_ok)
      end;

fun run [] root = (finish_manifest root "SUCCESS" ""; true)
  | run (stage :: rest) root =
      let val (id, _, _, _, _, _) = stage_fields stage in
        if run_stage root stage then run rest root
        else
          let val always_ok = run_after_failure root id rest true
              val _ = finish_manifest root "FAILED" id
          in false andalso always_ok end
      end;

fun main () =
  case CommandLine.arguments () of
    [plan, root] =>
      let
        val _ = ensure_dir root
        val _ = copy_file plan (OS.Path.concat (root, "pipeline.tsv"))
        val _ = write_file (OS.Path.concat (root, "runner-provenance.txt"))
          "execution model: CakeML/regression worker-style capture\nsource dependency: .aegis/references/cakeml-regression/utilLib.sml\ncommit: 23cfeba74d0cef77f7274ab41a2e8e87d4032995\n"
        val stages = read_plan plan
        val _ = if List.length stages = 23 then () else die "pipeline must contain exactly 23 stages"
        val ok = run stages root
      in OS.Process.exit (if ok then OS.Process.success else OS.Process.failure) end
  | _ => die "usage: regression_trace_runner.sml <pipeline.tsv> <run-dir>";

main ();
