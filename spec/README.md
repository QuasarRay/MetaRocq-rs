# Original contract

The full original MetaRocq repository is reused at the commit in upstream.lock.json.
Selected anchors retain their exact Git blob and SHA-256 identities. No source is
replaced by an agent-authored restatement. bootstrap.py check verifies these anchors
against the clean pinned checkout and against the independent Aegis authority lock.

These selected anchors are not a complete imported theory closure. An unchanged .v
file has original Rocq semantics; interpreting it in HOL4 is a separate OPEN proof
obligation. See obligations.json and docs/adr/0001-extraction-boundary.md.
