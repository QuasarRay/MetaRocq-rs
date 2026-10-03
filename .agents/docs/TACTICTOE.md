# TacticToe persistence

TacticToe does not permanently learn merely by calling `ttt`. Aegis therefore
treats recording as a separate, explicit pipeline.

The cache root is always supplied through `HOL4_TACTICTOE_CACHE`. CI restores the
latest cache compatible with the pinned HOL4 revision, calls
`scripts/record_tactictoe.sh`, then saves a new immutable cache generation.
TacticToe's own manifest hashes decide which theories are stale and need recording.

The cache is **search guidance, not proof evidence**. Generated proof scripts must
still build through direct `Holmake`/HOL4 kernel checking. A corrupt, stale, or
malicious TacticToe cache can at worst degrade search or propose bad tactics; it
must never be able to mark a failed HOL4 build as verified.

For a target repository:

1. set `HOLDIR` to the pinned built HOL4 checkout;
2. set `HOL4_TACTICTOE_CACHE` to a persistent path;
3. build the target theory with `Holmake`;
4. run `record_tactictoe.sh THEORY WORKDIR`;
5. persist the cache between CI runs;
6. independently rerun `Holmake` before accepting any proof claim.
