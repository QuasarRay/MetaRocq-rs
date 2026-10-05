structure OriginalCompilerOutputAutomationContractTheory :> OriginalCompilerOutputAutomationContractTheory =
struct
  
  val _ = if !Globals.print_thy_loads
    then TextIO.print "Loading OriginalCompilerOutputAutomationContractTheory ... "
    else ()
  
  open Type Term Thm
  local open OriginalCompilerOutputAutomationTheory in end;
  
  structure TDB = struct
    val path =
      OS.Path.base (#(FILE)) ^ ".dat"
    val timestamp = HOLFileSys.modTime path
    val thydata = 
      TheoryReader.load_thydata {
        thyname = "OriginalCompilerOutputAutomationContract",
        hash = "863ec023e0c6e0b584500340cc0d5dea00f0c881",
        path = path
      }
    fun find s = #1 (valOf (Symtab.lookup thydata s))
  end
  val () = Theory.record_metadata
    "OriginalCompilerOutputAutomationContract"
      {timestamp=TDB.timestamp, path=TDB.path}
  
  fun op library_data_length _ = ()
  val op library_data_length = TDB.find "library_data_length"
  fun op library_code_length _ = ()
  val op library_code_length = TDB.find "library_code_length"
  fun op library_code_data_offsets_disjoint_z3 _ = ()
  val op library_code_data_offsets_disjoint_z3 = TDB.find
    "library_code_data_offsets_disjoint_z3"
  fun op library_code_address_bounds_z3 _ = ()
  val op library_code_address_bounds_z3 = TDB.find
    "library_code_address_bounds_z3"
  
val _ = if !Globals.print_thy_loads then TextIO.print "done\n" else ()
val _ = Theory.load_complete "OriginalCompilerOutputAutomationContract"

end
