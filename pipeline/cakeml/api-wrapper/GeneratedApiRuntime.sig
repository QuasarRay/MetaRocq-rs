signature GeneratedApiRuntime =
sig
  (* Canonical native-side bridge for generated wrappers.

     The byte vector is a fixed-envelope protocol.  Its first 16 bytes are
     reserved for status/version/result-handle metadata.  Complex and
     polymorphic SML values remain inside the Poly/ML/HOL4 process and are
     named by opaque handles; no native Poly/ML pointer, closure or theorem
     representation crosses into CakeML.

     The implementation must:
       - dispatch the exact operation id,
       - reject malformed frames,
       - never write beyond the supplied frame,
       - preserve frame length on return,
       - encode failures in-band rather than fabricating success. *)
  val call : string -> Word8Vector.vector -> Word8Vector.vector
end
