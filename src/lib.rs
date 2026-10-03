//! Generated candidates. Compilation and retained proof data are not refinement proofs.
#![forbid(unsafe_code)]
#[allow(dead_code, non_camel_case_types, unused_imports, non_snake_case, unused_variables)]
pub mod pcuic {
    include!(concat!(env!("OUT_DIR"), "/pcuic_isapp.rs"));
}
#[cfg(feature = "retained")]
#[allow(dead_code, non_camel_case_types, unused_imports, non_snake_case, unused_variables)]
pub mod retained {
    include!(concat!(env!("OUT_DIR"), "/retained.rs"));
}

#[cfg(any(test, kani))]
mod proofs;
