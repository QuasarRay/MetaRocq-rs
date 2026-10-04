# ADR 0012: Ruby metaprogramming for maximum behavior density with minimum agent context

## Decision

Aegis should optimize **effective semantic density**, not raw character count. A DSL that saves 100 lines but forces every future agent to learn a new execution model can increase token cost.

The default order is:

1. reuse GitLab/Rails-native declarative facilities;
2. generate repeated code/UI/API surfaces from one Aegis schema;
3. add an external Ruby DSL only when it replaces a recurring subsystem and its expansion is reviewable;
4. keep whole-language/transpiler experiments outside the required runtime.

## Preferred vocabulary

The pinned GitLab tree already uses Rails/ActiveSupport metaprogramming extensively, including `ActiveSupport::Concern`, `class_attribute`, delegation, Active Model/Record macros and Rails routing. It also already uses GitLab DeclarativePolicy, Grape, GraphQL-Ruby and ViewComponent. These are the lowest-token abstractions because Astra does not need to learn another architecture to interpret them.

For Aegis specifically:

- **authorization/RBAC:** use GitLab DeclarativePolicy and existing GitLab abilities;
- **REST/API declarations:** use GitLab's Grape conventions when an API is needed;
- **GraphQL:** use the existing GraphQL-Ruby stack only where GitLab already expects GraphQL;
- **human supervision UI:** prefer GitLab ViewComponent/Pajamas + Rails presenters over ActiveAdmin/Administrate;
- **shared declarations:** prefer one machine-readable Aegis schema that generates Rails/MCP/UI indexes over parallel hand-written DSLs.

## External libraries

The machine-readable survey is in `research/ruby-metaprogramming/registry.json`.

High-compression external projects such as ActiveAdmin, Trailblazer and state-machine DSLs are mature, but they introduce substantial semantic vocabulary. They are therefore poor defaults for Aegis despite compact source.

The dry-rb schema/type family is the most plausible external exception. It becomes attractive only if a single schema actually replaces multiple independent declarations (for example MCP input, Rails validation, generated documentation and UI metadata). Adding dry-schema merely to shorten Ruby validation code is not enough.

Tapioca demonstrates an important principle: metaprogramming becomes easier to reason about when generated methods are materialized into a machine-readable interface. Aegis should copy that *principle* without adopting Sorbet/Tapioca solely for this project.

## Expansion contract

Every Aegis-specific macro/DSL that generates behavior must expose enough deterministic metadata to answer, without executing private agent reasoning:

- what methods/routes/policies/tools/components were generated;
- the input specification that generated them;
- the generator/version identity;
- the resulting source/artifact identity;
- authorization/proof boundaries affected;
- whether the output is runtime behavior, process evidence or formal evidence.

This allows Astra to inspect the small specification plus expansion index instead of repeatedly reconstructing macro behavior from Ruby metaprogramming internals.

## Astra review packet

`spec/astra-architecture-review.json` defines the bounded review surface. Astra should begin with seven semantic files and inspect implementation files only when an invariant or claim is disputed. This converts review from “understand the whole GitLab overlay” into “verify a small set of architecture claims, then sample implementation where needed.”

## Non-goals

- No new gem is added by this ADR.
- No formal proof gate is delegated to Ruby metaprogramming.
- No Aegis roadmap is duplicated into AASM/state_machines/Trailblazer.
- No second admin/dashboard framework is introduced inside GitLab.
