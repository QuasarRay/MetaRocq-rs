signature GeneratedApiRuntime =
sig
  (* The implementation is the only native runtime boundary.  It must satisfy
     the generated foreign contract: same operation id, same canonical codec,
     explicit failure, no raw Poly/ML object identity across the boundary. *)
  val call : string -> Word8Vector.vector -> Word8Vector.vector
end
