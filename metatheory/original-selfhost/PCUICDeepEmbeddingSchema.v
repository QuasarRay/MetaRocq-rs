From Stdlib Require Import String List Bool Arith.
From MetaRocq.PCUIC Require Import PCUICAst.

Import ListNotations.
Open Scope string_scope.

Inductive pcuic_term_constructor :=
| HCRel
| HCVar
| HCEvar
| HCSort
| HCProd
| HCLambda
| HCLetIn
| HCApp
| HCConst
| HCInd
| HCConstruct
| HCCase
| HCProj
| HCFix
| HCCoFix
| HCPrim.

Definition pcuic_term_constructors : list pcuic_term_constructor :=
  [HCRel; HCVar; HCEvar; HCSort; HCProd; HCLambda; HCLetIn; HCApp;
   HCConst; HCInd; HCConstruct; HCCase; HCProj; HCFix; HCCoFix; HCPrim].

Definition constructor_inventory_complete : bool :=
  Nat.eqb (List.length pcuic_term_constructors) 16.

Theorem constructor_inventory_has_pinned_shape :
  constructor_inventory_complete = true.
Proof. reflexivity. Qed.

Inductive hol_prelude_obligation :=
| DefinePCUICTermType
| DefinePCUICContextType
| DefinePCUICGlobalEnvType
| DefinePCUICUniverseTypes
| DefinePCUICPrimitiveTypes
| DefinePCUICTermConstructors
| ProveConstructorDistinctness
| ProveConstructorInjectivity
| DefinePCUICTypingRelation
| DefinePCUICReductionRelation
| DefinePCUICCumulativityRelation
| ProveEncodingRoundTrip
| ProveCheckerEncodingFaithful
| ProveCheckerSoundnessInHOL.

Definition required_hol_prelude_obligations : list hol_prelude_obligation :=
  [DefinePCUICTermType;
   DefinePCUICContextType;
   DefinePCUICGlobalEnvType;
   DefinePCUICUniverseTypes;
   DefinePCUICPrimitiveTypes;
   DefinePCUICTermConstructors;
   ProveConstructorDistinctness;
   ProveConstructorInjectivity;
   DefinePCUICTypingRelation;
   DefinePCUICReductionRelation;
   DefinePCUICCumulativityRelation;
   ProveEncodingRoundTrip;
   ProveCheckerEncodingFaithful;
   ProveCheckerSoundnessInHOL].

Definition required_hol_prelude_obligation_count : nat := 14.

Definition hol_prelude_shape_ok : bool :=
  Nat.eqb
    (List.length required_hol_prelude_obligations)
    required_hol_prelude_obligation_count.

Theorem hol_prelude_has_expected_obligations :
  hol_prelude_shape_ok = true.
Proof. reflexivity. Qed.

Record hol_prelude_evidence := {
  prelude_term_type : bool;
  prelude_context_type : bool;
  prelude_global_env_type : bool;
  prelude_universe_types : bool;
  prelude_primitive_types : bool;
  prelude_term_constructors : bool;
  prelude_constructor_distinctness : bool;
  prelude_constructor_injectivity : bool;
  prelude_typing_relation : bool;
  prelude_reduction_relation : bool;
  prelude_cumulativity_relation : bool;
  prelude_round_trip : bool;
  prelude_checker_faithful : bool;
  prelude_checker_sound : bool
}.

Definition hol_prelude_evidence_complete (e : hol_prelude_evidence) : bool :=
  e.(prelude_term_type)
  && e.(prelude_context_type)
  && e.(prelude_global_env_type)
  && e.(prelude_universe_types)
  && e.(prelude_primitive_types)
  && e.(prelude_term_constructors)
  && e.(prelude_constructor_distinctness)
  && e.(prelude_constructor_injectivity)
  && e.(prelude_typing_relation)
  && e.(prelude_reduction_relation)
  && e.(prelude_cumulativity_relation)
  && e.(prelude_round_trip)
  && e.(prelude_checker_faithful)
  && e.(prelude_checker_sound).
