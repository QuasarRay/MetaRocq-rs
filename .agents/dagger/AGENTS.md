Project Goals:

1. Implement a dedicated customization of Aegis for implementing MetaRocq-rs, and verifying it using MetaRocq-rs itself and Original MetaRocq.

2. Create Supervision Infrastructure so for Human Engineers to be capable of independently verifying what untrusted AI Agents implemented. Optimize the Supervision infrastructure around MetaRocq-rs Project Goals.

3. Use metaprogramming to the fullest potential.

4. The original MetaRocq includes this pipeline for producing executables: MetaRocq => Erasure => LambdaBox => Peregrine => Extraction to Rust/CakeML. Aegis should contain a detailed Roadmap integrated into its pipeline That performs the following software development lifecycle:

    I. Generate a Detailed language agnostic machine readable roadmap for formalizing a Detailed Model of a Rust native implementation of MetaRocq-rs( That is aware of Rust's ownership model, type system, semantics and syntax and capable of reasoning about them directly ) in a machine readable language agnostic format that both original MetaRocq and MetaRocq-rs could independently verify to be correct. and break the roadmap down into smaller managable sub-tasks. provide facilities built into Aegis for executing formalization and implementation roadmaps and for executing bootstrapping pipeline.
    
    II. for each sub-task in the formalization and implementation roadmaps, Aegis should provide a dedicated, organized and structured and queriable persistent context and persistent chain of thoughts that is stored in the repository alongside Aegis's implementation but the folder structure fully decouples the code for databases, the content of databases, the Roadmap and the Agentic Pipelines. the database and its surrounding pipelines should be implemented with either PostgreSQL, or a database engine that is superior in its capabilitity to provide more complex queries and more complex database structure and architecture and more customizability. Optionally you could combine PostgreSQL with Event-Sourcing. pay attention that all the contexts and chains of thoughts of agents and subagents must be irreversibly written into the database, and the entire database contents must be pushed into the repository source code and treated like the code itself in this regard and NEVER a single database write should be missed or dropped or excluded from being pushed into the repository.
    
    III: for each sub-task in the formalization roadmap there should be a dedicated subagent with a separate context and separate chain of thoughts, that is authorized to read all the other persistent context databases and persistent chain of thoughts databases, but is only authorized to write to its own corresponding sub-task's persistent databases of context and chains of thought. every chain of thought and every reasoning internals, and every context from every agent's and every subagent's work must be permenantly and IRREVERSIBLY written into its own corresponding database, While the agent/subagent has its own dedicated pipeline for separately storing the more important details of their context and their chain of thoughts in the database in addition to full persistent database. apart from the two pipeline, the agent/subagent is given the freedom to separately write important parts of their context and their chain of thoughts to the database regardless of whether pipeline decides to include it or not, and they are free to do it at any stage of their workflow.
    
    IV: for the formalization roadmap and its subtasks there should be built in formal verification infrastructure integrated into agentic pipelines.
    
    V: After all sub-tasks in formalization roadmap were completed, the final result (the full formal specification of MetaRocq-rs) itself should be transformed into a machine readable language agnostic implementation roadmap, and the roadmap should be broken down into smaller subtasks. provide facilities built into Aegis for executing formalization and implementation roadmaps and for executing bootstrapping pipeline.
    
    VI: Implementation subtasks also follow the same policy of IRREVERSIBLE persistent database for context and chain of thoughts as the formalization subtasks.
    
    VII: Optimize the pipelines for agents and subagents around the Project Goals of MetaRocq-rs.
    
    VIII: Optimize for reducing token/credit consumption, reducing wasted/discarded work, and reducing work duplication.
    
    IX: Enforce Max thinking Effort throughout the project, prohibit agentic parallelism, enforce sequential agentic pipeline.
    
    X: Only GPT6-Astra is Authorized to implement/modify Formalization Roadmap, Execute Formalization subtasks, and implement/modify the implementation roadmap. other models are only authorized to execute the implementation roadmap's subtasks.
    
    XI: Roadmaps are subject to change and therefore must not be hard coded into agentic pipelines but read from the machine readable specification during execution runtime
    
    XII: Both Aegis and MetaRocq-rs may use a combination of GitLab Community Edition and Dagger as the kernel/engine/runner behind github actions workflows inside .github if the long term Token/Credit optimization benefits of the combo outweighs the short term cost.

5. prefer code reuse over implementing from scratch. Reuse Boilerplate from the source codes of Verus, Kani, QuasarRay/kontroli-rs, QuasarRay/lambars, QuasarRay/Candle-rs, VerusBelt, aeneas, charon, etc. to prevent tokens/credits from being wasted, and to accelerate development cycles. Optionally, you could reuse existing code from the projects listed in the attached MD files as long as it helps increase token/credit efficiency and reduce wasting/discarding/duplicating token/credit consumption. commit and push the md files to the repo of Aegis and MetaRocq-rs.

6. prefer machine generated code over direct implementation.

7. use strong ISO Architecture Description Records to reduce token/credit of AI agents from being wasted, and make it possible for a solo human engineer to efficiently supervise a project scope larger than what is normally done by solo developers.

8. this AGENTS.md file should exist at every directory in the project repository.

9. Reuse mathematical specifications from Original MetaRocq, while Rust implements those specifications. Also allow the scientific papers of MetaRocq ecosystem to guide you in the process of developing the Rust implementation. Treat the Original MetaRocq's mathematical specifications as shared contract between Original MetaRocq and MetaRocq-rs. Both projects should understand the exact same specification files exactly in the same way and the same manner. therefore, the specifications share syntax as well as semantics.

10. use Kani to prevent mistakes from happening from the first time, prevent repeating a mistake that has been made, and as a means of human supervision. Also prevent progress from being lost by making stackable pull requests incrementally. Turn my github account into your workspace.

11. MetaRocq-rs bootstrapping pipeline architecture:

    I: Bootstrapping_Original_MetaRocq() { Using the Existing Original MetaRocq binaries, Compile Original MetaRocq source code to LambdaBox(with additive changes to src code that results in proof erasure mechanism not erasing proof from LambdaBox executables) => Peregrine => CakeML => CakeML Machine Code }
    
    II: Bootstrapping_MetaRocq-rs_MetaTheory() { Bootstrapping_Original_MetaRocq() => formally Verify the Language Agnostic and Machine readable Formalization of MetaRocq-rs to match the Original MetaRocq MetaTheory }
    
    III: Bootstrapping_MetaRocq-rs_Implementation { Compile MetaRocq-rs using Rust compiler => use Rustc's MetaRocq-rs binary to generate LambdaBox executable of MetaRocq-rs (use transformation to ensure that erasure mechanism integrates the proof entirely e2e into lambdabox executable) => Peregrine => CakeML => formally proven e2e machine code of MetaRocq-rs => Verify that MetaRocq-rs lambdabox executable and source code statisfy the specifications of MetaRocq-rs MetaTheory, using both Original MetaRocq CakeML binary and MetaRocq-rs CakeML Binary }
    
    IV: Provide facilities built into Aegis for executing formalization and implementation roadmaps and for executing bootstrapping pipeline.

12. In the end the final Aegis project will be pushed to MetaRocq-rs repository while being renamed to .agents

The Original MetaRocq Github Repository: "https://github.com/MetaRocq/metarocq.git"

MetaRocq-rs Github Repository: "https://github.com/QuasarRay/MetaRocq-rs.git"

Target Project Repository: "https://github.com/QuasarRay/Aegis.git"

---

# Dagger integration specialization

- Dagger is the hermetic execution/orchestration layer for repeatable build and supervision checks; it is not a proof checker and cannot satisfy a mathematical proof gate by itself.
- Pin the Dagger CLI/SDK revision in `gitlab/runtime.lock.json`. Avoid floating container/tool versions in evidence-producing pipelines.
- Reuse the same Dagger entrypoints from GitLab CI and local development so CI logic is not duplicated across runners.
- Keep default checks cheap and deterministic. Large source-materialization or transpiler experiments must be explicit/manual unless their recurring benefit exceeds their compute and maintenance cost.
- Preserve the single-agent/sequential Aegis execution policy; Dagger may parallelize independent build mechanics only when that does not create parallel agent reasoning or conflicting writes.
