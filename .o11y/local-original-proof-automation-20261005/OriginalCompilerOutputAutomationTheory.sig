signature OriginalCompilerOutputAutomationTheory =
sig
  type thm = Thm.thm
  
  (*  Theorems  *)
    val probe_code_address_bounds_z3 : thm
    val probe_code_data_offsets_disjoint_z3 : thm
    val probe_output_sizes : thm
end
