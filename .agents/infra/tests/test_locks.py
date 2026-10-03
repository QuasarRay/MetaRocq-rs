import json, os, socket, tempfile, unittest
from pathlib import Path
import sys
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from agentinfra.locks import FileLock, LockError

class TestProcessLock(unittest.TestCase):
    @unittest.skipUnless(os.name == "nt", "Windows sharing violations are a Windows host behavior")
    def test_transient_permission_error_during_create_is_bounded_contention(self):
        with tempfile.TemporaryDirectory() as td:
            lock=FileLock(Path(td)/"x.lock","transient")
            original=lock._try_create
            calls=0
            def transient(payload):
                nonlocal calls
                calls+=1
                if calls==1:
                    raise PermissionError("seeded Windows sharing window")
                return original(payload)
            with patch.object(lock,"_try_create",side_effect=transient):
                owner=lock.acquire(timeout=0.5)
            self.assertEqual(calls,2)
            self.assertEqual(owner["pid"],os.getpid())
            lock.release()

    def test_dead_owner_does_not_authorize_racy_lock_unlink(self):
        with tempfile.TemporaryDirectory() as td:
            p=Path(td)/"x.lock";p.write_text(json.dumps({"schema":2,"nonce":"abandoned-owner","pid":2147483647,"process_identity":None,"host":socket.gethostname(),"purpose":"old"}))
            original=p.read_bytes()
            with self.assertRaisesRegex(LockError,"exclusive recovery"):
                FileLock(p,"new").acquire()
            self.assertEqual(p.read_bytes(),original)
