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
box against the room's box, restore. The aggregate check is kept as the cheap
smoke test it always was, and the two live in separate tests so each measures one
thing.

It does not ship. Measured, in this order:

```
restore changed 0 pixels          the hand-rolled restore is faithful
these entities have no box to check at all: [switch_1]
```

The restore reproduces the room pixel for pixel, the room's art is held on frame
0 exactly as `room_render_test` holds it, and `switch_1` still has no box. The
same entity, measured by the same remove-and-diff mechanism, is 3200px in
`room_render_test` in the same run. The two differ only in that this file takes
every child out and re-adds them before measuring.

So there is a state the room can be in, after a full detach and re-attach, in
which the switch draws nothing, and it is not reproduced by the frame being
identical. That is the kind of fact you do not write an assertion around: the
assertion would encode the confusion rather than the behaviour.

## What is needed

Find what the detach and re-attach changes about `switch_1` that a pixel
comparison does not see. The candidates are the draw order of the re-added
children and the sprite's own re-mount, and the discriminator is cheap: after the
dance, read `switch_1`'s art component and compare `srcPosition`, `srcSize`,
`paint.colorFilter` and index in `room.children` against the same read taken
before the dance. Anything that differs is the answer.

Until then the guard stays as it was, which is worse than having none only because
it looks like it is holding a line.

## Note on what did land

`pinArtToFirstFrame` moved out of `room_render_test.dart` into
`test/support/hoh_frame.dart`, because two measurements needed it and a second
copy would have drifted from the first. That is independent of this ticket and
is the reason the rewrite above was possible at all.
