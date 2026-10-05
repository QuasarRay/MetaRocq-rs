(* Proof search remains in HOL4. These facts concern image layout only. *)
structure CompilerOutputAutomationLib :> CompilerOutputAutomationLib =
struct
open HolKernel boolLib bossLib wordsTheory integerTheory listTheory;

fun inspect_exact name expected th =
  let val (oracles, axioms) = Tag.dest_tag (Thm.tag th)
  in
    if null (Thm.hyp th) andalso aconv (Thm.concl th) expected andalso
       List.all (fn tag => tag = "DISK_THM") oracles andalso null axioms
    then () else raise Fail ("Open, contaminated, or wrong theorem: " ^ name)
  end;

fun length_fact compiled image =
  let
    val _ = inspect_exact "compiler input" (Thm.concl compiled) compiled
    val length_tm = listSyntax.mk_length image
    fun matches th = is_eq (Thm.concl th) andalso
      aconv (lhs (Thm.concl th)) length_tm andalso
      numSyntax.is_numeral (rhs (Thm.concl th))
  in
    case List.find matches (CONJUNCTS compiled) of
      SOME th => (Thm.concl th, th)
    | NONE => raise Fail "Compiler theorem does not contain this image's exact numeric length"
  end;

fun image_layout_facts {compiled,code,data} =
  let
    val _ = if type_of code = ``:word8 list`` andalso
               type_of data = ``:word64 list`` then ()
            else raise Fail "Image-layout automation requires x64 code bytes and 64-bit data words"
    val (code_goal, code_length) = length_fact compiled code
    val (data_goal, data_length) = length_fact compiled data
    val address_goal =
      ``!base i:int.
          0 <= base /\
          base + &(LENGTH ^code + 8 * LENGTH ^data) < 18446744073709551616 /\
          0 <= i /\ i < &(LENGTH ^code) ==>
          0 <= base + i /\ base + i < 18446744073709551616``
    val disjoint_goal =
      ``!base i j:int.
          0 <= i /\ i < &(LENGTH ^code) /\
          0 <= j /\ j < &(LENGTH ^data) ==>
          base + i < base + &(LENGTH ^code) + 8 * j``
    fun reconstruct goal = prove
      (goal, REWRITE_TAC [code_length,data_length] >> HolSmtLib.Z3_TAC)
    val address = reconstruct address_goal
    val disjoint = reconstruct disjoint_goal
    val facts = [("code_length",code_goal,code_length),
                 ("data_length",data_goal,data_length),
                 ("code_address_bounds_z3",address_goal,address),
                 ("code_data_offsets_disjoint_z3",disjoint_goal,disjoint)]
    val _ = List.app (fn (name,expected,th) => inspect_exact name expected th) facts
  in facts end;

fun code_nonempty_tactictoe {compiled,code} =
  let
    val (_,code_length) = length_fact compiled code
    val goal = ``^code <> []``
    val _ = tacticToe.set_timeout 30.0
    val th = Lib.with_flag
      (tacticToe.prioritize_stacl,
       "bossLib.simp []" :: !tacticToe.prioritize_stacl)
      (fn () => prove (goal, REWRITE_TAC [GSYM listTheory.LENGTH_NIL] >>
                            mp_tac code_length >> tacticToe.ttt)) ()
    val _ = inspect_exact "code_nonempty_tactictoe" goal th
  in (goal,th) end;
end
