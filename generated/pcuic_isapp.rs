#![allow(dead_code)]
#![allow(non_camel_case_types)]
#![allow(unused_imports)]
#![allow(non_snake_case)]
#![allow(unused_variables)]

use std::marker::PhantomData;

fn hint_app<TArg, TRet>(f: &dyn Fn(TArg) -> TRet) -> &dyn Fn(TArg) -> TRet {
  f
}


#[derive(Debug, Clone)]
pub enum Corelib_Init_Datatypes_nat<'a> {
  O(PhantomData<&'a ()>),
  S(PhantomData<&'a ()>, &'a Corelib_Init_Datatypes_nat<'a>)
}

#[derive(Debug, Clone)]
pub enum Corelib_Init_Byte_byte<'a> {
  x00(PhantomData<&'a ()>),
  x01(PhantomData<&'a ()>),
  x02(PhantomData<&'a ()>),
  x03(PhantomData<&'a ()>),
  x04(PhantomData<&'a ()>),
  x05(PhantomData<&'a ()>),
  x06(PhantomData<&'a ()>),
  x07(PhantomData<&'a ()>),
  x08(PhantomData<&'a ()>),
  x09(PhantomData<&'a ()>),
  x0a(PhantomData<&'a ()>),
  x0b(PhantomData<&'a ()>),
  x0c(PhantomData<&'a ()>),
  x0d(PhantomData<&'a ()>),
  x0e(PhantomData<&'a ()>),
  x0f(PhantomData<&'a ()>),
  x10(PhantomData<&'a ()>),
  x11(PhantomData<&'a ()>),
  x12(PhantomData<&'a ()>),
  x13(PhantomData<&'a ()>),
  x14(PhantomData<&'a ()>),
  x15(PhantomData<&'a ()>),
  x16(PhantomData<&'a ()>),
  x17(PhantomData<&'a ()>),
  x18(PhantomData<&'a ()>),
  x19(PhantomData<&'a ()>),
  x1a(PhantomData<&'a ()>),
  x1b(PhantomData<&'a ()>),
  x1c(PhantomData<&'a ()>),
  x1d(PhantomData<&'a ()>),
  x1e(PhantomData<&'a ()>),
  x1f(PhantomData<&'a ()>),
  x20(PhantomData<&'a ()>),
  x21(PhantomData<&'a ()>),
  x22(PhantomData<&'a ()>),
  x23(PhantomData<&'a ()>),
  x24(PhantomData<&'a ()>),
  x25(PhantomData<&'a ()>),
  x26(PhantomData<&'a ()>),
  x27(PhantomData<&'a ()>),
  x28(PhantomData<&'a ()>),
  x29(PhantomData<&'a ()>),
  x2a(PhantomData<&'a ()>),
  x2b(PhantomData<&'a ()>),
  x2c(PhantomData<&'a ()>),
  x2d(PhantomData<&'a ()>),
  x2e(PhantomData<&'a ()>),
  x2f(PhantomData<&'a ()>),
  x30(PhantomData<&'a ()>),
  x31(PhantomData<&'a ()>),
  x32(PhantomData<&'a ()>),
  x33(PhantomData<&'a ()>),
  x34(PhantomData<&'a ()>),
  x35(PhantomData<&'a ()>),
  x36(PhantomData<&'a ()>),
  x37(PhantomData<&'a ()>),
  x38(PhantomData<&'a ()>),
  x39(PhantomData<&'a ()>),
  x3a(PhantomData<&'a ()>),
  x3b(PhantomData<&'a ()>),
  x3c(PhantomData<&'a ()>),
  x3d(PhantomData<&'a ()>),
  x3e(PhantomData<&'a ()>),
  x3f(PhantomData<&'a ()>),
  x40(PhantomData<&'a ()>),
  x41(PhantomData<&'a ()>),
  x42(PhantomData<&'a ()>),
  x43(PhantomData<&'a ()>),
  x44(PhantomData<&'a ()>),
  x45(PhantomData<&'a ()>),
  x46(PhantomData<&'a ()>),
  x47(PhantomData<&'a ()>),
  x48(PhantomData<&'a ()>),
  x49(PhantomData<&'a ()>),
  x4a(PhantomData<&'a ()>),
  x4b(PhantomData<&'a ()>),
  x4c(PhantomData<&'a ()>),
  x4d(PhantomData<&'a ()>),
  x4e(PhantomData<&'a ()>),
  x4f(PhantomData<&'a ()>),
  x50(PhantomData<&'a ()>),
  x51(PhantomData<&'a ()>),
  x52(PhantomData<&'a ()>),
  x53(PhantomData<&'a ()>),
  x54(PhantomData<&'a ()>),
  x55(PhantomData<&'a ()>),
  x56(PhantomData<&'a ()>),
  x57(PhantomData<&'a ()>),
  x58(PhantomData<&'a ()>),
  x59(PhantomData<&'a ()>),
  x5a(PhantomData<&'a ()>),
  x5b(PhantomData<&'a ()>),
  x5c(PhantomData<&'a ()>),
  x5d(PhantomData<&'a ()>),
  x5e(PhantomData<&'a ()>),
  x5f(PhantomData<&'a ()>),
  x60(PhantomData<&'a ()>),
  x61(PhantomData<&'a ()>),
  x62(PhantomData<&'a ()>),
  x63(PhantomData<&'a ()>),
  x64(PhantomData<&'a ()>),
  x65(PhantomData<&'a ()>),
  x66(PhantomData<&'a ()>),
  x67(PhantomData<&'a ()>),
  x68(PhantomData<&'a ()>),
  x69(PhantomData<&'a ()>),
  x6a(PhantomData<&'a ()>),
  x6b(PhantomData<&'a ()>),
  x6c(PhantomData<&'a ()>),
  x6d(PhantomData<&'a ()>),
  x6e(PhantomData<&'a ()>),
  x6f(PhantomData<&'a ()>),
  x70(PhantomData<&'a ()>),
  x71(PhantomData<&'a ()>),
  x72(PhantomData<&'a ()>),
  x73(PhantomData<&'a ()>),
  x74(PhantomData<&'a ()>),
  x75(PhantomData<&'a ()>),
  x76(PhantomData<&'a ()>),
  x77(PhantomData<&'a ()>),
  x78(PhantomData<&'a ()>),
  x79(PhantomData<&'a ()>),
  x7a(PhantomData<&'a ()>),
  x7b(PhantomData<&'a ()>),
  x7c(PhantomData<&'a ()>),
  x7d(PhantomData<&'a ()>),
  x7e(PhantomData<&'a ()>),
  x7f(PhantomData<&'a ()>),
  x80(PhantomData<&'a ()>),
  x81(PhantomData<&'a ()>),
  x82(PhantomData<&'a ()>),
  x83(PhantomData<&'a ()>),
  x84(PhantomData<&'a ()>),
  x85(PhantomData<&'a ()>),
  x86(PhantomData<&'a ()>),
  x87(PhantomData<&'a ()>),
  x88(PhantomData<&'a ()>),
  x89(PhantomData<&'a ()>),
  x8a(PhantomData<&'a ()>),
  x8b(PhantomData<&'a ()>),
  x8c(PhantomData<&'a ()>),
  x8d(PhantomData<&'a ()>),
  x8e(PhantomData<&'a ()>),
  x8f(PhantomData<&'a ()>),
  x90(PhantomData<&'a ()>),
  x91(PhantomData<&'a ()>),
  x92(PhantomData<&'a ()>),
  x93(PhantomData<&'a ()>),
  x94(PhantomData<&'a ()>),
  x95(PhantomData<&'a ()>),
  x96(PhantomData<&'a ()>),
  x97(PhantomData<&'a ()>),
  x98(PhantomData<&'a ()>),
  x99(PhantomData<&'a ()>),
  x9a(PhantomData<&'a ()>),
  x9b(PhantomData<&'a ()>),
  x9c(PhantomData<&'a ()>),
  x9d(PhantomData<&'a ()>),
  x9e(PhantomData<&'a ()>),
  x9f(PhantomData<&'a ()>),
  xa0(PhantomData<&'a ()>),
  xa1(PhantomData<&'a ()>),
  xa2(PhantomData<&'a ()>),
  xa3(PhantomData<&'a ()>),
  xa4(PhantomData<&'a ()>),
  xa5(PhantomData<&'a ()>),
  xa6(PhantomData<&'a ()>),
  xa7(PhantomData<&'a ()>),
  xa8(PhantomData<&'a ()>),
  xa9(PhantomData<&'a ()>),
  xaa(PhantomData<&'a ()>),
  xab(PhantomData<&'a ()>),
  xac(PhantomData<&'a ()>),
  xad(PhantomData<&'a ()>),
  xae(PhantomData<&'a ()>),
  xaf(PhantomData<&'a ()>),
  xb0(PhantomData<&'a ()>),
  xb1(PhantomData<&'a ()>),
  xb2(PhantomData<&'a ()>),
  xb3(PhantomData<&'a ()>),
  xb4(PhantomData<&'a ()>),
  xb5(PhantomData<&'a ()>),
  xb6(PhantomData<&'a ()>),
  xb7(PhantomData<&'a ()>),
  xb8(PhantomData<&'a ()>),
  xb9(PhantomData<&'a ()>),
  xba(PhantomData<&'a ()>),
  xbb(PhantomData<&'a ()>),
  xbc(PhantomData<&'a ()>),
  xbd(PhantomData<&'a ()>),
  xbe(PhantomData<&'a ()>),
  xbf(PhantomData<&'a ()>),
  xc0(PhantomData<&'a ()>),
  xc1(PhantomData<&'a ()>),
  xc2(PhantomData<&'a ()>),
  xc3(PhantomData<&'a ()>),
  xc4(PhantomData<&'a ()>),
  xc5(PhantomData<&'a ()>),
  xc6(PhantomData<&'a ()>),
  xc7(PhantomData<&'a ()>),
  xc8(PhantomData<&'a ()>),
  xc9(PhantomData<&'a ()>),
  xca(PhantomData<&'a ()>),
  xcb(PhantomData<&'a ()>),
  xcc(PhantomData<&'a ()>),
  xcd(PhantomData<&'a ()>),
  xce(PhantomData<&'a ()>),
  xcf(PhantomData<&'a ()>),
  xd0(PhantomData<&'a ()>),
  xd1(PhantomData<&'a ()>),
  xd2(PhantomData<&'a ()>),
  xd3(PhantomData<&'a ()>),
  xd4(PhantomData<&'a ()>),
  xd5(PhantomData<&'a ()>),
  xd6(PhantomData<&'a ()>),
  xd7(PhantomData<&'a ()>),
  xd8(PhantomData<&'a ()>),
  xd9(PhantomData<&'a ()>),
  xda(PhantomData<&'a ()>),
  xdb(PhantomData<&'a ()>),
  xdc(PhantomData<&'a ()>),
  xdd(PhantomData<&'a ()>),
  xde(PhantomData<&'a ()>),
  xdf(PhantomData<&'a ()>),
  xe0(PhantomData<&'a ()>),
  xe1(PhantomData<&'a ()>),
  xe2(PhantomData<&'a ()>),
  xe3(PhantomData<&'a ()>),
  xe4(PhantomData<&'a ()>),
  xe5(PhantomData<&'a ()>),
  xe6(PhantomData<&'a ()>),
  xe7(PhantomData<&'a ()>),
  xe8(PhantomData<&'a ()>),
  xe9(PhantomData<&'a ()>),
  xea(PhantomData<&'a ()>),
  xeb(PhantomData<&'a ()>),
  xec(PhantomData<&'a ()>),
  xed(PhantomData<&'a ()>),
  xee(PhantomData<&'a ()>),
  xef(PhantomData<&'a ()>),
  xf0(PhantomData<&'a ()>),
  xf1(PhantomData<&'a ()>),
  xf2(PhantomData<&'a ()>),
  xf3(PhantomData<&'a ()>),
  xf4(PhantomData<&'a ()>),
  xf5(PhantomData<&'a ()>),
  xf6(PhantomData<&'a ()>),
  xf7(PhantomData<&'a ()>),
  xf8(PhantomData<&'a ()>),
  xf9(PhantomData<&'a ()>),
  xfa(PhantomData<&'a ()>),
  xfb(PhantomData<&'a ()>),
  xfc(PhantomData<&'a ()>),
  xfd(PhantomData<&'a ()>),
  xfe(PhantomData<&'a ()>),
  xff(PhantomData<&'a ()>)
}

#[derive(Debug, Clone)]
pub enum MetaRocq_Utils_bytestring_String_t<'a> {
  EmptyString(PhantomData<&'a ()>),
  String(PhantomData<&'a ()>, &'a Corelib_Init_Byte_byte<'a>, &'a MetaRocq_Utils_bytestring_String_t<'a>)
}

type MetaRocq_Common_Kernames_ident<'a> = &'a MetaRocq_Utils_bytestring_String_t<'a>;

#[derive(Debug, Clone)]
pub enum Corelib_Init_Datatypes_list<'a, A> {
  nil(PhantomData<&'a A>, ()),
  cons(PhantomData<&'a A>, (), A, &'a Corelib_Init_Datatypes_list<'a, A>)
}

#[derive(Debug, Clone)]
pub enum MetaRocq_Common_Universes_Sort_t_<'a, univ> {
  sProp(PhantomData<&'a univ>, ()),
  sSProp(PhantomData<&'a univ>, ()),
  sType(PhantomData<&'a univ>, (), univ)
}

#[derive(Debug, Clone)]
pub enum Corelib_Init_Datatypes_prod<'a, A, B> {
  pair(PhantomData<&'a (A, B)>, (), (), A, B)
}

#[derive(Debug, Clone)]
pub enum MetaRocq_Common_Universes_Level_t_<'a> {
  lzero(PhantomData<&'a ()>),
  level(PhantomData<&'a ()>, &'a MetaRocq_Utils_bytestring_String_t<'a>),
  lvar(PhantomData<&'a ()>, &'a Corelib_Init_Datatypes_nat<'a>)
}

type MetaRocq_Common_Universes_Level_t<'a> = &'a MetaRocq_Common_Universes_Level_t_<'a>;

type MetaRocq_Common_Universes_LevelExprSet_Raw_elt<'a> = &'a Corelib_Init_Datatypes_prod<'a, MetaRocq_Common_Universes_Level_t<'a>, &'a Corelib_Init_Datatypes_nat<'a>>;

type MetaRocq_Common_Universes_LevelExprSet_Raw_t<'a> = &'a Corelib_Init_Datatypes_list<'a, MetaRocq_Common_Universes_LevelExprSet_Raw_elt<'a>>;

#[derive(Debug, Clone)]
pub enum Corelib_Init_Datatypes_bool<'a> {
  r#true(PhantomData<&'a ()>),
  r#false(PhantomData<&'a ()>)
}

#[derive(Debug, Clone)]
pub enum MetaRocq_Common_Universes_LevelExprSet_t_<'a> {
  Mkt(PhantomData<&'a ()>, MetaRocq_Common_Universes_LevelExprSet_Raw_t<'a>, ())
}

type MetaRocq_Common_Universes_LevelExprSet_t<'a> = &'a MetaRocq_Common_Universes_LevelExprSet_t_<'a>;

#[derive(Debug, Clone)]
pub enum MetaRocq_Common_Universes_nonEmptyLevelExprSet<'a> {
  Build_nonEmptyLevelExprSet(PhantomData<&'a ()>, MetaRocq_Common_Universes_LevelExprSet_t<'a>, ())
}

type MetaRocq_Common_Universes_Universe_t<'a> = &'a MetaRocq_Common_Universes_nonEmptyLevelExprSet<'a>;

type MetaRocq_Common_Universes_Sort_t<'a> = &'a MetaRocq_Common_Universes_Sort_t_<'a, MetaRocq_Common_Universes_Universe_t<'a>>;

#[derive(Debug, Clone)]
pub enum MetaRocq_Common_BasicAst_relevance<'a> {
  Relevant(PhantomData<&'a ()>),
  Irrelevant(PhantomData<&'a ()>)
}

#[derive(Debug, Clone)]
pub enum MetaRocq_Common_BasicAst_binder_annot<'a, A> {
  mkBindAnn(PhantomData<&'a A>, (), A, &'a MetaRocq_Common_BasicAst_relevance<'a>)
}

#[derive(Debug, Clone)]
pub enum MetaRocq_Common_BasicAst_name<'a> {
  nAnon(PhantomData<&'a ()>),
  nNamed(PhantomData<&'a ()>, MetaRocq_Common_Kernames_ident<'a>)
}

type MetaRocq_Common_BasicAst_aname<'a> = &'a MetaRocq_Common_BasicAst_binder_annot<'a, &'a MetaRocq_Common_BasicAst_name<'a>>;

type MetaRocq_Common_Kernames_dirpath<'a> = &'a Corelib_Init_Datatypes_list<'a, MetaRocq_Common_Kernames_ident<'a>>;

#[derive(Debug, Clone)]
pub enum MetaRocq_Common_Kernames_modpath<'a> {
  MPfile(PhantomData<&'a ()>, MetaRocq_Common_Kernames_dirpath<'a>),
  MPbound(PhantomData<&'a ()>, MetaRocq_Common_Kernames_dirpath<'a>, MetaRocq_Common_Kernames_ident<'a>, &'a Corelib_Init_Datatypes_nat<'a>),
  MPdot(PhantomData<&'a ()>, &'a MetaRocq_Common_Kernames_modpath<'a>, MetaRocq_Common_Kernames_ident<'a>)
}

type MetaRocq_Common_Kernames_kername<'a> = &'a Corelib_Init_Datatypes_prod<'a, &'a MetaRocq_Common_Kernames_modpath<'a>, MetaRocq_Common_Kernames_ident<'a>>;

type MetaRocq_Common_Universes_Instance_t<'a> = &'a Corelib_Init_Datatypes_list<'a, MetaRocq_Common_Universes_Level_t<'a>>;

#[derive(Debug, Clone)]
pub enum MetaRocq_Common_Kernames_inductive<'a> {
  mkInd(PhantomData<&'a ()>, MetaRocq_Common_Kernames_kername<'a>, &'a Corelib_Init_Datatypes_nat<'a>)
}

#[derive(Debug, Clone)]
pub enum MetaRocq_Common_BasicAst_case_info<'a> {
  mk_case_info(PhantomData<&'a ()>, &'a MetaRocq_Common_Kernames_inductive<'a>, &'a Corelib_Init_Datatypes_nat<'a>, &'a MetaRocq_Common_BasicAst_relevance<'a>)
}

#[derive(Debug, Clone)]
pub enum Corelib_Init_Datatypes_option<'a, A> {
  Some(PhantomData<&'a A>, (), A),
  None(PhantomData<&'a A>, ())
}

#[derive(Debug, Clone)]
pub enum MetaRocq_Common_BasicAst_context_decl<'a, term> {
  mkdecl(PhantomData<&'a term>, (), MetaRocq_Common_BasicAst_aname<'a>, &'a Corelib_Init_Datatypes_option<'a, term>, term)
}

#[derive(Debug, Clone)]
pub enum MetaRocq_PCUIC_PCUICAst_predicate<'a, term> {
  mk_predicate(PhantomData<&'a term>, (), &'a Corelib_Init_Datatypes_list<'a, term>, MetaRocq_Common_Universes_Instance_t<'a>, &'a Corelib_Init_Datatypes_list<'a, &'a MetaRocq_Common_BasicAst_context_decl<'a, term>>, term)
}

#[derive(Debug, Clone)]
pub enum MetaRocq_PCUIC_PCUICAst_branch<'a, term> {
  mk_branch(PhantomData<&'a term>, (), &'a Corelib_Init_Datatypes_list<'a, &'a MetaRocq_Common_BasicAst_context_decl<'a, term>>, term)
}

#[derive(Debug, Clone)]
pub enum MetaRocq_Common_Kernames_projection<'a> {
  mkProjection(PhantomData<&'a ()>, &'a MetaRocq_Common_Kernames_inductive<'a>, &'a Corelib_Init_Datatypes_nat<'a>, &'a Corelib_Init_Datatypes_nat<'a>)
}

#[derive(Debug, Clone)]
pub enum MetaRocq_Common_BasicAst_def<'a, term> {
  mkdef(PhantomData<&'a term>, (), MetaRocq_Common_BasicAst_aname<'a>, term, term, &'a Corelib_Init_Datatypes_nat<'a>)
}

type MetaRocq_Common_BasicAst_mfixpoint<'a, term> = &'a Corelib_Init_Datatypes_list<'a, &'a MetaRocq_Common_BasicAst_def<'a, term>>;

#[derive(Debug, Clone)]
pub enum Corelib_Init_Specif_sigT<'a, A, P> {
  existT(PhantomData<&'a (A, P)>, (), &'a dyn Fn(A) -> (), A, P)
}

#[derive(Debug, Clone)]
pub enum MetaRocq_Common_Primitive_prim_tag<'a> {
  primInt(PhantomData<&'a ()>),
  primFloat(PhantomData<&'a ()>),
  primString(PhantomData<&'a ()>),
  primArray(PhantomData<&'a ()>)
}

type MetaRocq_PCUIC_utils_PCUICPrimitive_prim_val<'a, term> = &'a Corelib_Init_Specif_sigT<'a, &'a MetaRocq_Common_Primitive_prim_tag<'a>, ()>;

#[derive(Debug, Clone)]
pub enum MetaRocq_PCUIC_PCUICAst_term<'a> {
  tRel(PhantomData<&'a ()>, &'a Corelib_Init_Datatypes_nat<'a>),
  tVar(PhantomData<&'a ()>, MetaRocq_Common_Kernames_ident<'a>),
  tEvar(PhantomData<&'a ()>, &'a Corelib_Init_Datatypes_nat<'a>, &'a Corelib_Init_Datatypes_list<'a, &'a MetaRocq_PCUIC_PCUICAst_term<'a>>),
  tSort(PhantomData<&'a ()>, MetaRocq_Common_Universes_Sort_t<'a>),
  tProd(PhantomData<&'a ()>, MetaRocq_Common_BasicAst_aname<'a>, &'a MetaRocq_PCUIC_PCUICAst_term<'a>, &'a MetaRocq_PCUIC_PCUICAst_term<'a>),
  tLambda(PhantomData<&'a ()>, MetaRocq_Common_BasicAst_aname<'a>, &'a MetaRocq_PCUIC_PCUICAst_term<'a>, &'a MetaRocq_PCUIC_PCUICAst_term<'a>),
  tLetIn(PhantomData<&'a ()>, MetaRocq_Common_BasicAst_aname<'a>, &'a MetaRocq_PCUIC_PCUICAst_term<'a>, &'a MetaRocq_PCUIC_PCUICAst_term<'a>, &'a MetaRocq_PCUIC_PCUICAst_term<'a>),
  tApp(PhantomData<&'a ()>, &'a MetaRocq_PCUIC_PCUICAst_term<'a>, &'a MetaRocq_PCUIC_PCUICAst_term<'a>),
  tConst(PhantomData<&'a ()>, MetaRocq_Common_Kernames_kername<'a>, MetaRocq_Common_Universes_Instance_t<'a>),
  tInd(PhantomData<&'a ()>, &'a MetaRocq_Common_Kernames_inductive<'a>, MetaRocq_Common_Universes_Instance_t<'a>),
  tConstruct(PhantomData<&'a ()>, &'a MetaRocq_Common_Kernames_inductive<'a>, &'a Corelib_Init_Datatypes_nat<'a>, MetaRocq_Common_Universes_Instance_t<'a>),
  tCase(PhantomData<&'a ()>, &'a MetaRocq_Common_BasicAst_case_info<'a>, &'a MetaRocq_PCUIC_PCUICAst_predicate<'a, &'a MetaRocq_PCUIC_PCUICAst_term<'a>>, &'a MetaRocq_PCUIC_PCUICAst_term<'a>, &'a Corelib_Init_Datatypes_list<'a, &'a MetaRocq_PCUIC_PCUICAst_branch<'a, &'a MetaRocq_PCUIC_PCUICAst_term<'a>>>),
  tProj(PhantomData<&'a ()>, &'a MetaRocq_Common_Kernames_projection<'a>, &'a MetaRocq_PCUIC_PCUICAst_term<'a>),
  tFix(PhantomData<&'a ()>, MetaRocq_Common_BasicAst_mfixpoint<'a, &'a MetaRocq_PCUIC_PCUICAst_term<'a>>, &'a Corelib_Init_Datatypes_nat<'a>),
  tCoFix(PhantomData<&'a ()>, MetaRocq_Common_BasicAst_mfixpoint<'a, &'a MetaRocq_PCUIC_PCUICAst_term<'a>>, &'a Corelib_Init_Datatypes_nat<'a>),
  tPrim(PhantomData<&'a ()>, MetaRocq_PCUIC_utils_PCUICPrimitive_prim_val<'a, &'a MetaRocq_PCUIC_PCUICAst_term<'a>>)
}

struct Program {
  __alloc: bumpalo::Bump,
}

impl<'a> Program {
fn new() -> Self {
  Program {
    __alloc: bumpalo::Bump::new(),
  }
}

fn alloc<T>(&'a self, t: T) -> &'a T {
  self.__alloc.alloc(t)
}

fn closure<TArg, TRet>(&'a self, F: impl Fn(TArg) -> TRet + 'a) -> &'a dyn Fn(TArg) -> TRet {
  self.__alloc.alloc(F)
}


fn MetaRocq_PCUIC_PCUICAst_isApp(&'a self, t: &'a MetaRocq_PCUIC_PCUICAst_term<'a>) -> &'a Corelib_Init_Datatypes_bool<'a> {
  match t {
    &MetaRocq_PCUIC_PCUICAst_term::tRel(_, n) => {
      self.alloc(
        Corelib_Init_Datatypes_bool::r#false(
          PhantomData))
    },
    &MetaRocq_PCUIC_PCUICAst_term::tVar(_, i) => {
      self.alloc(
        Corelib_Init_Datatypes_bool::r#false(
          PhantomData))
    },
    &MetaRocq_PCUIC_PCUICAst_term::tEvar(_, n, l) => {
      self.alloc(
        Corelib_Init_Datatypes_bool::r#false(
          PhantomData))
    },
    &MetaRocq_PCUIC_PCUICAst_term::tSort(_, u) => {
      self.alloc(
        Corelib_Init_Datatypes_bool::r#false(
          PhantomData))
    },
    &MetaRocq_PCUIC_PCUICAst_term::tProd(_, na, A, B) => {
      self.alloc(
        Corelib_Init_Datatypes_bool::r#false(
          PhantomData))
    },
    &MetaRocq_PCUIC_PCUICAst_term::tLambda(_, na, A, t0) => {
      self.alloc(
        Corelib_Init_Datatypes_bool::r#false(
          PhantomData))
    },
    &MetaRocq_PCUIC_PCUICAst_term::tLetIn(_, na, b, B, t0) => {
      self.alloc(
        Corelib_Init_Datatypes_bool::r#false(
          PhantomData))
    },
    &MetaRocq_PCUIC_PCUICAst_term::tApp(_, u, v) => {
      self.alloc(
        Corelib_Init_Datatypes_bool::r#true(
          PhantomData))
    },
    &MetaRocq_PCUIC_PCUICAst_term::tConst(_, k, ui) => {
      self.alloc(
        Corelib_Init_Datatypes_bool::r#false(
          PhantomData))
    },
    &MetaRocq_PCUIC_PCUICAst_term::tInd(_, ind, ui) => {
      self.alloc(
        Corelib_Init_Datatypes_bool::r#false(
          PhantomData))
    },
    &MetaRocq_PCUIC_PCUICAst_term::tConstruct(_, ind, n, ui) => {
      self.alloc(
        Corelib_Init_Datatypes_bool::r#false(
          PhantomData))
    },
    &MetaRocq_PCUIC_PCUICAst_term::tCase(_, indn, p, c, brs) => {
      self.alloc(
        Corelib_Init_Datatypes_bool::r#false(
          PhantomData))
    },
    &MetaRocq_PCUIC_PCUICAst_term::tProj(_, p, c) => {
      self.alloc(
        Corelib_Init_Datatypes_bool::r#false(
          PhantomData))
    },
    &MetaRocq_PCUIC_PCUICAst_term::tFix(_, mfix, idx) => {
      self.alloc(
        Corelib_Init_Datatypes_bool::r#false(
          PhantomData))
    },
    &MetaRocq_PCUIC_PCUICAst_term::tCoFix(_, mfix, idx) => {
      self.alloc(
        Corelib_Init_Datatypes_bool::r#false(
          PhantomData))
    },
    &MetaRocq_PCUIC_PCUICAst_term::tPrim(_, prim) => {
      self.alloc(
        Corelib_Init_Datatypes_bool::r#false(
          PhantomData))
    },
  }
}
fn MetaRocq_PCUIC_PCUICAst_isApp__curried(&'a self) -> &'a dyn Fn(&'a MetaRocq_PCUIC_PCUICAst_term<'a>) -> &'a Corelib_Init_Datatypes_bool<'a> {
  self.closure(move |t| {
    self.MetaRocq_PCUIC_PCUICAst_isApp(
      t)
  })
}
}
