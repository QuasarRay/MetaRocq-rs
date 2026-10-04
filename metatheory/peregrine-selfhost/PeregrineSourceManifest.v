From Stdlib Require Import String List.
From MetaRocq.Template Require Import Loader.
From MetaRocq.Common Require Import Kernames.

Import ListNotations.
Open Scope string_scope.

Module PeregrineSourceManifest.

Definition pinned_peregrine_revision : string :=
  "d768b83ffa7dab35b8d72241f0570b5bb6aedae9".

Definition pinned_peregrine_tree : string :=
  "b0c82eded52366ba1b4dcee930ba83e712ec638b".

Definition peregrine_modules : list qualid := [
  "Peregrine.PAst"%bs;
  "Peregrine.Utils"%bs;
  "Peregrine.Config"%bs;
  "Peregrine.ConfigUtils"%bs;
  "Peregrine.Unicode"%bs;
  "Peregrine.UnicodeXID"%bs;
  "Peregrine.NameSanitize"%bs;
  "Peregrine.CheckWf"%bs;
  "Peregrine.EvalBox"%bs;
  "Peregrine.CoqToLambdaBox"%bs;
  "Peregrine.Extraction"%bs;
  "Peregrine.Pipeline"%bs;
  "Peregrine.erasure.Erasure"%bs;
  "Peregrine.erasure.ErasureTyped"%bs;
  "Peregrine.erasure.Transforms"%bs;
  "Peregrine.erasure.EImplementLazyForce"%bs;
  "Peregrine.backends.RustBackend"%bs;
  "Peregrine.backends.ElmBackend"%bs;
  "Peregrine.backends.OCamlBackend"%bs;
  "Peregrine.backends.CakeMLBackend"%bs;
  "Peregrine.backends.CBackend"%bs;
  "Peregrine.backends.WasmBackend"%bs;
  "Peregrine.backends.CertiRocqBackend"%bs;
  "Peregrine.backends.EvalBackend"%bs;
  "Peregrine.backends.ASTBackend"%bs;
  "Peregrine.serialization.Deserialize"%bs;
  "Peregrine.serialization.Serialize"%bs;
  "Peregrine.serialization.SerializeComplete"%bs;
  "Peregrine.serialization.SerializeSound"%bs;
  "Peregrine.serialization.DeserializeCommon"%bs;
  "Peregrine.serialization.SerializeCommon"%bs;
  "Peregrine.serialization.SerializeCommonComplete"%bs;
  "Peregrine.serialization.SerializeCommonSound"%bs;
  "Peregrine.serialization.DeserializePrimitives"%bs;
  "Peregrine.serialization.SerializePrimitives"%bs;
  "Peregrine.serialization.SerializePrimitivesComplete"%bs;
  "Peregrine.serialization.SerializePrimitivesSound"%bs;
  "Peregrine.serialization.DeserializeEAst"%bs;
  "Peregrine.serialization.SerializeEAst"%bs;
  "Peregrine.serialization.SerializeEAstComplete"%bs;
  "Peregrine.serialization.SerializeEAstSound"%bs;
  "Peregrine.serialization.DeserializeExAst"%bs;
  "Peregrine.serialization.SerializeExAst"%bs;
  "Peregrine.serialization.SerializeExAstComplete"%bs;
  "Peregrine.serialization.SerializeExAstSound"%bs;
  "Peregrine.serialization.DeserializePAst"%bs;
  "Peregrine.serialization.SerializePAst"%bs;
  "Peregrine.serialization.SerializePAstComplete"%bs;
  "Peregrine.serialization.SerializePAstSound"%bs;
  "Peregrine.serialization.DeserializeConfig"%bs;
  "Peregrine.serialization.SerializeConfig"%bs;
  "Peregrine.serialization.SerializeConfigComplete"%bs;
  "Peregrine.serialization.SerializeConfigSound"%bs;
  "Peregrine.serialization.SerializeLambdaBoxMut"%bs;
  "Peregrine.serialization.SerializeLambdaBoxLocal"%bs;
  "Peregrine.serialization.SerializeLambdaANF"%bs
].

Definition expected_module_count : nat := 56.

Definition manifest_count_ok : bool :=
  Nat.eqb (List.length peregrine_modules) expected_module_count.

End PeregrineSourceManifest.
