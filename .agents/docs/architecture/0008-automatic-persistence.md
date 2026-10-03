# ADR 0008: persist exposed execution records without model calls

Status: implemented controller boundary; full autonomous formalization remains open.
Stakeholders: solo supervisor, task workers, independent proof reviewers.
Concerns: lost work, silent missing exports, task isolation, model cost, false proof claims.

Use PostgreSQL for append-only task events, JSONB queries and indexed metadata. Each
task receives an independently provisioned login. RLS is bound to session_user; no
worker receives destructive privileges or task provisioning rights. Application
triggers reject UPDATE, DELETE and TRUNCATE. A global advisory lock serializes
managed workers. This is database enforcement, not a same-account OS sandbox.

The storage adapter synchronously fsyncs an outbox packet, inserts the event with
an idempotent UUID, verifies its hash chain and exports all logical application
tables. Failure leaves recoverable data and blocks progress. Direct database
writes are discovered by the next complete export. Event bytes are immutable in
the export. A generated manifest includes all rows, including failure records.

The process recorder forwards every stdout/stderr chunk into this adapter before
bounded terminal capture. Capture failures terminate the process. The controller
captures declared input contents, argv, prior artifacts and outcomes mechanically.
It generates a Markdown journal with no LLM summarization, prompts or API calls.
An explicit host event feed supports externally exposed messages and tool results.
It cannot intercept private reasoning or automatically observe a host without that
feed. Scripts cannot turn unavailable internal reasoning into an output file.

Publish all exports before/after a task. Non-forcing Git pushes and exact remote
head verification implement an advancement barrier. PostgreSQL and Git do not
share an atomic transaction; an outage blocks progress until recovery republishes.
Database administrators and Git administrators can defeat local retention rules.
Independent protected replicas remain necessary for stronger permanence.

Reuse the existing process recorder, atomic writes, path confinement and historical
proof/extraction infrastructure. Do not introduce lambars or unpythonic merely for
syntax compression: no required capability here depends on either, and neither is
assumed correct. GitLab/Dagger migration is deferred because it adds a deployment
boundary without demonstrated token savings for this sequential bootstrap.

Formal and roadmap workers require authenticated model/effort metadata from a
qualified provider adapter. That adapter and semantic proof replay are not yet
implemented. Their gates fail closed; a configured model name, success exit code,
source hash, retained AST or candidate checker's self-acceptance is not a proof.

Verification covers actual PostgreSQL RLS/immutability, crash/outbox recovery,
complete exports, global lock exclusion, capture failure, stale/interrupted tasks,
forged proof completions and non-forcing Git publication. This supports the tested
controller behaviors, not maximum efficiency or production readiness of the full
architecture. Bootstrapping_MetaRocq-rs_MetaTheory remains unfinished.
