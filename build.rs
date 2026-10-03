use std::{env, fs, path::PathBuf};

fn main() {
    let mut names = vec!["pcuic_isapp"];
    if env::var_os("CARGO_FEATURE_RETAINED").is_some() { names.push("retained"); }
    for name in names {
        let input = format!("generated/{name}.rs");
        println!("cargo:rerun-if-changed={input}");
        let raw = fs::read_to_string(&input).expect("run the pinned Peregrine extraction first");
        let normalized = metarocq_rust_normalize::normalize(&raw).expect("invalid generated Rust syntax");
        let out = PathBuf::from(env::var_os("OUT_DIR").unwrap()).join(format!("{name}.rs"));
        fs::write(out, normalized).unwrap();
    }
}
