signature OriginalBootstrapCompilerProbeTheory =
sig
  type thm = Thm.thm
  
  (*  Definitions  *)
    val original_bootstrap_probe_code_def : thm
    val original_bootstrap_probe_compiled : thm
    val original_bootstrap_probe_conf_def : thm
    val original_bootstrap_probe_data_def : thm
    val original_bootstrap_probe_ffis_def : thm
    val original_bootstrap_probe_machine_code_def : thm
    val original_bootstrap_probe_prog_cv_def : thm
    val original_bootstrap_probe_prog_def : thm
  
  (*  Theorems  *)
    val original_bootstrap_probe_evaluated : thm
    val original_bootstrap_probe_prog_cv_eq : thm
    val original_bootstrap_probe_prog_cv_thm : thm
    val original_bootstrap_probe_temp_oracle_cv_thm : thm
end
