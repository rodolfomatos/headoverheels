---
id: T085
status: done
severity: minor
found_by: session observation
---

# T085 — the room came up empty once after a joystick drag

## Statement

Observed once in the browser and not reproduced: after a joystick drag the room
rendered with no contents.

Not reproduced across the render suite, which boots the room many times and draws
a frame each time, nor in `make verify-browser`, which confirms 12 of 12 motion
steps change.

## Closed: three mechanisms tested, one of which was the cause

Not closed on the grounds that it has not recurred. Three mechanisms were named,
and each was measured.

**1. A room presented before its tileset decoded.** `_loadRoom` adds the new room
and sets `_currentRoom`, and `world.add` resolves before the tileset has decoded,
so in principle the room is mounted and interactive while painting nothing.
`room_transition_test.dart` samples every frame of a transition from the first
frame:

    blank frames across the transition: 0 of 40

Refuted. The load completes before the first frame is presented.

**2. A restore that appends and so reorders.** Covered by construction since
T088 and T089: floor treatment is drawn first by declared priority, and every
render measurement rebuilds the room exactly as the game built it. See
SD-CI-002.

**3. A room whose contents are all invisible.** This is the one, and it was not
this ticket's fault for not finding it. The party was detached from every tree on
every door, so a room after a transition had a floor and nothing else. A player
reporting an empty room after a joystick drag was reporting the room it had just
walked into. That is fixed, and the invariant — both characters in a tree the game
draws, at every step of every transition — is asserted in
`room_transition_test.dart`.

The joystick in the sighting was incidental: the drag was the last thing that
happened before the room changed.

## What would reopen it

A blank room, with a frame count. The test above samples every frame of every
transition and fails above two blank ones, so a recurrence is caught at the door
rather than by a player.
