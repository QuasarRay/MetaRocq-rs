# Unified CakeML E2E controller

This directory implements the sequential controller for the 23-step
Peregrine + MetaRocq instruction set under
`docs/unified-peregrine-metarocq-e2e/`.

## Trust boundary

The controller is written in CakeML and owns stage order, stop-on-failure
semantics and controller-side receipts.  The pinned CakeML basis used by the
existing proof stack does not expose process spawning, so external tool
execution is confined to `#(e2e_exec)`, implemented by `e2e_ffi.c`.

The FFI is **not proof evidence**.  It can only launch
`./tools/unified_e2e_stage.sh NN`; each stage separately verifies or produces
the artifacts required by the corresponding manual step.  Proof stages reject
missing theorem sources, admitted obligations and known trust escapes.

The existing self-reflective MetaRocq and vendored Peregrine work is preserved.
Nothing in this controller changes a theorem statement or upgrades producer
success into semantic evidence.

## Building

`tools/build_unified_e2e_cakeml.sh` downloads the pinned official CakeML
x64-64 release bundle used only to compile the orchestration program, verifies
its SHA-256 digest, appends the narrow FFI to the release basis FFI and builds
`generated/cakeml-unified-e2e/unified_e2e.cake`.

The theorem-bound Peregrine/MetaRocq CakeML artifacts continue to use the
separately pinned revisions in the existing E2E specs.  The controller compiler
is therefore not substituted for the formal CakeML/HOL4 proof boundary.
