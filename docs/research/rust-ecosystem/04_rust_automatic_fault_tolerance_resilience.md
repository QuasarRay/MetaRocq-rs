# 4 — Projects that take non-fault-tolerant Rust and produce fault-tolerant/resilient equivalents

## Executive finding

For the strict requirement—

> feed an arbitrary ordinary Rust application into a tool and receive a behaviorally equivalent application that automatically survives crashes, retries, partitions, duplicate messages, transient dependency failures, task failures, and restarts—

**no general source-to-source transformer exists.**

The Rust ecosystem instead has four mature/important approaches:

1. **durable-execution runtimes** — replay/recover workflows and state after process failure;
2. **actor supervision** — restart/isolate failed actors/tasks;
3. **resilience middleware** — retries, timeouts, circuit breakers, bulkheads, backoff;
4. **deterministic simulation testing** — systematically expose faults so humans can fix the program.

The closest literal code transformation is the new class of **attribute/procedural macros** that turn an async handler into a durable-execution handler. That still requires the programmer to obey the runtime's execution model; it does not infer fault tolerance from arbitrary code.

## Highest-value projects

| Project | Stars | Readiness | Orientation | Ambition | Spectrum | Exact fit | What it provides |
|---|---:|---|---|---:|---|---|---|
| [Restate](https://github.com/restatedev/restate) | **4,511** | Production | Engineering | 5/5 | C4/C5 | **Strong runtime, not transformer** | Durable execution, durable objects/services, retries, timers, reliable communication/state. |
| [Restate Rust SDK](https://github.com/restatedev/sdk-rust) | **88** | Production SDK | Engineering | 4/5 | C2/C4 | Partial | Rust-native service/workflow contract on top of Restate durability. |
| **Temporal Rust SDK** | current/GA in 2026 | Production | Engineering | 5/5 | C4 | **Strong runtime** | Durable workflows/activities with event-history replay and worker recovery. |
| [AWS Durable Execution SDK for Rust](https://github.com/aws/aws-durable-execution-sdk-rust) | **13** | Experimental preview | Engineering | 5/5 | C2/C4 | **Closest syntactic transform** | `#[durable_execution]`-style wrapping turns async Lambda handlers into durable executions; explicitly not yet production according to preview status. |
| [Bastion](https://github.com/bastion-rs/bastion) | **2,916** | Established / maintenance must be assessed | Engineering | 4/5 | C4 | Partial | Supervision trees and fault-tolerant actor runtime. |
| [Ractor](https://github.com/slawlor/ractor) | **2,116** | Production-capable core | Engineering | 4/5 | C4 | Partial | Erlang-inspired actors and supervision; distributed/cluster features have separate maturity caveats. |
| [Actix](https://github.com/actix/actix) | **9,251** | Production | Engineering | 4/5 | C4 | Partial | Mature actor framework with supervision patterns. |
| [BackON](https://github.com/Xuanwo/backon) | **1,059** | Production-capable | Engineering | 2/5 | C2 | Partial primitive | Retry/backoff abstraction. |
| [tower-resilience](https://github.com/joshrotenberg/tower-resilience) | **107** | Emerging/production-oriented | Engineering | 4/5 | C2/C4 | Partial | Tower middleware for retry/circuit breaker/bulkhead/etc. |
| [MadSim](https://github.com/madsim-rs/madsim) | **~1.1k** | Production-capable testing | Research/engineering | 5/5 | C5/test kernel | Adjacent | Deterministic distributed-system simulator + fault injection. Finds failures, does not repair code. |
| [Turmoil](https://github.com/tokio-rs/turmoil) | **~1.2k** | Production-capable testing | Engineering | 4/5 | C5/test kernel | Adjacent | Deterministic network/filesystem simulation with latency, drops, partitions, crashes, torn writes. |
| [Shuttle](https://github.com/awslabs/shuttle) | **~1.1k** | Production-capable testing | Research/engineering | 4/5 | C5/test kernel | Adjacent | Systematic/reproducible concurrency testing for Rust. |

## The core semantic problem

“Make it fault tolerant” is not a semantics-preserving local rewrite.

Suppose this code exists:

```rust
charge_card();
mark_order_paid();
send_email();
```

If the process dies after `charge_card()` but before `mark_order_paid()`, a retry may charge twice.

A transformer cannot safely fix this without knowing:

- whether charging is idempotent;
- whether the provider supports idempotency keys;
- transaction boundaries;
- compensating actions;
- durability guarantees of each dependency;
- whether email duplication matters;
- what “success” means to the application.

So fault tolerance is partly a **business contract**, not only a compiler property.

## Durable-execution runtimes

### Restate

Repositories:

- https://github.com/restatedev/restate
- https://github.com/restatedev/sdk-rust

Restate moves fault tolerance into a runtime/application model:

- durable handlers/services;
- reliable invocation;
- durable state;
- retries;
- durable timers;
- workflow-style execution;
- recovery after process failure.

This is close to the desired “application engine/kernel” end of the spectrum.

What must change:

- handlers execute through Restate's model;
- external side effects have to be placed behind durable/idempotent boundaries;
- state and communication semantics must conform to the runtime.

So it can make *adopted code* much more failure-resilient, but there is no safe universal pass:

```text
ordinary crate -> Restate crate
```

that can infer all boundaries automatically.

### Temporal Rust SDK

Temporal's Rust SDK reached GA in September 2026.

Core model:

```text
workflow source
   -> deterministic decisions
   -> event history
   -> replay after crash/restart

side effects
   -> activities
   -> retries/timeouts/idempotency policies
```

This is among the strongest production answers when the application can be expressed as workflows. It deliberately constrains programming style to make recovery deterministic.

Again: **runtime contract adoption**, not transparent source rewriting.

### AWS Durable Execution SDK for Rust

Repository:
https://github.com/aws/aws-durable-execution-sdk-rust

This project is especially relevant because the programming surface literally uses attribute/procedural-macro-style transformation around an async function.

Conceptually:

```rust
#[durable_execution]
async fn handler(...) { ... }
```

becomes a handler integrated with the durable-execution runtime.

This is the closest discovered example to “take ordinary-looking Rust and transform it into durable Rust.”

But:

- the SDK was presented as experimental/not-for-production in its preview documentation;
- only operations represented through the durable context get durable semantics;
- external side effects still need correct idempotency/compensation design;
- the macro does not prove arbitrary inner logic fault tolerant.

## Actor supervision

### Bastion

Repository: https://github.com/bastion-rs/bastion

Bastion explicitly targets fault-tolerant Rust applications using supervisor-like models inspired by Erlang/OTP.

Strength:

- isolates failure domains;
- supports restart/supervision strategies;
- encourages “let it fail, recover at the supervisor” architecture.

Limitation:

- restart does not automatically make external side effects safe;
- durable state/replay is distinct from actor restart;
- an existing arbitrary Tokio application must be architecturally adapted.

### Ractor

Repository: https://github.com/slawlor/ractor

Ractor provides an Erlang-influenced Rust actor model with supervision. It is a good base for structuring failures in concurrent services.

Its cluster/distributed features should be evaluated separately from its local actor core; “actor framework” and “production distributed fault-tolerance substrate” are not the same maturity claim.

### Actix

Repository: https://github.com/actix/actix

Actix is mature and widely used as an actor framework. Supervision can automatically restart actors in supported patterns. As with all actor systems, fault isolation is not equivalent to transactionally correct recovery of arbitrary external effects.

## Resilience middleware

### BackON

Repository: https://github.com/Xuanwo/backon

A focused retry/backoff library.

Good for:

- transient network failures;
- explicit retry policies;
- async/sync operation wrapping.

Not enough for:

- exactly-once semantics;
- durable workflow recovery;
- distributed transaction recovery;
- state-machine repair.

### tower-resilience

Repository: https://github.com/joshrotenberg/tower-resilience

Targets composable resilience policy in Tower-style services:

- retry;
- circuit breaking;
- bulkheading/concurrency isolation;
- timeout;
- related policy layers.

This is a strong **contract-implementer** layer: you can declaratively compose known resilience semantics around calls. It does not synthesize the correct policy automatically from application source.

### Tower itself

The broader Tower ecosystem supplies well-established middleware concepts such as timeout, buffering, load shedding, balancing, and retry. It is one of the best foundations for a code generator that wants to emit resilient service wrappers.

## Deterministic simulation: prevention through exhaustive failure discovery

These projects do **not** rewrite programs, but they are critical if an automatic transformer is to be trustworthy.

### MadSim

Repository: https://github.com/madsim-rs/madsim

MadSim provides a deterministic async/distributed simulation runtime that can:

- amplify random schedules;
- inject failures;
- reproduce failing seeds;
- run distributed systems rapidly under simulated time/network conditions.

It is valuable as the **oracle** after a proposed resilience rewrite.

### Turmoil

Repository: https://github.com/tokio-rs/turmoil

Turmoil simulates multiple hosts in one process and can inject:

- latency;
- dropped packets;
- partitions;
- crashes;
- torn filesystem writes.

The newer split crates (`turmoil-net`, `turmoil-fs`, etc.) make it more useful as a subsystem testing foundation.

### Shuttle

Repository: https://github.com/awslabs/shuttle

Shuttle systematically explores concurrent schedules. This catches:

- races;
- atomicity mistakes;
- deadlocks;
- rare ordering failures.

A future “fault-tolerance compiler” should run Shuttle-like schedule exploration after generated concurrency/retry changes.

## New/smaller durable-runtime experiments

The long tail matters because this area is active.

| Project | Stars/state | Role |
|---|---|---|
| [NOLA](https://github.com/richardartoul/nola) | **82**, early-stage | FoundationDB-backed virtual actors / HA stateful services. |
| [durust](https://github.com/danthegoodman1/durust) | **2**, experimental | Durable async workflow/replay ideas in Rust. |
| `durable-workflow/sdk-rust` | early | Rust SDK for durable workflow patterns. |
| `iopsystems/durable` | early | Crash/restart durable workflow experimentation. |
| `Databending/immortal` | early | Temporal-inspired durable-execution experiment. |
| `tokio-stage` | **1**, experimental | Self-healing/fault-tolerance abstractions around Tokio tasks. |
| `NineLives` | small/new | Tower-native composable “self-healing” policy patterns. |
| `Coerce` | active niche | Distributed actor framework with fault-tolerance ambitions. |

These are worth tracking for architecture ideas but should not be treated as equivalent to Temporal/Restate maturity.

## Why retry injection alone can make software *less* correct

An automatic rewrite like:

```text
call()
```

→

```text
retry(call)
```

can create:

- double payment;
- duplicate messages;
- repeated destructive mutations;
- thundering-herd overload;
- retry storms;
- violation of ordering;
- stale writes;
- amplified data corruption.

So automatic resilience synthesis needs an **effect taxonomy**:

```text
pure
read-only
idempotent mutation
conditionally idempotent mutation
non-idempotent external effect
compensatable effect
transactional effect
irreversible effect
```

Without that contract, “fault-tolerant rewrite” is unsafe.

## What a true fault-tolerance transformer would need

A plausible architecture is:

```text
Rust source + application contracts
          │
          ▼
effect + state-machine analysis
          │
          ├─ identify external effects
          ├─ infer/require idempotency contracts
          ├─ infer durable state boundaries
          ├─ derive retry/timeout policy
          ├─ derive compensation where specified
          └─ partition failure domains
          ▼
rewrite into durable runtime model
          │
          ├─ Restate / Temporal-style steps
          ├─ supervised tasks/actors
          ├─ Tower resilience wrappers
          └─ durable outbox/inbox/idempotency records
          ▼
verification
          ├─ model checking
          ├─ MadSim/Turmoil/Shuttle campaigns
          ├─ crash-at-every-boundary testing
          └─ invariant/property checks
```

The missing input is a **machine-readable failure semantics contract**. Source code alone usually does not say enough.

## Failure classes and strongest Rust ecosystems

| Failure class | Strongest current families |
|---|---|
| Process/worker crash during workflow | Temporal, Restate, AWS durable execution |
| Actor/task crash | Bastion, Ractor, Actix supervision |
| Transient RPC/service failure | Tower, tower-resilience, BackON |
| Network partition/drop/latency | MadSim/Turmoil for testing; durable runtimes for recovery |
| Concurrency scheduling bugs | Shuttle, loom-style testing |
| Duplicate delivery/retry | Durable runtimes + application idempotency contracts |
| Persistent state crash consistency | Database transaction model + durable runtime; simulation for testing |
| Byzantine faults | Separate consensus/BFT protocols; none of these automatically synthesize BFT semantics |
| Logic bugs | Not solved by fault-tolerance wrappers |

## Strongest answer by intended usage

### “I want minimal source changes and automatic runtime resilience”

Closest:
- attribute-macro durable execution systems;
- Tower middleware generation.

But these cover only specified boundaries.

### “I can move the application into a fault-tolerant execution model”

Strongest:
- **Restate**
- **Temporal Rust SDK**

### “I want Erlang-style supervision”

Strongest established Rust families:
- **Actix**
- **Ractor**
- **Bastion** (after checking maintenance/activity against your support horizon)

### “I want the transformer itself to prove it improved resilience”

No existing turnkey solution. The most credible research architecture combines:

- explicit effect/failure contracts;
- durable-runtime code generation;
- deterministic simulation;
- state-machine/model checking;
- differential invariants.

## Bottom line

Rust has mature **fault-tolerance engines**, good **resilience components**, and unusually strong **deterministic testing**.

What it lacks is a production system that automatically infers:

```text
what can be retried
what must be durable
what must be idempotent
what must be compensated
what failure boundaries are legal
```

from arbitrary Rust source.

Therefore the realistic automation target is not “Rust → fault-tolerant Rust from source alone.” It is:

```text
Rust + machine-readable effect/failure contracts
    -> generated durable-runtime adapters/state machines
    -> deterministic fault verification
```

That formulation connects directly to report 5: **contract-driven generation is the missing bridge.**

## Additional resilience, verification, and synthesis findings

The long report concentrates on durable runtimes, actors, middleware, and deterministic distributed simulation. The paired report adds the verification and failure-prevention half of the pipeline.

### Additional resilience-policy target: Nine Lives

**Nine Lives** is a newer/smaller resilience library whose algebraic policy composition is conceptually useful for generated code. It is less established than Tower/Restate/Temporal, but a compact algebra of retry/circuit-breaker/bulkhead/timeout/fork-join policies is close to the form a machine-readable failure contract could compile into.

### Explicit failpoints

**fail-rs** provides dynamic failure injection such as panic, return, sleep, and probabilistic triggers. It does not harden code, but it gives a transformer explicit failure sites and repeatable campaigns for validating generated recovery behavior.

### Loom

**Loom** explores concurrency interleavings under modeled synchronization primitives and complements Shuttle:

- Loom: systematic/exhaustive exploration within its bounded modeled world.
- Shuttle: randomized but reproducible schedule exploration that scales to larger real programs.

A generated concurrency rewrite should use the two for different validation regimes.

### Verification and failure-prevention tools

| Project | Capability | Role in an automatic hardener |
|---|---|---|
| **Kani** | Bit-precise Rust model checking, contracts, panic/overflow/UB checks | Proof/check gate and counterexample producer |
| **Verus** | SMT-backed verification for a Rust subset | Invariant/refinement proof layer |
| **Creusot** | Deductive verification via Why3 | Functional-correctness obligations |
| **Prusti** | Viper-based verification | Additional deductive-verification prior art |
| **MIRAI** | MIR abstract interpretation | Precondition/panic/taint-style static checks |
| **Miri** | Rust/MIR UB interpreter | Dynamic semantic/UB diagnostic |
| **cargo-fuzz** | libFuzzer integration | Counterexample generation |
| **Bolero / proptest** | Fuzz/property-based testing | Generated invariant/property campaigns |
| **Rudra and related unsafe analyzers** | Unsafe-Rust bug detection | Pre/post rewrite safety screening |

These tools mostly **detect or prove properties**; they do not automatically synthesize fault tolerance.

### Repair/transformation projects adjacent to resilience

- **Rust-lancet**: automatic ownership-rule repair; useful as evidence that compiler-guided Rust repair can be automated.
- **Concrat**: infers lock structure and synthesizes Rust lock APIs; a model for “infer a concurrency contract → synthesize a safer primitive.”
- **Crown / Laertes**: memory-safety transformations; better classified as fault prevention than availability.
- **Cpp2Rust**: safe translation plus ownership-runtime simplification; structurally useful for staged repair even though it is not a resilience transformer.

### Failure taxonomy for generated hardening

A future hardener should distinguish at least:

1. **Local panic/error avoidance** — `unwrap`, indexing, overflow, allocation assumptions.
2. **Transient dependency failures** — retry, backoff, jitter, timeout, reconnect, retry budget.
3. **Persistent dependency failures** — circuit breaker, fallback, degraded service, health routing/outlier ejection.
4. **Resource exhaustion** — bulkhead, rate/concurrency limits, load shedding, bounded queues.
5. **Tail latency** — hedging/racing, timeout, request coalescing.
6. **Concurrency faults** — races, deadlocks, cancellation safety, task/actor supervision.
7. **Distributed faults** — crash, partition, duplication/reordering, quorum/consensus semantics.
8. **State/data faults** — transactions, journaling/checkpointing, durable queues, compensation.

This taxonomy must be combined with the long report's effect taxonomy (`pure`, read-only, idempotent mutation, conditionally idempotent mutation, non-idempotent effect, compensatable effect, transactional effect, irreversible effect). Failure class alone is not enough to choose a safe rewrite.

### Contract-driven hardener

A synthesized pipeline can be expressed as:

```text
Rust + machine-readable failure/effect contract
    ↓
call/effect/state-machine analysis
    ↓
policy synthesis
    ↓
Restate/Temporal durable steps
+ Tower/tower-resilience/BackON/Nine-Lives policies
+ actor/task supervision
+ durable outbox/inbox/idempotency records
    ↓
proof obligations
    ↓
Kani / Verus / Creusot where applicable
+ Loom / Shuttle
+ MadSim / Turmoil
+ fail-rs
+ fuzz/property campaigns
```

Typical proof obligations include:

- retries never duplicate a non-idempotent side effect;
- deadline/budget constraints remain bounded;
- fallbacks are reachable under the declared fault model;
- durable state is committed before externally visible acknowledgement when required;
- generated supervision does not convert a safety failure into an infinite restart storm.

## Primary sources

- Restate — https://github.com/restatedev/restate
- Restate Rust SDK — https://github.com/restatedev/sdk-rust
- AWS Durable Execution SDK Rust — https://github.com/aws/aws-durable-execution-sdk-rust
- Bastion — https://github.com/bastion-rs/bastion
- Ractor — https://github.com/slawlor/ractor
- Actix — https://github.com/actix/actix
- BackON — https://github.com/Xuanwo/backon
- tower-resilience — https://github.com/joshrotenberg/tower-resilience
- MadSim — https://github.com/madsim-rs/madsim
- Turmoil — https://github.com/tokio-rs/turmoil
- Shuttle — https://github.com/awslabs/shuttle
- NOLA — https://github.com/richardartoul/nola
- durust — https://github.com/danthegoodman1/durust

### Additional primary sources retained from the paired report

- https://arxiv.org/abs/2301.10943
- https://doi.org/10.1145/3597503.3639103
- https://github.com/creusot-rs/creusot
- https://github.com/endorlabs/MIRAI
- https://github.com/flyingrobots/ninelives
- https://github.com/model-checking/kani
- https://github.com/tikv/fail-rs
- https://github.com/verus-lang/verus
- https://github.com/viperproject/prusti-dev
