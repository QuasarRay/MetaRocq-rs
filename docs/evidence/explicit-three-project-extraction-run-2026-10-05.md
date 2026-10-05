# Explicit three-project extraction attempt

An explicitly requested unified run now attempts the retained three-project
LambdaBox root once, after the existing CakeML controller returns. This root
differs from the legacy Peregrine self-host root: it retains the complete
mapped Rocq, Stdlib, Peregrine, and MetaRocq declaration inventory as program
data. An earlier legacy bootstrap failure must not hide its own compilation
result.

Both processes use the existing regression-style observer, with individual
exit status, combined output, resource accounting, and completion markers.
`explicit-producer-statuses.txt` records both results. Any original controller
failure remains the overall failure; a successful controller followed by a
failed retained-image build also fails. No semantic proof gate is opened by
candidate generation. The builder activates the existing pinned opam switch
installed by the controller instead of rebuilding it.

The workflow remains manual-only. This does not repeat the failed legacy
producer from the workflow's separate source-to-machine lane. The existing
generated-checkpoint capture and final trace commit preserve the new build's
logs, inventory, and any produced artifacts.

Validation: four subprocess regressions exercise the actual observer and
both independent process failures, verify each program runs once, and check
the captured status and resource files. Shell syntax and whitespace checks
pass. Fixture program success is not kernel verification. A real cloud
attempt is still required; verified full proof replay and source-to-machine
composition remain open.
