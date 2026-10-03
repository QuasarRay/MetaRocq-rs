from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
import ctypes
import ctypes.wintypes
import json
import os
import socket
import time
import uuid
from pathlib import Path

from .atomic import atomic_write_json


class LockError(RuntimeError):
    pass


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _process_identity(pid: int) -> str | None:
    """Return a creation identity stronger than PID when the host exposes one."""
    if pid <= 0:
        return None
    if os.name == "nt":
        PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
        handle = ctypes.windll.kernel32.OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, pid)
        if not handle:
            return None
        try:
            creation = ctypes.wintypes.FILETIME()
            exit_time = ctypes.wintypes.FILETIME()
            kernel = ctypes.wintypes.FILETIME()
            user = ctypes.wintypes.FILETIME()
            if not ctypes.windll.kernel32.GetProcessTimes(
                handle, ctypes.byref(creation), ctypes.byref(exit_time), ctypes.byref(kernel), ctypes.byref(user)
            ):
                return None
            value = (creation.dwHighDateTime << 32) | creation.dwLowDateTime
            return f"win-filetime:{value}"
        finally:
            ctypes.windll.kernel32.CloseHandle(handle)
    stat_path = Path(f"/proc/{pid}/stat")
    try:
        # Field 22 is process start time.  The command name may contain spaces inside parentheses.
        tail = stat_path.read_text(encoding="utf-8").rsplit(")", 1)[1].split()
        return f"proc-start:{tail[19]}"
    except (OSError, IndexError):
        return None


def _pid_alive(pid: int, identity: str | None = None) -> bool:
    if pid <= 0:
        return False
    if os.name == "nt":
        PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
        ctypes.windll.kernel32.SetLastError(0)
        handle = ctypes.windll.kernel32.OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, pid)
        if handle:
            ctypes.windll.kernel32.CloseHandle(handle)
            alive = True
        else:
            alive = ctypes.windll.kernel32.GetLastError() == 5
    else:
        try:
            os.kill(pid, 0)
            alive = True
        except ProcessLookupError:
            alive = False
        except PermissionError:
            alive = True
    if alive and identity is not None:
        current = _process_identity(pid)
        return current is None or current == identity
    return alive


@dataclass
class FileLock:
    """Short-lived process lock authenticated by nonce and process creation identity."""

    path: Path
    purpose: str
    _owner: dict | None = field(default=None, init=False, repr=False)

    def _try_create(self, payload: dict) -> None:
        fd = os.open(self.path, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8", newline="\n") as stream:
            json.dump(payload, stream, sort_keys=True)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())

    def acquire(self, *, timeout: float = 10.0) -> dict:
        if self._owner is not None:
            raise LockError("lock object already owns a lease")
        if timeout < 0 or timeout != timeout or timeout == float("inf"):
            raise ValueError("lock timeout must be finite and non-negative")
        self.path.parent.mkdir(parents=True, exist_ok=True)
        payload = {
            "schema": 2,
            "nonce": uuid.uuid4().hex,
            "pid": os.getpid(),
            "process_identity": _process_identity(os.getpid()),
            "host": socket.gethostname(),
            "created": _now(),
            "purpose": self.purpose,
        }
        deadline = time.monotonic() + timeout
        last_contention: PermissionError | None = None
        while True:
            try:
                self._try_create(payload)
                self._owner = payload
                return dict(payload)
            except FileExistsError:
                pass
            except PermissionError as exc:
                # Windows may report a sharing violation rather than
                # FileExistsError while another thread/process is creating or
                # unlinking the lock.  During that window exists() can also be
                # false, so retry to the explicit deadline instead of leaking
                # a nondeterministic raw OSError from the lock abstraction.
                if os.name != "nt":
                    raise
                last_contention = exc
            info = self.inspect()
            if info.get("exists") and info.get("same_host") and info.get("pid_alive_here") is False:
                # Observing a dead owner does not atomically authorize unlink:
                # another recovery process may already have replaced the file.
                raise LockError(f"abandoned lock requires exclusive recovery: {self.path} ({info})")
            if time.monotonic() >= deadline:
                raise LockError(f"lock already exists or remains inaccessible: {self.path} ({info})") from last_contention
            time.sleep(min(0.05, max(0.001, deadline - time.monotonic())))

    def inspect(self) -> dict:
        last_error = None
        for delay in (0.0, 0.002, 0.01, 0.03):
            if delay:
                time.sleep(delay)
            try:
                data = json.loads(self.path.read_text(encoding="utf-8"))
                break
            except FileNotFoundError:
                return {"exists": False}
            except PermissionError as exc:
                last_error = exc
            except Exception as exc:
                return {"exists": True, "corrupt": True, "error": str(exc)}
        else:
            return {"exists": True, "corrupt": True, "error": str(last_error)}
        if not isinstance(data, dict):
            return {"exists": True, "corrupt": True, "error": "lock record is not an object"}
        if not isinstance(data, dict) or not isinstance(data.get("nonce"), str):
            return {"exists": True, "corrupt": True, "error": "missing owner nonce"}
        data["exists"] = True
        data["same_host"] = data.get("host") == socket.gethostname()
        data["pid_alive_here"] = (
            _pid_alive(int(data.get("pid", -1)), data.get("process_identity")) if data["same_host"] else None
        )
        try:
            data["age_seconds"] = max(0.0, time.time() - self.path.stat().st_mtime)
        except OSError:
            data["age_seconds"] = None
        return data

    def release(self, *, nonce: str | None = None) -> None:
        if self._owner is None:
            raise LockError("this lock object does not own the process lock")
        info = self.inspect()
        if not info.get("exists"):
            self._owner = None
            raise LockError("owned process lock disappeared")
        expected = nonce or self._owner["nonce"]
        if (
            info.get("nonce") != expected
            or info.get("nonce") != self._owner.get("nonce")
            or info.get("host") != self._owner.get("host")
            or int(info.get("pid", -1)) != os.getpid()
            or info.get("process_identity") != self._owner.get("process_identity")
        ):
            raise LockError("refusing to release process lock with mismatched owner binding")
        last_error = None
        for delay in (0.0, 0.002, 0.01, 0.03, 0.08):
            if delay:
                time.sleep(delay)
            try:
                self.path.unlink()
                break
            except PermissionError as exc:
                last_error = exc
        else:
            raise LockError(f"owned process lock could not be released after bounded sharing retries: {last_error}")
        self._owner = None
