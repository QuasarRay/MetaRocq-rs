structure OriginalBootstrapCompilerProbeTheory :> OriginalBootstrapCompilerProbeTheory =
struct
  
  val _ = if !Globals.print_thy_loads
    then TextIO.print "Loading OriginalBootstrapCompilerProbeTheory ... "
    else ()
  
  open Type Term Thm
  local open backend_x64_cvTheory in end;
  
  structure TDB = struct
    val path =
      OS.Path.base (#(FILE)) ^ ".dat"
    val timestamp = HOLFileSys.modTime path
    val thydata = 
      TheoryReader.load_thydata {
        thyname = "OriginalBootstrapCompilerProbe",
        hash = "3aaa1bd76d4c6ed3f234258d7079e94e50f9bb6b",
        path = path
      }
    fun find s = #1 (valOf (Symtab.lookup thydata s))
  end
  val () = Theory.record_metadata
    "OriginalBootstrapCompilerProbe"
      {timestamp=TDB.timestamp, path=TDB.path}
  
  fun op original_bootstrap_probe_temp_oracle_cv_thm _ = ()
  val op original_bootstrap_probe_temp_oracle_cv_thm = TDB.find
    "original_bootstrap_probe_temp_oracle_cv_thm"
  fun op original_bootstrap_probe_prog_def _ = ()
  val op original_bootstrap_probe_prog_def = TDB.find
    "original_bootstrap_probe_prog_def"
  fun op original_bootstrap_probe_prog_cv_thm _ = ()
  val op original_bootstrap_probe_prog_cv_thm = TDB.find
    "original_bootstrap_probe_prog_cv_thm"
  fun op original_bootstrap_probe_prog_cv_eq _ = ()
  val op original_bootstrap_probe_prog_cv_eq = TDB.find
    "original_bootstrap_probe_prog_cv_eq"
  fun op original_bootstrap_probe_prog_cv_def _ = ()
  val op original_bootstrap_probe_prog_cv_def = TDB.find
    "original_bootstrap_probe_prog_cv_def"
  fun op original_bootstrap_probe_machine_code_def _ = ()
  val op original_bootstrap_probe_machine_code_def = TDB.find
    "original_bootstrap_probe_machine_code_def"
  fun op original_bootstrap_probe_ffis_def _ = ()
  val op original_bootstrap_probe_ffis_def = TDB.find
    "original_bootstrap_probe_ffis_def"
  fun op original_bootstrap_probe_evaluated _ = ()
  val op original_bootstrap_probe_evaluated = TDB.find
    "original_bootstrap_probe_evaluated"
  fun op original_bootstrap_probe_data_def _ = ()
  val op original_bootstrap_probe_data_def = TDB.find
    "original_bootstrap_probe_data_def"
  fun op original_bootstrap_probe_conf_def _ = ()
  val op original_bootstrap_probe_conf_def = TDB.find
    "original_bootstrap_probe_conf_def"
  fun op original_bootstrap_probe_compiled _ = ()
  val op original_bootstrap_probe_compiled = TDB.find
    "original_bootstrap_probe_compiled"
  fun op original_bootstrap_probe_code_def _ = ()
  val op original_bootstrap_probe_code_def = TDB.find
    "original_bootstrap_probe_code_def"
  
val _ = if !Globals.print_thy_loads then TextIO.print "done\n" else ()
val _ = Theory.load_complete "OriginalBootstrapCompilerProbe"

end
