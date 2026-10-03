use crate::pcuic::*;
use std::marker::PhantomData as P;

// Bounded representation probes. Original isApp discriminates only the outer
// constructor; this is not the missing cross-language representation theorem.
fn check_application_case(application: bool) {
    let program = Program::new();
    let zero = Corelib_Init_Datatypes_nat::O(P);
    let variable = MetaRocq_PCUIC_PCUICAst_term::tRel(P, &zero);
    let app = MetaRocq_PCUIC_PCUICAst_term::tApp(P, &variable, &variable);
    let term = if application { &app } else { &variable };
    let result = program.MetaRocq_PCUIC_PCUICAst_isApp(term);
    assert_eq!(matches!(result, Corelib_Init_Datatypes_bool::r#true(_)), application);
}

#[test]
fn original_predicate_application_and_variable() {
    check_application_case(false);
    check_application_case(true);
}

#[cfg(kani)]
#[kani::proof]
fn pcuic_isapp() { check_application_case(kani::any()); }
