# Automatic persistence

Install `database/requirements.txt`. A trusted supervisor applies `schema.sql` to
a fresh PostgreSQL database, provisions one LOGIN role per roadmap task, grants
`aegis_event_writer` to it, and inserts its task/principal/description in
`aegis.tasks`. Workers must not be superusers, schema owners, role administrators,
or holders of BYPASSRLS. Database credentials stay outside Git and child processes.

`database/store.py` writes a durable local outbox before committing each exposed
event to PostgreSQL. Every committed event is exported automatically to
`data/events/<task>/<sequence>.json`. A failed DB write remains in the outbox;
a failed export is reconstructed from PostgreSQL. Retrying the same event UUID
is idempotent and rejects changed content. A complete snapshot of both application
tables and their chain heads is recorded in `data/manifest.json` and `data/tasks.json`.
These are the entire logical database contents; server catalogs, WAL files and
credentials are not project data. Schema and indexes are reproducible from SQL.

Supervisor commands use a separate `AEGIS_ADMIN_DSN` and never run inside worker
processes. `database/admin.py init` creates the schema; `register --task TASK
--principal ROLE --description TEXT` provisions a restricted login (configure its
authentication separately). `restore SNAPSHOT_ROOT` verifies every exported hash,
event chain and watermark and restores into an empty initialized application database.
It retains historical actors and event UUIDs; it does not manufacture new events.

PostgreSQL row security uses authenticated `session_user`, not a caller-supplied
task setting. All workers can query all event contents; INSERT is restricted to
their own task. UPDATE, DELETE, TRUNCATE and schema changes are not granted.
Triggers also reject destructive table operations. An administrator can change
permissions/triggers or erase Git, so independent backups and protected remote
branches are still needed for stronger durability. These controls do not claim
an OS sandbox against agents sharing the supervisor's account or credentials.

Example queries (using an authorized read-only or task connection):

```sql
SELECT task, seq, event->>'kind' AS kind FROM aegis.events ORDER BY task, seq;
SELECT task, event FROM aegis.events WHERE event @> '{"kind":"task_finished"}';
SELECT task, event FROM aegis.events WHERE event @> '{"kind":"decision"}';
```

`data/journal.md` is rendered mechanically from metadata. Full exposed input files
and stdout/stderr bytes are recorded as base64; bounded terminal display does not
truncate the event stream. Persistence makes no model calls, requests no logging
prompts and performs no model summarization. Its additional model-token cost is
zero; database, disk, network and any later reading of context still have costs.
Private internal reasoning is inaccessible and is not requested or fabricated.

The host can provide a public-event JSONL export to `capture-host`; accepted channels
are user, assistant_final, assistant_commentary, tool, action and context. Events
must be supplied by the host adapter: this code cannot intercept an unrelated ChatGPT
session. Do not put credentials or private reasoning into this public repository feed.
Exposed explicit decisions may be logged as ordinary events without extra prompts.
