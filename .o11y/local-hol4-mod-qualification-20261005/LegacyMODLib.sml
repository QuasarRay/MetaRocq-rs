structure LegacyMODLib = struct
val _ = Parse.temp_set_fixity "MOD" (Parse.Infixl 650);
val _ = Theory.register_hook ("CakeML.legacy_MOD", fn TheoryDelta.NewTheory _ => Parse.temp_set_fixity "MOD" (Parse.Infixl 650) | _ => ());
end
