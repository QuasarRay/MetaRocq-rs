# Human Readable Implications for MetaRocq-rs

## 1. Do Not Build MetaRocq-rs Around the Wrong Conclusion

The research does **not** support this architectural assumption:

> We should preserve PCUIC because PCUIC is inherently the best calculus for certified metaprogramming.

The research supports this stronger and more useful assumption:

> We should preserve PCUIC-compatible semantics because PCUIC is the authoritative Rocq-native semantic contract, while separately preserving and improving the reflective metaprogramming, verified transformation, proof-certificate, and independent-checking architecture around it.

This distinction directly affects what should be reimplemented in Rust and what should be treated as a specification/oracle.

## 2. Architecture That Should Be Preserved

MetaRocq-rs should preserve the following separation:

```text
[Rust-Native Reflection / AST / Environment Interface]
                    |
                    v
[Shared PCUIC-Compatible Semantic Contract]
                    |
                    v
[MetaTheory / Structural Theorems]
                    |
                    v
[Verified Checker / Retyping / Conversion]
                    |
                    v
[Transformation Framework]
                    |
                    v
[Proof / Certificate Generation]
                    |
                    v
[Independent Checker(s)]
                    |
                    v
[Verified / Independently Audited Compilation Boundary]
```

The project should not collapse these layers into one monolithic "MetaTheory" implementation.

## 3. What PCUIC Should Be in MetaRocq-rs

PCUIC should be treated as:

1. The shared mathematical contract with Original MetaRocq.
2. The source of truth for Rocq-level typing and semantic obligations.
3. The specification against which the Rust-native checker and transformations are refined.
4. One of the independent interfaces through which Original MetaRocq can audit MetaRocq-rs.

PCUIC should **not** be treated as the entire metaprogramming architecture.

## 4. What Should Be Made Rust-Native

The Rust implementation should aggressively make the following facilities native and reusable:

1. Reflected syntax and declaration representations.
2. A typed environment/query/update interface analogous to the Template Monad.
3. A generic transformation contract:

```text
Input well-formedness
+
Transformation
+
Generated certificate / proof object
+
Preservation theorem schema
```

4. A reusable certificate checking interface.
5. Macro-expansion correctness infrastructure so metaprograms that generate Rust code can also generate machine-checkable evidence connecting expansion to specification.
6. A clean separation between untrusted generators and trusted/verified checkers.

## 5. How HOL4 Should Be Used

The HOL/CakeML evidence suggests that HOL4 should not be viewed as a weaker fallback that is only needed because MetaRocq-rs is incomplete.

HOL4 can provide an intentionally independent verification axis:

- independently encode/check critical semantic obligations;
- verify generated certificates;
- leverage CakeML-style proof-producing synthesis patterns;
- provide a path toward machine-code-level assurance where appropriate.

This gives stronger defense against correlated bugs than only rechecking a Rust implementation against another implementation of the same PCUIC machinery.

## 6. How Lambda-Pi Modulo Should Be Used

Lambdapi/Dedukti should be considered primarily as an interoperability and proof-transport layer:

- transport HOL/OpenTheory results;
- represent/check cross-system certificates;
- connect logic-specific proof objects through a smaller common framework;
- serve as an independently implemented checking path where this reduces correlated trust.

This is complementary to PCUIC rather than a replacement for PCUIC.

## 7. The Best Combined Architecture

For this project's goals, the strongest architecture is not "choose one calculus".

It is:

```text
PCUIC
    = Rocq-native semantic fidelity and authoritative contract

HOL4 / CakeML
    = independent theorem-proving and verified-executable assurance axis

Lambda-Pi Modulo / Dedukti / Lambdapi
    = proof interoperability and translation/checking axis

Rust / Verus / Kani / Aeneas / Charon
    = implementation semantics, refinement, and executable safety axis
```

The systems should cross-check each other wherever practical instead of competing to become the only root of trust.

## 8. Relationship to Existing MetaRocq-rs Progress

The existing experimental HOL4 -> OpenTheory -> Dedukti/Lambdapi -> Rocq/PCUIC bridge is directionally consistent with this research conclusion.

This report intentionally does not modify that experimental branch and does not duplicate its implementation work.

The report stack is based separately from `main` so that the open formalization/runtime work remains untouched.

## 9. Correct Project-Level Claim Going Forward

A defensible project statement would be:

> MetaRocq's unusual strength for certified metaprogramming comes from an integrated architecture in which Rocq syntax is reflectable, PCUIC supplies a formally connected semantic contract and MetaTheory, and verified or proof-producing algorithms can be independently checked and extracted. MetaRocq-rs should preserve this architecture while adding independent HOL4 and Lambda-Pi-modulo verification paths rather than assuming PCUIC is intrinsically superior to every alternative calculus.
