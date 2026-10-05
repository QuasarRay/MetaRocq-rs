signature CompilerOutputAutomationLib =
sig
  val inspect_exact : string -> Term.term -> Thm.thm -> unit
  val image_layout_facts :
    {compiled : Thm.thm, code : Term.term, data : Term.term} ->
    (string * Term.term * Thm.thm) list
  val code_nonempty_tactictoe :
    {compiled : Thm.thm, code : Term.term} -> Term.term * Thm.thm
end
