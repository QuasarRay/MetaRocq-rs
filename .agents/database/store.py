"""Lossless exposed-event capture, durable outbox and complete logical Git export.

No model API is called here. Private model reasoning is not an input to this API.
PostgreSQL is authoritative; failed export/publication prevents advancement.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import threading
import uuid

import psycopg
from psycopg.rows import dict_row

from agentinfra.atomic import atomic_write_bytes, durable_unlink
from agentinfra.security import confined_path


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False, allow_nan=False)


def sha(data):
    return hashlib.sha256(data).hexdigest()


class Store:
    def __init__(self, dsn, root, task=None):
        self.root = Path(root).resolve(strict=True)
        self.task = task
        self.connection = psycopg.connect(dsn, autocommit=True, row_factory=dict_row)
        self.lock = threading.RLock()
        if task:
            row = self.connection.execute(
                'SELECT t.task FROM aegis.tasks t JOIN pg_roles r ON r.rolname=t.principal '
                'WHERE t.task=%s AND t.principal=session_user AND NOT r.rolsuper AND NOT r.rolbypassrls '
                'AND NOT r.rolcreaterole', (task,)).fetchone()
            if not row:
                self.close()
                raise ValueError('task requires its own unprivileged database login')

    def close(self):
        self.connection.close()

    def exclusive(self):
        # One global worker across connections and machines sharing this database.
        row = self.connection.execute("SELECT pg_try_advisory_lock(7351, 1) AS acquired").fetchone()
        if not row['acquired']:
            raise RuntimeError('another sequential worker is active')

    def release(self):
        self.connection.execute("SELECT pg_advisory_unlock(7351, 1)")

    def _write(self, relative, data, immutable=False):
        path = confined_path(self.root, relative)
        if path.exists():
            if path.read_bytes() == data:
                return
            if immutable:
                raise ValueError(f'event export changed: {relative}')
        atomic_write_bytes(path, data, root=self.root)

    def rows(self):
        return self.connection.execute(
            "SELECT task, seq, event_id::text, actor::text, event_text, previous, digest "
            "FROM aegis.events ORDER BY task, seq").fetchall()

    def export(self):
        with self.lock, self.connection.transaction():
            # The transaction's snapshot covers every logical application table.
            self.connection.execute('SET TRANSACTION ISOLATION LEVEL REPEATABLE READ, READ ONLY')
            tasks = self.connection.execute(
                'SELECT task, principal::text, description FROM aegis.tasks ORDER BY task').fetchall()
            rows = self.rows()
        files = {}
        heads = {}
        for row in rows:
            prior_seq, prior_hash = heads.get(row['task'], (0, '0' * 64))
            body = '\n'.join(str(row[k]) for k in ('task', 'seq', 'event_id', 'actor', 'previous', 'event_text'))
            if row['seq'] != prior_seq + 1 or row['previous'] != prior_hash or sha(body.encode()) != row['digest']:
                raise ValueError('database event chain is inconsistent')
            name = f"data/events/{row['task']}/{row['seq']:012d}.json"
            raw = (canonical(row) + '\n').encode()
            self._write(name, raw, immutable=True)
            files[name] = sha(raw)
            heads[row['task']] = (row['seq'], row['digest'])
        tracked = confined_path(self.root, 'data/events')
        existing = {p.relative_to(self.root).as_posix() for p in tracked.rglob('*.json')} if tracked.exists() else set()
        if existing - set(files):
            raise ValueError('export contains events absent from database; restore database before proceeding')
        task_bytes = (canonical(tasks) + '\n').encode()
        self._write('data/tasks.json', task_bytes)
        files['data/tasks.json'] = sha(task_bytes)
        manifest = {'schema': 1, 'events': len(rows), 'heads': heads, 'files': files,
                    'tables': ['aegis.tasks', 'aegis.events'], 'claim': 'logical content, not credentials or PostgreSQL system catalogs'}
        self._write('data/manifest.json', (canonical(manifest) + '\n').encode())
        # Mechanical Markdown rendering: no LLM, generated summaries or token spend.
        lines = ['# Automatic execution journal', '',
                 'Exposed events only. This journal is not private internal reasoning or proof evidence.', '',
                 '| Task | Sequence | Event | Outcome |', '| --- | ---: | --- | --- |']
        for row in rows:
            event = json.loads(row['event_text'])
            def cell(value):
                return str(value).replace('|', '\\|').replace('\n', ' ').replace('<', '&lt;')
            lines.append(f"| {cell(row['task'])} | {row['seq']} | {cell(event.get('kind', ''))} | {cell(event.get('outcome', ''))} |")
        self._write('data/journal.md', ('\n'.join(lines) + '\n').encode())
        return manifest

    def _insert(self, packet):
        row = self.connection.execute(
            'SELECT task, event_text FROM aegis.events WHERE event_id=%s', (packet['event_id'],)).fetchone()
        if row:
            if row != {'task': packet['task'], 'event_text': packet['event_text']}:
                raise ValueError('event identifier reused with different content')
        else:
            self.connection.execute('INSERT INTO aegis.events(task,event_id,event_text) VALUES (%s,%s,%s)',
                                    (packet['task'], packet['event_id'], packet['event_text']))

    def append(self, event, event_id=None):
        if not self.task:
            raise ValueError('capture requires a task-scoped database identity')
        if not isinstance(event, dict) or not isinstance(event.get('kind'), str):
            raise ValueError('event requires an object and kind')
        if event['kind'] in {'chain_of_thought', 'private_reasoning', 'analysis'}:
            raise ValueError('private internal reasoning is not an exposed event')
        packet = {'task': self.task, 'event_id': str(uuid.UUID(event_id)) if event_id else str(uuid.uuid4()),
                  'event_text': canonical(event)}
        name = f"data/pending/{self.task}/{packet['event_id']}.json"
        with self.lock:
            # Persist before DB I/O; failed DB writes survive for deterministic retry.
            self._write(name, (canonical(packet) + '\n').encode(), immutable=True)
            self._insert(packet)
            self.export()
            durable_unlink(confined_path(self.root, name), root=self.root)
        return packet['event_id']

    def recover(self):
        with self.lock:
            pending = confined_path(self.root, f'data/pending/{self.task}')
            for path in sorted(pending.glob('*.json')) if pending.exists() else []:
                packet = json.loads(path.read_text())
                if packet['task'] != self.task:
                    raise ValueError('outbox task mismatch')
                self._insert(packet)
                self.export()
                durable_unlink(path, root=self.root)
            return self.export()

    def events(self, task=None):
        return [json.loads(row['event_text']) for row in self.rows() if task is None or row['task'] == task]
