---
id: SD-CI-004
cluster: ci
title: runAsync, pump and resumeEngine are mutually exclusive in a widget test
score: 0.9
epistemic_state: SUPPORTED
last_verified: 2026-10-02
access_count: 3
provenance: D006, T087
---

# SD-CI-004

A room change cannot be driven from `testWidgets`, and the three requirements are
mutually exclusive:

- `transitionTo` awaits the new room's tileset decode, which needs the real event
  loop, so it must start inside `runAsync`.
- `runAsync` denies a second call while the first is pending, so it cannot be the
  thing that drives the change to completion.
- Mounting the room needs `pump`, and every render test freezes the engine so two
  frames differ only by what the test changed — so nothing turns until
  `resumeEngine`.
- `resumeEngine` restarts the game's own `GameLoop` timers, which the binding
  counts as pending async work. `runAsync` is then refused. An empty `runAsync` at
  the top of the same test body passes.

Three ways of forcing it, all measured and all wrong: `game.update(0)` by hand
inside `runAsync` (the lifecycle pass never runs, 400 turns, no completion), and
`withLoop` (deadlock, same cause). `gridPosition` is integral, so a single 16ms
frame does not cross a tile boundary either — a working key looks like a dead one
until it is given sixty frames.

## The rule

When three requirements are mutually exclusive, the harness is the constraint, not
the code. Record it and ask for `integration_test` rather than shipping a test that
hangs for minutes and reports itself as a sink error.
