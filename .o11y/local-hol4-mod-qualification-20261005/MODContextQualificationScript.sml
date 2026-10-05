Theory MODContextQualification
Ancestors arithmetic
Libs LegacyMODLib

val _ = Parse.temp_set_fixity "MOD" (Parse.Infixl 650);
val expected = ``n * (p MOD q):num``;
val actual = ``n * p MOD q:num``;
val _ = if Term.aconv expected actual then print "Historical MOD parse retained.\n"
        else raise Fail "Historical MOD parse lost";
Theorem mod_parse_preserved:
  !n p q. 0 < n /\ 0 < q ==>
    ((n * p) MOD (n * q) = n * p MOD q)
Proof
  fs [GSYM MOD_COMMON_FACTOR]
QED
val _ = if null (Thm.hyp mod_parse_preserved) andalso
  (Tag.isEmpty (Thm.tag mod_parse_preserved) orelse Tag.isDisk (Thm.tag mod_parse_preserved))
  then print "Kernel-checked closed MOD theorem.\n" else raise Fail "Unexpected proof dependencies";
