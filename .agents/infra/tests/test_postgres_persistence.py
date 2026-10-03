"""Real PostgreSQL qualification; CI supplies a dedicated, disposable database."""
import base64
import json
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path[:0] = [str(ROOT), str(ROOT / 'infra')]
import psycopg
from psycopg import sql
from psycopg.conninfo import make_conninfo
from database.store import Store


@unittest.skipUnless(os.environ.get('AEGIS_TEST_ADMIN_DSN'), 'real PostgreSQL DSN required')
class PostgresTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.admin_dsn = os.environ['AEGIS_TEST_ADMIN_DSN']
        cls.admin = psycopg.connect(cls.admin_dsn, autocommit=True)
        # A dedicated test database only; never accepts a production task DSN.
        name = cls.admin.execute('SELECT current_database()').fetchone()[0]
        if not name.startswith('aegis_test_'):
            raise ValueError('tests require an aegis_test_* disposable database')
        cls.admin.execute((ROOT / 'database/schema.sql').read_text())
        cls.roles = ('aegis_test_worker_a', 'aegis_test_worker_b')
        for role, task in zip(cls.roles, ('task-a', 'task-b')):
            if not cls.admin.execute('SELECT 1 FROM pg_roles WHERE rolname=%s', (role,)).fetchone():
                cls.admin.execute(sql.SQL('CREATE ROLE {} LOGIN NOSUPERUSER NOCREATEROLE NOBYPASSRLS PASSWORD {}').format(sql.Identifier(role), sql.Literal('fixture-only')))
            cls.admin.execute(sql.SQL('GRANT aegis_event_writer TO {}').format(sql.Identifier(role)))
            cls.admin.execute('INSERT INTO aegis.tasks VALUES (%s,%s,%s)', (task, role, 'isolated test task'))
        cls.tmp = tempfile.TemporaryDirectory()
        cls.root = Path(cls.tmp.name)

    @classmethod
    def tearDownClass(cls):
        cls.admin.execute('DROP SCHEMA aegis CASCADE')
        cls.admin.close()
        cls.tmp.cleanup()

    def store(self, task='task-a'):
        user = self.roles[0 if task == 'task-a' else 1]
        store = Store(make_conninfo(self.admin_dsn, user=user, password='fixture-only'), self.root, task)
        self.addCleanup(store.close)
        return store

    def test_01_append_only_and_cross_task_permissions(self):
        a, b = self.store(), self.store('task-b')
        a.append({'kind': 'context', 'message': 'public execution context'})
        self.assertEqual(b.events()[0]['message'], 'public execution context')
        with self.assertRaises(psycopg.Error):
            a.connection.execute("INSERT INTO aegis.events(task,event_id,event_text) VALUES ('task-b',gen_random_uuid(),'{\"kind\":\"forged\"}')")
        for statement in ('DELETE FROM aegis.events', 'UPDATE aegis.events SET event_text=event_text',
                          'TRUNCATE aegis.events', "UPDATE aegis.tasks SET description='changed'", 'DELETE FROM aegis.tasks'):
            with self.subTest(sql=statement), self.assertRaises(psycopg.Error):
                a.connection.execute(statement)
        with self.assertRaises(ValueError):
            Store(make_conninfo(self.admin_dsn, user=self.roles[0], password='fixture-only'), self.root, 'task-b')

    def test_02_crash_after_commit_recovers_without_duplicate(self):
        store = self.store()
        count = len(store.rows())
        with patch.object(store, 'export', side_effect=OSError('simulated export failure')):
            with self.assertRaises(OSError):
                store.append({'kind': 'decision', 'message': 'committed before export failed'})
        self.assertEqual(len(store.rows()), count + 1)
        self.assertTrue(list((self.root / 'data/pending/task-a').glob('*.json')))
        store.recover()
        self.assertEqual(len(store.rows()), count + 1)
        self.assertFalse(list((self.root / 'data/pending/task-a').glob('*.json')))

    def test_03_failed_insert_retains_outbox(self):
        store = self.store()
        count = len(store.rows())
        with patch.object(store, '_insert', side_effect=OSError('simulated disconnected database')):
            with self.assertRaises(OSError):
                store.append({'kind': 'tool_result', 'result': 'read bytes survive failed database write'})
        self.assertEqual(len(store.rows()), count)
        store.recover()
        self.assertEqual(len(store.rows()), count + 1)

    def test_04_global_worker_lock(self):
        a, b = self.store(), self.store('task-b')
        a.exclusive()
        with self.assertRaises(RuntimeError):
            b.exclusive()
        a.release()
        b.exclusive()
        b.release()

    def test_05_export_covers_direct_database_writes_and_journal(self):
        store = self.store()
        store.connection.execute("INSERT INTO aegis.events(task,event_id,event_text) VALUES ('task-a',gen_random_uuid(),'{\"kind\":\"direct-write\"}')")
        manifest = store.export()
        self.assertEqual(manifest['events'], len(store.rows()))
        self.assertIn('direct-write', (self.root / 'data/journal.md').read_text())
        self.assertEqual(len(manifest['files']), len(store.rows()) + 1)

    def test_06_tampered_export_is_not_overwritten(self):
        store = self.store()
        path = next((self.root / 'data/events').rglob('*.json'))
        original = path.read_bytes()
        path.write_text('tampered')
        try:
            with self.assertRaises(ValueError):
                store.export()
        finally:
            path.write_bytes(original)

    def test_07_private_channel_is_rejected(self):
        with self.assertRaises(ValueError):
            self.store().append({'kind': 'private_reasoning', 'text': 'not available'})

    def test_08_exact_logical_database_restore(self):
        from database.admin import restore
        import uuid
        store = self.store()
        original = store.export()
        db = 'aegis_test_restore_' + uuid.uuid4().hex[:12]
        self.admin.execute(sql.SQL('CREATE DATABASE {}').format(sql.Identifier(db)))
        try:
            dsn = make_conninfo(self.admin_dsn, dbname=db)
            with psycopg.connect(dsn, autocommit=True) as connection:
                connection.execute((ROOT / 'database/schema.sql').read_text())
                restore(connection, self.root)
            with tempfile.TemporaryDirectory() as folder:
                replica = Store(dsn, Path(folder))
                try:
                    self.assertEqual(replica.export(), original)
                finally:
                    replica.close()
        finally:
            self.admin.execute(sql.SQL('DROP DATABASE {}').format(sql.Identifier(db)))
