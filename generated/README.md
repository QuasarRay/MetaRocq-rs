# Generated candidates

`python tools/bootstrap.py extract` writes `pcuic_isapp.ast` and `pcuic_isapp.rs`
only after the actual Rocq/Peregrine processes succeed and emit nonempty output.
No generated Rust is checked in at this checkpoint because those tools were absent.
The Cargo manifest intentionally fails to build until generation succeeds.
Do not fill this directory with hand-written code and label it extracted.
