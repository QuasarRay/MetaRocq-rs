//! Narrow, unverified printer repair. Original Peregrine bytes stay immutable.
//! Uses Rust syntax trees; never rewrites program expressions with regexes.
#![forbid(unsafe_code)]
use quote::quote;
use syn::{parse_quote, punctuated::Punctuated, visit_mut::VisitMut, Item, Token};

struct Derives;
impl VisitMut for Derives {
    fn visit_attribute_mut(&mut self, attr: &mut syn::Attribute) {
            if attr.path().is_ident("derive") {
                if let Ok(paths) = attr.parse_args_with(Punctuated::<syn::Path, Token![,]>::parse_terminated) {
                    let kept: Vec<_> = paths.into_iter().filter(|p| !p.is_ident("Debug")).collect();
                    *attr = parse_quote!(#[derive(#(#kept),*)]);
                }
            }
    }
}

pub fn normalize(source: &str) -> Result<String, syn::Error> {
    let mut file = syn::parse_file(source)?;
    // The enclosing generated module supplies the upstream lint allowances.
    file.attrs.clear();
    Derives.visit_file_mut(&mut file);
    let mut aliases = false;
    for item in &mut file.items {
        match item {
            Item::Type(alias) => {
                let params: Vec<_> = alias.generics.type_params().map(|p| p.ident.clone()).collect();
                if !params.is_empty() {
                    // Associated-type identity uses otherwise erased generic
                    // parameters without introducing a value or changing RHS.
                    let rhs = &alias.ty;
                    alias.ty = Box::new(syn::parse2(quote!(
                        <std::marker::PhantomData<(#(#params,)*)> as __MetaRocqKeep>::Value<#rhs>
                    ))?);
                    aliases = true;
                }
                alias.vis = parse_quote!(pub);
            }
            Item::Struct(s) if s.ident == "Program" => s.vis = parse_quote!(pub),
            Item::Impl(i) if i.trait_.is_none() && matches!(i.self_ty.as_ref(), syn::Type::Path(p) if p.path.is_ident("Program")) => {
                for member in &mut i.items {
                    if let syn::ImplItem::Fn(f) = member {
                        f.vis = parse_quote!(pub);
                    }
                }
            }
            _ => {}
        }
    }
    if aliases {
        // Reserve the helper name; do not silently shadow an upstream item.
        if source.contains("__MetaRocqKeep") {
            return Err(syn::Error::new_spanned(&file, "normalizer helper name collision"));
        }
        file.items.push(parse_quote!(pub trait __MetaRocqKeep { type Value<T: ?Sized>: ?Sized; }));
        file.items.push(parse_quote!(impl<T: ?Sized> __MetaRocqKeep for std::marker::PhantomData<T> {
            type Value<U: ?Sized> = U;
        }));
    }
    Ok(prettyplease::unparse(&file))
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn program_expressions_survive_normalization() {
        let src = "impl<'a> Program { fn probe(&'a self, n: u8) -> bool { match n { 7 => true, _ => false } } }";
        // Canonicalize optional trailing punctuation before AST equality.
        let original = syn::parse_file(&prettyplease::unparse(&syn::parse_file(src).unwrap())).unwrap();
        let transformed = syn::parse_file(&normalize(src).unwrap()).unwrap();
        let body = |f: syn::File| match f.items.into_iter().next().unwrap() {
            Item::Impl(i) => match i.items.into_iter().next().unwrap() {
                syn::ImplItem::Fn(f) => f.block, _ => panic!()
            }, _ => panic!()
        };
        assert_eq!(body(original), body(transformed));
    }
    #[test]
    fn malformed_input_is_rejected() { assert!(normalize("fn broken(").is_err()); }
    #[test]
    fn reserved_name_is_rejected() {
        assert!(normalize("type A<T> = (); struct __MetaRocqKeep;").is_err());
    }
}
