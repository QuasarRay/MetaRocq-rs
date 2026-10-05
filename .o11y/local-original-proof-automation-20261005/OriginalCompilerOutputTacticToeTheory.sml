structure OriginalCompilerOutputTacticToeTheory :> OriginalCompilerOutputTacticToeTheory =
struct
  
  val _ = if !Globals.print_thy_loads
    then TextIO.print "Loading OriginalCompilerOutputTacticToeTheory ... "
    else ()
  
  open Type Term Thm
  local open OriginalCompilerOutputAutomationTheory in end;
  
  structure TDB = struct
    val path =
      OS.Path.base (#(FILE)) ^ ".dat"
    val timestamp = HOLFileSys.modTime path
    val thydata = 
      TheoryReader.load_thydata {
        thyname = "OriginalCompilerOutputTacticToe",
        hash = "15e21cd44e61ffb4460b7a0e5a5337f7265a1c40",
        path = path
      }
    fun find s = #1 (valOf (Symtab.lookup thydata s))
  end
  val () = Theory.record_metadata
    "OriginalCompilerOutputTacticToe"
      {timestamp=TDB.timestamp, path=TDB.path}
  
  fun op probe_code_nonempty_tactictoe _ = ()
  val op probe_code_nonempty_tactictoe = TDB.find
    "probe_code_nonempty_tactictoe"
  
val _ = if !Globals.print_thy_loads then TextIO.print "done\n" else ()
val _ = Theory.load_complete "OriginalCompilerOutputTacticToe"

end
