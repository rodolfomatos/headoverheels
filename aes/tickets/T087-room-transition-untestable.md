---
id: T087
status: open
severity: major
found_by: aes-peer-review/2026-09-30-render-fidelity (pragmatic)
decision: D006
---

# T087 — no regression test can reach a room change

## Statement

The two blockers fixed in `game.dart` (the `ConcurrentModificationError` and the
party detached from every tree) have no regression test, because a room change
cannot be driven from `testWidgets`. Reasoning and measurements in
`aes/decisions/D006.md`.

## Closure

Either an `integration_test` that walks through a door, or a seam that lets a
test unload a room without loading one. Not a test that hangs.
