From Stdlib Require Import String List Bool Arith.

Import ListNotations.
Open Scope string_scope.

Inductive ci_stage :=
| CIStart
| CIPinSources
| CIQuotePCUIC
| CILowerHOL
| CISerializeOpenTheory
| CICandleReplay
| CIPeregrineExtract
| CIProveResidualSafety
| CIComposeCakeMLImage
| CIVerifiedCakeMLCompile
| CIBindMachineIdentity
| CIReplaySelf
| CIAccept
| CIBlocked.

Inductive ci_action :=
| PinExactSources
| QuoteCompletePCUICSnapshot
| ProduceHOLDerivations
| SerializeOpenTheoryArticles
| ReplayWithEmbeddedCandle
| ExtractSingleLambdaBox
| ProveMetaRocqResidualSafe
| ComposeCandleCompilerMetaRocqImage
| CompileWithVerifiedCakeML
| BindSourceAndBinaryIdentity
| ReplayRecursiveSelfProof
| PublishAcceptedImage.

Record ci_instruction := {
  instruction_stage : ci_stage;
  instruction_action : ci_action;
  instruction_name : string
}.

Definition selfhost_ci_program : list ci_instruction :=
  [{| instruction_stage := CIPinSources;
      instruction_action := PinExactSources;
      instruction_name := "pin exact source and theorem identities" |};
   {| instruction_stage := CIQuotePCUIC;
      instruction_action := QuoteCompletePCUICSnapshot;
      instruction_name := "quote complete pinned PCUIC MetaTheory" |};
   {| instruction_stage := CILowerHOL;
      instruction_action := ProduceHOLDerivations;
      instruction_name := "produce proof-carrying HOL deep-embedding derivations" |};
   {| instruction_stage := CISerializeOpenTheory;
      instruction_action := SerializeOpenTheoryArticles;
      instruction_name := "serialize only proof-producing OpenTheory articles" |};
   {| instruction_stage := CICandleReplay;
      instruction_action := ReplayWithEmbeddedCandle;
      instruction_name := "replay articles through embedded verified OpenTheory/Candle path" |};
   {| instruction_stage := CIPeregrineExtract;
      instruction_action := ExtractSingleLambdaBox;
      instruction_name := "extract one reflective MetaRocq lambda-box root" |};
   {| instruction_stage := CIProveResidualSafety;
      instruction_action := ProveMetaRocqResidualSafe;
      instruction_name := "prove the appended MetaRocq residual safe and semantics preserving" |};
   {| instruction_stage := CIComposeCakeMLImage;
      instruction_action := ComposeCandleCompilerMetaRocqImage;
      instruction_name := "compose Candle prefix, compiler residual and MetaRocq residual" |};
   {| instruction_stage := CIVerifiedCakeMLCompile;
      instruction_action := CompileWithVerifiedCakeML;
      instruction_name := "compile through the pinned verified CakeML path" |};
   {| instruction_stage := CIBindMachineIdentity;
      instruction_action := BindSourceAndBinaryIdentity;
      instruction_name := "bind exact source, proof payload and machine-image identities" |};
   {| instruction_stage := CIReplaySelf;
      instruction_action := ReplayRecursiveSelfProof;
      instruction_name := "replay recursive self-proof from the installed image" |};
   {| instruction_stage := CIAccept;
      instruction_action := PublishAcceptedImage;
      instruction_name := "publish only after every previous proof gate succeeds" |}].

Definition expected_ci_instruction_count : nat := 12.

Definition ci_program_structure_ok : bool :=
  Nat.eqb (List.length selfhost_ci_program) expected_ci_instruction_count.

Theorem ci_program_has_expected_shape :
  ci_program_structure_ok = true.
Proof. reflexivity. Qed.
