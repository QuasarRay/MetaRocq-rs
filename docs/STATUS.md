# Current status

Merged bootstrap PRs 1 and 2 supply the supervision scaffold. The post-merge
preflight drift is repaired in the resumable-extraction change. The inspected
artifact from run 37104122593 contains no generated Rust; its extraction and
compilation steps were skipped. The earlier toolchain build was cancelled.

The next cloud run reuses partial/completed dependency installations when the
source pins, recipe and runner image match, records the actual current run,
and attempts the original PCUICAst.isApp typed extraction and Rust compilation.
This is one pipeline slice, not a complete MetaRocq reimplementation.

The original Rocq contract files are unchanged. No Kani proof, HOL4 source
refinement, macro certificate, or machine-code proof has been established.
All production blockers remain recorded in spec/obligations.json.
