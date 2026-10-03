#!/usr/bin/env python3
"""Supervisor-only provisioning and verified logical restore; never a worker tool."""
import argparse
import json
import os
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT), str(ROOT / 'infra')]
import psycopg
from psycopg import sql
from database.store import Store, sha
from agentinfra.security import confined_path


def register(connection, task, principal, description):
    if not re.fullmatch('[a-z][a-z0-9-]{0,95}', task) or not re.fullmatch('[a-z][a-z0-9_]{0,62}', principal):
        raise ValueError('invalid task or database principal')
    with connection.transaction():
        role = connection.execute('SELECT rolsuper,rolcreaterole,rolbypassrls FROM pg_roles WHERE rolname=%s', (principal,)).fetchone()
        if role and any(role):
            raise ValueError('worker principal has administrative privileges')
        if not role:
            connection.execute(sql.SQL('CREATE ROLE {} LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS').format(sql.Identifier(principal)))
        connection.execute(sql.SQL('GRANT aegis_event_writer TO {}').format(sql.Identifier(principal)))
        connection.execute('INSERT INTO aegis.tasks(task,principal,description) VALUES (%s,%s,%s)', (task, principal, description))


def restore(connection, snapshot):
    snapshot = Path(snapshot).resolve(strict=True)
    manifest = json.loads((snapshot / 'data/manifest.json').read_text())
    if manifest.get('schema') != 1 or manifest.get('tables') != ['aegis.tasks', 'aegis.events']:
        raise ValueError('unsupported logical snapshot')
    if connection.execute('SELECT count(*) FROM aegis.tasks').fetchone()[0]:
        raise ValueError('restore requires an empty application database')
    events, tasks = [], None
    for name, digest in manifest['files'].items():
        path = confined_path(snapshot, name, must_exist=True)
        if sha(path.read_bytes()) != digest:
            raise ValueError('snapshot byte mismatch')
        if name == 'data/tasks.json':
            tasks = json.loads(path.read_text())
        elif name.startswith('data/events/') and name.endswith('.json'):
            events.append(json.loads(path.read_text()))
        else:
            raise ValueError('unexpected logical snapshot file')
    if tasks is None or len(events) != manifest['events']:
        raise ValueError('incomplete snapshot')
    heads = {}
    for event in sorted(events, key=lambda e: (e['task'], e['seq'])):
        previous_seq, previous_hash = heads.get(event['task'], (0, '0' * 64))
        body = '\n'.join(str(event[k]) for k in ('task','seq','event_id','actor','previous','event_text'))
        if event['seq'] != previous_seq + 1 or event['previous'] != previous_hash or sha(body.encode()) != event['digest']:
            raise ValueError('snapshot chain mismatch')
        heads[event['task']] = (event['seq'], event['digest'])
    if {k: list(v) for k,v in heads.items()} != manifest['heads']:
        raise ValueError('snapshot watermark mismatch')
    # Only a database supervisor can suspend the insert-chain trigger for exact
    # replay of historical actors. Destructive triggers remain enabled.
    with connection.transaction():
        for task in tasks:
            register(connection, **task)
        connection.execute('ALTER TABLE aegis.events DISABLE TRIGGER chain')
        for event in events:
            connection.execute('INSERT INTO aegis.events(task,seq,event_id,actor,event_text,previous,digest) '
                               'VALUES (%s,%s,%s,%s,%s,%s,%s)', tuple(event[k] for k in ('task','seq','event_id','actor','event_text','previous','digest')))
        connection.execute('ALTER TABLE aegis.events ENABLE TRIGGER chain')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    commands.add_parser('init')
    registration = commands.add_parser('register')
    registration.add_argument('--task', required=True)
    registration.add_argument('--principal', required=True)
    registration.add_argument('--description', required=True)
    restoration = commands.add_parser('restore')
    restoration.add_argument('snapshot', type=Path)
    args = parser.parse_args()
    with psycopg.connect(os.environ['AEGIS_ADMIN_DSN'], autocommit=True) as connection:
        if not connection.execute('SELECT pg_try_advisory_lock(7351,1)').fetchone()[0]:
            raise RuntimeError('worker active; offline administration required')
        if args.command == 'init':
            connection.execute((ROOT / 'database/schema.sql').read_text())
        elif args.command == 'register':
            register(connection, args.task, args.principal, args.description)
        else:
            restore(connection, args.snapshot)
    print(json.dumps({'status': 'APPLIED', 'command': args.command}))


if __name__ == '__main__':
    main()
