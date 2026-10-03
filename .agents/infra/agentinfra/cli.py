from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

from .metarocq import MetaRocq
from .contracts import ContractError, authority, authority_digest, read_json, validate_plan


def main(argv=None):
    parser = argparse.ArgumentParser(description="MetaRocq original-specification work cycles; no test-order gates")
    parser.add_argument("--root", type=Path, default=Path.cwd())
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("authority")
    validate = commands.add_parser("validate")
    validate.add_argument("plan", type=Path)
    freeze = commands.add_parser("freeze")
    freeze.add_argument("plan", type=Path)
    freeze.add_argument("--metarocq", type=Path, required=True)
    freeze.add_argument("--peregrine", type=Path, required=True)
    commands.add_parser("brief")
    verify = commands.add_parser("verify")
    verify.add_argument("--timeout", type=int, default=120)
    extract = commands.add_parser("extract")
    extract.add_argument("--timeout", type=int, default=600)
    extract.add_argument("--retry-diagnosis", help="failure diagnosis and correction; changed inputs also required")
    checkpoint = commands.add_parser("checkpoint")
    checkpoint.add_argument("--pr", type=int, required=True)
    commands.add_parser("audit")
    inspect = commands.add_parser("inspect-artifact")
    inspect.add_argument("archive", type=Path)
    inspect.add_argument("--run", type=int, required=True)
    inspect.add_argument("--head", required=True)
    inspect.add_argument("--sha256", required=True)
    inspect.add_argument("--max-expanded-mib", type=int, default=64,
                         help="explicit expanded ZIP budget, 1..256 MiB (default 64)")
    args = parser.parse_args(argv)
    try:
        app = MetaRocq(args.root)
        if args.command == "authority":
            out = {"digest": authority_digest(), **authority()}
        elif args.command == "validate":
            out = {"task": validate_plan(read_json(args.root / args.plan))["task"], "valid": True}
        elif args.command == "freeze":
            out = app.freeze(args.plan, {"metarocq": args.metarocq, "peregrine": args.peregrine})
        elif args.command == "extract":
            out = app.extract(args.timeout, retry_diagnosis=args.retry_diagnosis)
        elif args.command == "verify":
            out = app.verify(args.timeout)
        elif args.command == "checkpoint":
            out = app.checkpoint(args.pr)
        elif args.command == "inspect-artifact":
            from .ci_artifact import inspect
            out = inspect(args.root, args.archive, expected_run=args.run,
                          expected_head=args.head, expected_sha256=args.sha256,
                          max_expanded_mib=args.max_expanded_mib)
        else:
            out = getattr(app, args.command)()
        print(json.dumps(out, sort_keys=True, separators=(",", ":")))
        if args.command == "verify" and any(x["status"] != "CHECKED" for x in out["results"]):
            return 2
        if args.command == "extract" and out["status"] != "GENERATED":
            return 2
        return 0
    except (ContractError, OSError, ValueError, RuntimeError, KeyError, TypeError) as exc:
        print(json.dumps({"ok": False, "error": str(exc)}, sort_keys=True), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
