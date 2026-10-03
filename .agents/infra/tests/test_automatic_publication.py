import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path[:0] = [str(ROOT), str(ROOT / 'infra')]
from pipelines.publish import publish, git


class PublicationTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name) / 'target'
        self.root.mkdir()
        self.remote = Path(self.tmp.name) / 'remote.git'
        git(self.root, 'init', '-q', '-b', 'bootstrap')
        git(self.root, 'config', 'user.name', 'fixture')
        git(self.root, 'config', 'user.email', 'fixture@example.invalid')
        subprocess.run(['git', 'init', '--bare', '-q', str(self.remote)], check=True)
        git(self.root, 'remote', 'add', 'origin', str(self.remote))
        self.framework = self.root / '.agents'
        for name in ('.agents/scripts/generate.py', 'tools/sync_instructions.py'):
            p = self.root / name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text('# no generated fixtures\n')
        git(self.root, 'add', '.')
        git(self.root, 'commit', '-qm', 'fixture source')
        (self.framework / 'data').mkdir()
        (self.framework / 'data/manifest.json').write_text('{"events":1}')

    def test_pushes_every_export_and_verifies_remote(self):
        receipt = publish(self.framework, self.root, [])
        self.assertEqual(receipt['commit'], git(self.root, 'rev-parse', 'HEAD'))
        self.assertEqual(git(self.remote, 'show', 'refs/heads/bootstrap:.agents/data/manifest.json'), '{"events":1}')

    def test_unrelated_changes_and_failed_remote_block(self):
        (self.root / 'unexpected.txt').write_text('not an automatic logging change')
        with self.assertRaises(ValueError):
            publish(self.framework, self.root, [])
        (self.root / 'unexpected.txt').unlink()
        git(self.root, 'remote', 'set-url', 'origin', str(self.remote.parent / 'missing.git'))
        with self.assertRaises(subprocess.CalledProcessError):
            publish(self.framework, self.root, [])
        self.assertIn('manifest.json', git(self.root, 'show', '--stat', 'HEAD'))
