From Stdlib Require Import String List.
From MetaRocq.Template Require Import Loader.

Import ListNotations.

Module PCUICModuleManifest.

(* Generated once from the pinned MetaRocq 1.5.1 source tree at
   7197056adbb9c15288b4c8d43407bf25786f723e.  The build gate compares this
   registry with that pinned tree; the trusted proof pipeline consumes this
   MetaRocq value, not a CI-side theorem list. *)
Definition pinned_source_revision : string :=
  "7197056adbb9c15288b4c8d43407bf25786f723e".

Definition pcuic_metatheory_modules : list qualid := [
  "MetaRocq.PCUIC.PCUICAlpha"%bs;
  "MetaRocq.PCUIC.PCUICArities"%bs;
  "MetaRocq.PCUIC.PCUICAst"%bs;
  "MetaRocq.PCUIC.PCUICCSubst"%bs;
  "MetaRocq.PCUIC.PCUICCanonicity"%bs;
  "MetaRocq.PCUIC.PCUICCasesContexts"%bs;
  "MetaRocq.PCUIC.PCUICCasesHelper"%bs;
  "MetaRocq.PCUIC.PCUICClassification"%bs;
  "MetaRocq.PCUIC.PCUICConfluence"%bs;
  "MetaRocq.PCUIC.PCUICConsistency"%bs;
  "MetaRocq.PCUIC.PCUICContextConversion"%bs;
  "MetaRocq.PCUIC.PCUICContextReduction"%bs;
  "MetaRocq.PCUIC.PCUICContextSubst"%bs;
  "MetaRocq.PCUIC.PCUICContexts"%bs;
  "MetaRocq.PCUIC.PCUICConvCumInversion"%bs;
  "MetaRocq.PCUIC.PCUICConversion"%bs;
  "MetaRocq.PCUIC.PCUICCumulProp"%bs;
  "MetaRocq.PCUIC.PCUICCumulativity"%bs;
  "MetaRocq.PCUIC.PCUICCumulativitySpec"%bs;
  "MetaRocq.PCUIC.PCUICElimination"%bs;
  "MetaRocq.PCUIC.PCUICEquality"%bs;
  "MetaRocq.PCUIC.PCUICEtaExpand"%bs;
  "MetaRocq.PCUIC.PCUICExpandLets"%bs;
  "MetaRocq.PCUIC.PCUICExpandLetsCorrectness"%bs;
  "MetaRocq.PCUIC.PCUICFirstorder"%bs;
  "MetaRocq.PCUIC.PCUICGeneration"%bs;
  "MetaRocq.PCUIC.PCUICGlobalEnv"%bs;
  "MetaRocq.PCUIC.PCUICGuardCondition"%bs;
  "MetaRocq.PCUIC.PCUICInductiveInversion"%bs;
  "MetaRocq.PCUIC.PCUICInductives"%bs;
  "MetaRocq.PCUIC.PCUICInversion"%bs;
  "MetaRocq.PCUIC.PCUICLoader"%bs;
  "MetaRocq.PCUIC.PCUICMonadAst"%bs;
  "MetaRocq.PCUIC.PCUICNormal"%bs;
  "MetaRocq.PCUIC.PCUICNormalization"%bs;
  "MetaRocq.PCUIC.PCUICParallelReduction"%bs;
  "MetaRocq.PCUIC.PCUICParallelReductionConfluence"%bs;
  "MetaRocq.PCUIC.PCUICPrincipality"%bs;
  "MetaRocq.PCUIC.PCUICProgram"%bs;
  "MetaRocq.PCUIC.PCUICProgress"%bs;
  "MetaRocq.PCUIC.PCUICRedTypeIrrelevance"%bs;
  "MetaRocq.PCUIC.PCUICReduction"%bs;
  "MetaRocq.PCUIC.PCUICSN"%bs;
  "MetaRocq.PCUIC.PCUICSR"%bs;
  "MetaRocq.PCUIC.PCUICSafeLemmata"%bs;
  "MetaRocq.PCUIC.PCUICSigmaCalculus"%bs;
  "MetaRocq.PCUIC.PCUICSpine"%bs;
  "MetaRocq.PCUIC.PCUICSubstitution"%bs;
  "MetaRocq.PCUIC.PCUICTelescopes"%bs;
  "MetaRocq.PCUIC.PCUICTypedAst"%bs;
  "MetaRocq.PCUIC.PCUICTyping"%bs;
  "MetaRocq.PCUIC.PCUICUnivLevels"%bs;
  "MetaRocq.PCUIC.PCUICValidity"%bs;
  "MetaRocq.PCUIC.PCUICWcbvEval"%bs;
  "MetaRocq.PCUIC.PCUICWeakeningConfig"%bs;
  "MetaRocq.PCUIC.PCUICWeakeningConfigSN"%bs;
  "MetaRocq.PCUIC.PCUICWeakeningEnv"%bs;
  "MetaRocq.PCUIC.PCUICWeakeningEnvSN"%bs;
  "MetaRocq.PCUIC.PCUICWellScopedCumulativity"%bs;
  "MetaRocq.PCUIC.PCUICWfCases"%bs;
  "MetaRocq.PCUIC.PCUICWfUniverses"%bs;
  "MetaRocq.PCUIC.PCUICWtCumulativity"%bs;
  "MetaRocq.PCUIC.Bidirectional.BDFromPCUIC"%bs;
  "MetaRocq.PCUIC.Bidirectional.BDStrengthening"%bs;
  "MetaRocq.PCUIC.Bidirectional.BDToPCUIC"%bs;
  "MetaRocq.PCUIC.Bidirectional.BDTyping"%bs;
  "MetaRocq.PCUIC.Bidirectional.BDUnique"%bs;
  "MetaRocq.PCUIC.Conversion.PCUICClosedConv"%bs;
  "MetaRocq.PCUIC.Conversion.PCUICInstConv"%bs;
  "MetaRocq.PCUIC.Conversion.PCUICNamelessConv"%bs;
  "MetaRocq.PCUIC.Conversion.PCUICOnFreeVarsConv"%bs;
  "MetaRocq.PCUIC.Conversion.PCUICRenameConv"%bs;
  "MetaRocq.PCUIC.Conversion.PCUICUnivSubstitutionConv"%bs;
  "MetaRocq.PCUIC.Conversion.PCUICWeakeningConfigConv"%bs;
  "MetaRocq.PCUIC.Conversion.PCUICWeakeningConv"%bs;
  "MetaRocq.PCUIC.Conversion.PCUICWeakeningEnvConv"%bs;
  "MetaRocq.PCUIC.Syntax.PCUICCases"%bs;
  "MetaRocq.PCUIC.Syntax.PCUICClosed"%bs;
  "MetaRocq.PCUIC.Syntax.PCUICDepth"%bs;
  "MetaRocq.PCUIC.Syntax.PCUICInduction"%bs;
  "MetaRocq.PCUIC.Syntax.PCUICInstDef"%bs;
  "MetaRocq.PCUIC.Syntax.PCUICLiftSubst"%bs;
  "MetaRocq.PCUIC.Syntax.PCUICNamelessDef"%bs;
  "MetaRocq.PCUIC.Syntax.PCUICOnFreeVars"%bs;
  "MetaRocq.PCUIC.Syntax.PCUICPosition"%bs;
  "MetaRocq.PCUIC.Syntax.PCUICReflect"%bs;
  "MetaRocq.PCUIC.Syntax.PCUICRenameDef"%bs;
  "MetaRocq.PCUIC.Syntax.PCUICTactics"%bs;
  "MetaRocq.PCUIC.Syntax.PCUICUnivSubst"%bs;
  "MetaRocq.PCUIC.Syntax.PCUICViews"%bs;
  "MetaRocq.PCUIC.Typing.PCUICClosedTyp"%bs;
  "MetaRocq.PCUIC.Typing.PCUICContextConversionTyp"%bs;
  "MetaRocq.PCUIC.Typing.PCUICInstTyp"%bs;
  "MetaRocq.PCUIC.Typing.PCUICNamelessTyp"%bs;
  "MetaRocq.PCUIC.Typing.PCUICRenameTyp"%bs;
  "MetaRocq.PCUIC.Typing.PCUICUnivSubstitutionTyp"%bs;
  "MetaRocq.PCUIC.Typing.PCUICWeakeningConfigTyp"%bs;
  "MetaRocq.PCUIC.Typing.PCUICWeakeningEnvTyp"%bs;
  "MetaRocq.PCUIC.Typing.PCUICWeakeningTyp"%bs;
  "MetaRocq.PCUIC.utils.PCUICAstUtils"%bs;
  "MetaRocq.PCUIC.utils.PCUICOnOne"%bs;
  "MetaRocq.PCUIC.utils.PCUICPretty"%bs;
  "MetaRocq.PCUIC.utils.PCUICPrimitive"%bs;
  "MetaRocq.PCUIC.utils.PCUICSize"%bs;
  "MetaRocq.PCUIC.utils.PCUICUtils"%bs
].

Definition expected_module_count : nat := 105.

Definition manifest_count_ok : bool :=
  Nat.eqb (List.length pcuic_metatheory_modules) expected_module_count.

End PCUICModuleManifest.
