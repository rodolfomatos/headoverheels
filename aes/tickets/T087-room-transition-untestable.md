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


## The fix for the party has a one-frame gap, found by the test this ticket asked for

`room_transition_test.dart` cannot await the whole transition (D006), but it can
start one and watch the party while it happens. Written and run, it fails:

```
after 0 steps of a room change the party is gone: 0 of 2 are in a tree
```

`_unloadCurrentRoom` does:

```dart
room.removeCharacter(character);   // detaches
await world.add(character);        // and only then attaches
```

There is an `await` between the detach and the attach, so across it the character
is parentless. A `FlameGame` draws no tree but its own, so for that frame the
party is not on screen.

The original bug was the same shape with no window at all: it detached and never
re-attached. The fix moved the characters to `world` and made the transition stop
throwing, which is most of it — but it did not make the move atomic, and "the party
is in a tree at every moment" was never actually asserted by anything.

## Why the test is not committed

It fails, and the fix it wants is a refactor rather than a patch: build the new
room before tearing the old one down, then reparent the characters from one room to
the other in a single synchronous step, with no `await` in the middle. That is
worth doing and it is not something to start without being able to finish and
verify it.

The test is written and kept here rather than in `test/`, because a red file in the
suite trains everyone to ignore red, and the measurement above is the record.

## What closing this properly needs

1. `_loadRoom` builds the new room while the old one is still standing.
2. Characters move from the old room to the new one in one step, synchronously.
3. Then the old room is torn down with nobody in it.
4. `room_transition_test.dart` goes into `test/` and asserts the party is findable
   at every step, which is what it does today and fails.

Step 4 is the point: the invariant was never asserted, which is why a fix that
removed the crash and the disappearance still left a frame where the party is not
drawn.
