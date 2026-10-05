signature OriginalCompilerOutputAutomationContractTheory =
sig
  type thm = Thm.thm
  
  (*  Theorems  *)
    val library_code_address_bounds_z3 : thm
    val library_code_data_offsets_disjoint_z3 : thm
    val library_code_length : thm
    val library_data_length : thm
end
