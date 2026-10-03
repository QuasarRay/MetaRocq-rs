-- Run once as a supervisor, never with an agent's database credentials.
BEGIN;
CREATE SCHEMA aegis;
REVOKE ALL ON SCHEMA aegis FROM PUBLIC;
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'aegis_event_writer') THEN
    CREATE ROLE aegis_event_writer NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE
      NOREPLICATION NOBYPASSRLS;
  END IF;
END $$;
CREATE TABLE aegis.tasks (
  task text PRIMARY KEY CHECK (task ~ '^[a-z][a-z0-9-]{0,95}$'),
  principal name UNIQUE NOT NULL,
  description text NOT NULL
);
CREATE TABLE aegis.events (
  task text NOT NULL REFERENCES aegis.tasks(task),
  seq bigint NOT NULL,
  event_id uuid NOT NULL UNIQUE,
  actor name NOT NULL,
  event_text text NOT NULL CHECK (jsonb_typeof(event_text::jsonb) = 'object'),
  event jsonb GENERATED ALWAYS AS (event_text::jsonb) STORED,
  previous text NOT NULL,
  digest text NOT NULL,
  PRIMARY KEY (task, seq)
);
CREATE INDEX events_kind ON aegis.events ((event->>'kind'));
CREATE INDEX events_search ON aegis.events USING gin (event jsonb_path_ops);
CREATE FUNCTION aegis.chain_event() RETURNS trigger LANGUAGE plpgsql
SET search_path = pg_catalog, aegis AS $$
BEGIN
  PERFORM pg_advisory_xact_lock(hashtextextended(NEW.task, 7351));
  SELECT seq+1, digest INTO NEW.seq, NEW.previous FROM aegis.events
    WHERE task=NEW.task ORDER BY seq DESC LIMIT 1;
  NEW.seq := coalesce(NEW.seq, 1);
  NEW.previous := coalesce(NEW.previous, repeat('0', 64));
  NEW.actor := session_user;
  NEW.digest := encode(sha256(convert_to(NEW.task || chr(10) || NEW.seq::text ||
    chr(10) || NEW.event_id::text || chr(10) || NEW.actor::text || chr(10) ||
    NEW.previous || chr(10) || NEW.event_text, 'UTF8')), 'hex');
  RETURN NEW;
END $$;
CREATE TRIGGER chain BEFORE INSERT ON aegis.events
  FOR EACH ROW EXECUTE FUNCTION aegis.chain_event();
CREATE FUNCTION aegis.deny_change() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION 'append-only table: % is forbidden', TG_OP; END $$;
CREATE TRIGGER immutable_events BEFORE UPDATE OR DELETE OR TRUNCATE ON aegis.events
  FOR EACH STATEMENT EXECUTE FUNCTION aegis.deny_change();
CREATE TRIGGER immutable_tasks BEFORE UPDATE OR DELETE OR TRUNCATE ON aegis.tasks
  FOR EACH STATEMENT EXECUTE FUNCTION aegis.deny_change();
ALTER TABLE aegis.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE aegis.events FORCE ROW LEVEL SECURITY;
CREATE POLICY read_all ON aegis.events FOR SELECT USING (true);
CREATE POLICY write_own ON aegis.events FOR INSERT WITH CHECK
  (EXISTS (SELECT FROM aegis.tasks t WHERE t.task=events.task AND t.principal=session_user));
GRANT USAGE ON SCHEMA aegis TO aegis_event_writer;
GRANT SELECT ON aegis.tasks, aegis.events TO aegis_event_writer;
GRANT INSERT (task, event_id, event_text) ON aegis.events TO aegis_event_writer;
-- No application role receives UPDATE, DELETE, TRUNCATE, CREATE or task provisioning.
-- Superusers/owners can change this schema: independent replicas remain necessary.
COMMIT;
