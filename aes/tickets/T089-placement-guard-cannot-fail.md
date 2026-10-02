---
id: T089
status: open
severity: major
found_by: aes-peer-review/2026-09-30-render-fidelity (cinico, pragmatic)
---

# T089 — the placement guard measures the room and calls it the contents

## Statement

`room_placement_test.dart` compares the bounding box of everything in the room
against the bounding box of the room. That check cannot fail. The union of every
entity in a room is nearly as large as the room, so an entity in the wrong place
does not change the union. Sixteen entities placed correctly and one in the
corner produce the same union as seventeen correct ones.

This is why every placement defect in this project's history passed it.

## What was attempted, and what stopped it

Rewritten to measure each entity alone: remove one, diff the frame, check that
box against the room's box. It does not ship, and the reason turned out to be
worse than the original fault.

## The diagnosis is wrong, and here is what killed it

The first hypothesis was that taking every child out and re-adding them left the
switch in a state a pixel comparison cannot see. Measured, comparing every
entity's art component before and after the dance:

```
before switch_1: idx=4 | SpriteAnimationComponent f0=[0,0]/[48,48] filter=null
after  switch_1: idx=4 | SpriteAnimationComponent f0=[0,0]/[48,48] filter=null
```

Identical index, identical sprite, identical source rect, identical filter, for
every entity. Then the decisive run: the per-entity loop **without the dance**,
on the room as spawned. `switch_1` still has no box. The dance is not involved.

## What is actually going on: the two tests measure different rooms

`room_render_test.dart` removes entities **cumulatively** -- it collects them in
`takenOut` and restores them only after the loop, so by the third entity the
first two are already gone. `room_placement_test.dart` restores each entity
before measuring the next, so every measurement is taken with the whole room
present.

Same mechanism, same entity, same run:

```
room_render_test   (cumulative removal)   switch_1 = 3200px
per-entity loop    (whole room present)   switch_1 = no box
```

So the switch is covered by something in the intact room, and
`room_render_test`'s first pass was reporting it as visible because the two doors
measured before it had already been taken away. Its 3200px was a measurement of a
room that does not exist.

That is the real finding, and it is the same fault as the aggregate box this
ticket is about, one level down: **a measurement that cannot tell the case it is
supposed to detect from the case where the thing has been removed.** Here the
removal is cumulative and unreported, and the number it produced was never a claim
about the room a player is in.

## What is needed

One convention, and it has to be the one that is honest: every entity is measured
with the rest of the room present, and a removal that persists across iterations
has to be visible in the output. `room_render_test`'s first pass and its "alone"
pass are two different questions and the first one is currently answering the
second by accident.

Until that is settled the switch's 3200px in `room_render_test` is not evidence
that the switch is visible, and this ticket says so rather than leaving the number
standing.

## Note on what did land

`pinArtToFirstFrame` moved out of `room_render_test.dart` into
`test/support/hoh_frame.dart`, because two measurements needed it and a second
copy would have drifted from the first. That is independent of this ticket and
is the reason the rewrite above was possible at all.
