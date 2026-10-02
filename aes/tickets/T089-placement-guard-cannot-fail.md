---
id: T089
status: done
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

## Resolved, and it was the measurement, not the room

The switch measured 0px with the whole room present and 3200px alone. Three
conventions were tried and the first two were wrong in ways that produced
confident numbers.

**Collecting the removals and restoring them after the loop.** By the third
entity the first two were already gone, so every number described a room that had
been quietly emptied around the thing being measured.

**Restoring each entity before the next.** This fixed the accumulation and broke
the draw order instead. `add` appends, `children` is a `ReadOnlyOrderedSet` with
no insert-at-index, so by the time `switch_1` was measured the 1024-wide conveyor
had been re-appended *after* it and the switch read 0px while standing plainly
visible. The test was manufacturing the occlusion it was looking for.

**What works: the room is rebuilt exactly as the game built it.** Every child out,
render, every child back in its original order except the one under test, render,
then every child back. A measurement of a room the test has rearranged is not a
measurement of the room.

```
before the fix                        after
door_east    3200px                   6400px
spring_1      800px                   1600px
hushpuppy_1   800px                   1000px
fish_1       2400px                   3200px
switch_1        0px                   3200px
```

Four of those were wrong before and nobody knew. An entity measured against a room
missing its neighbours counts their disappearance as its own contribution, so the
bigger an entity's neighbours the more it was credited with. `door_east` was
credited with half of what it draws.

The switch now measures 3200px in the room and 3200px alone. Equal, which is what
"not covered" looks like from the outside, and the covered list is empty.

## What the placement guard still needs

The aggregate bounding box is still wrong: the union of a room's contents is
nearly as large as the room, so an individual entity in the wrong place does not
change it. That part is untouched and is still the reason every placement defect
in this project passed. The per-entity version can now be built on the
rebuild-exactly-as-built convention above, which is the part that took the work.

## Note on what did land

`pinArtToFirstFrame` moved out of `room_render_test.dart` into
`test/support/hoh_frame.dart`, because two measurements needed it and a second
copy would have drifted from the first. That is independent of this ticket and
is the reason the rewrite above was possible at all.
