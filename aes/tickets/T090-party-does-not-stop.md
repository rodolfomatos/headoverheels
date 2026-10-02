---
id: T090
status: open
severity: blocker
found_by: aes-peer-review follow-up while closing T083
---

# T090 — the party does not stop

## Statement

Releasing the movement control does not stop the party. It keeps walking.

## Measured

Holding the right arrow for 60 frames, then releasing it:

```
released at 2.87,28.77
after 60 more frames at 2.87,38.24
```

x is frozen, so the party did stop moving east. y kept increasing by 9.5 tiles.
That is not coasting: coasting decays, and this is a steady rate over a full
second. Something is still driving it along that axis.

`InputSystem.onJoystickDirection(Offset.zero)` calls `notifier.stop()`, and
`directionFromKeys` returns null for an empty key set, so the mapping reports "no
direction" correctly. The fault is downstream of both: either `stop()` does not
clear whatever `update(dt)` integrates, or something else in the room is
continuing to push the party — a conveyor at the party\'s own row being the
obvious candidate, and `castle_start.tmx` does place `conveyor_1` across the room.

## Why it is a blocker and not a bug

A player who cannot stop cannot play. With the keyboard landed in the same
commit, this is now reachable by a key, and every key press becomes a permanent
commitment.

## Why the assertion is not in the test

It would have meant either a red suite or a weaker claim than the one that turned
out to be true. The test that shipped asserts what is established -- a held key
moves the party the way the key points -- and this ticket carries the rest.

## What closing it needs

The discriminator is cheap and is not in the room: run the same sequence with the
conveyor removed. If the party stops, the belt is the cause and the fix is the
party not being carried when the player is not asking to move. If it keeps going,
read `CharacterStateNotifier.stop()` against `update(dt)` and find the term that
is not being cleared.
