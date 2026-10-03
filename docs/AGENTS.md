Project Goals:

1. Reimplement MetaRocq in Rust and formally verify its source code Rust implementation to behave identically to the intended specification.

2. Create Supervision Infrastructure so for Human Engineers to be capable of independently verify what untrusted AI Agents implemented.

3. Use metaprogramming to the fullest potential.

4. MetaRocq provides an automated path of extracting to Rust via Peregrine. Use that pipeline to extract MetaRocq's source code to Rust. Afterwards, formally prove the Rust implementation to match MetaRocq's MetaTheory and specifications/Contract in HOL4 using Z3_tac So that Z3 automatically generates proofs that HOL4 can independently verify. The goal of the project is to provide reusable metaprogramming capabilities that also create machine generated proofs that the metaprogram produces code according to its specifications, meaning that it is automatically proven that macro expansion is correct. it should also make writing specification easier for software engineers so that the metaprogramming/metaverification system can be used to generate a proof that itself generates more proofs, for example if we have a high level contract already specified, the metaprogram that generates implementation for the declarative contract should automatically generate proofs for the implementation as well. The Metaprogramming infra should ultimately become Rust native, and capable of generating proof carrying expanded macros "under the hood". MetaRocq-rs should be capable of machine checking the proofs that its own macro expansion utilities generate. Use MetaRocq's own metaprogramming capabilities and any reusable code from any project that can automate more and result in more metaprogramming oriented software development paradigm, to transform MetaRocq itself into becoming Idiomatic Rust, and natively aware of Rust syntax and semantics, including Ownership and Rust's Type System.

5. prefer code reuse over implementing from scratch. Reuse Boilerplate from the source codes of Verus, Kani, QuasarRay/kontroli-rs, QuasarRay/lambars, QuasarRay/Candle-rs, VerusBelt, aeneas, charon, etc. to prevent tokens/credits from being wasted, and to accelerate development cycles.

6. prefer machine generated code over direct implementation.

7. use strong ISO Architecture Description Records to reduce token/credit of AI agents from being wasted, and make it possible for a solo human engineer to efficiently supervise a project scope larger than what is normally done by solo developers.

8. this AGENTS.md file should exist at every directory in the project repository.

9. Reuse mathematical specifications from Original MetaRocq, while Rust implements those specifications. Also allow the scientific papers of MetaRocq ecosystem to guide you in the process of developing the Rust implementation. Treat the Original MetaRocq's mathematical specifications as shared contract between Original MetaRocq and MetaRocq-rs. Both projects should understand the exact same specification files exactly in the same way and the same manner. therefore, the specifications share syntax as well as semantics.

10. use Kani to prevent mistakes from happening from the first time, prevent repeating a mistake that has been made, and as a means of human supervision. Also prevent progress from being lost by making stackable pull requests incrementally. Turn my github account into your workspace.

11. after the initial bootstrapping of MetaRocq in Rust, and verifying the Rust implementation to be correct using Z3_tac + HOL4, prove the machine code correct as well using Z3_tac + HOL4.

12. The project Aegis contains mechanisms for formal verification including HOL4 MCP and policies for reducing token/credit consumption(the policy that prevents wrong implementation from happening before hand rather than change and discard must enforce it strongly enough to prevent wasting tokens/credits. make sure that the mechanism is effective for that), some of them are still in the pull requests, and partially complete, different branches have different capabilities. Adapt Aegis source code to match the requirements of This project based on This AGENTS.MD file, and work inside the finished Aegis: https://github.com/QuasarRay/Aegis
Some progress in Aegis has been made in https://github.com/QuasarRay/kontroli-rs, reuse if it is more efficient than from scratch implementation

The Original MetaRocq Github Repository: "https://github.com/MetaRocq/metarocq.git"

Target Project Repository: "https://github.com/QuasarRay/MetaRocq-rs.git"