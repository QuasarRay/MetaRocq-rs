structure OriginalCompilerOutputAutomationTheory :> OriginalCompilerOutputAutomationTheory =
struct
  
  val _ = if !Globals.print_thy_loads
    then TextIO.print "Loading OriginalCompilerOutputAutomationTheory ... "
    else ()
  
  open Type Term Thm
  local open HolSmtTheory OriginalBootstrapCompilerProbeTheory in end;
  
  structure TDB = struct
    val path =
      OS.Path.base (#(FILE)) ^ ".dat"
    val timestamp = HOLFileSys.modTime path
    val thydata = 
      TheoryReader.load_thydata {
        thyname = "OriginalCompilerOutputAutomation",
        hash = "1a2d59bb5df9d9d5149487c13cc9a630c9903866",
        path = path
      }
    fun find s = #1 (valOf (Symtab.lookup thydata s))
  end
  val () = Theory.record_metadata
    "OriginalCompilerOutputAutomation"
      {timestamp=TDB.timestamp, path=TDB.path}
  
  fun op probe_output_sizes _ = ()
  val op probe_output_sizes = TDB.find "probe_output_sizes"
  fun op probe_code_data_offsets_disjoint_z3 _ = ()
  val op probe_code_data_offsets_disjoint_z3 = TDB.find
    "probe_code_data_offsets_disjoint_z3"
  fun op probe_code_address_bounds_z3 _ = ()
  val op probe_code_address_bounds_z3 = TDB.find
    "probe_code_address_bounds_z3"
  
val _ = if !Globals.print_thy_loads then TextIO.print "done\n" else ()
val _ = Theory.load_complete "OriginalCompilerOutputAutomation"

end
