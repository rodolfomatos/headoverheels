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

## The placement guard, rebuilt on that convention

Each entity is dropped from a room that is otherwise exactly as the game built it,
and the box where it drew is compared against the room's own box. Three faults
were in the way and all three were in the test:

- `without` took the entity to exclude and a null meant "exclude nothing, add it
  all back", so the "room alone" frame was the room with everything in it. It now
  takes the set to drop.
- "The room alone" dropped the tilemap as well, and the floor *is* the room: what
  was left measured 60x72 pixels of wall, and every entity was reported as
  straddling the whole frame. The room alone is now the tilemap and nothing else.
- `boot` registered a second `game.dispose`. `loadRealGame` already tears the
  widget down before disposing the game; a second dispose leaves the ticker live
  and the next test reports "the game never finished loading" for reasons that
  have nothing to do with the game.

### It has teeth

Moving the tilemap 400 pixels to the right makes it fail, naming what moved:

```
these entities are not drawn inside the room: [door_east drew at x[0,1208] ...]
```

Which is the property the guard never had. The old one passed with any entity
anywhere.

### The aggregate guard is deleted, not demoted

It was kept for a while as "the cheap smoke test it always was". That is a name for
a check that cannot fail, and a check that passes whatever is placed where is not
a smoke test — it is reassurance, and it is the reason every placement defect in
this project passed. Deleting it removes a thing that looked like a line being
held. There is now one placement guard, and it can fail.

### One enumerated exception

`conveyor_1` is `x=0 width=1024` in `castle_start.tmx` — the full room width, and
the belt is floor treatment. The room's ink box is narrower than its declared
extent because the floor does not paint to the very edge, so the belt is wider
than the floor by construction, and the first run of the new guard failed on it.

That is the guard working, not the guard being wrong: the reviewer had already
measured `conveyor_1` as entirely outside the room. So the exception is
**enumerated** — one id, allowed to be as wide as the room and still checked
vertically — rather than a larger slack. A slack wide enough to admit the belt
would admit a genuinely misplaced entity, which is the fault this guard exists to
remove.

## Note on what did land

`pinArtToFirstFrame` moved out of `room_render_test.dart` into
`test/support/hoh_frame.dart`, because two measurements needed it and a second
copy would have drifted from the first. That is independent of this ticket and
is the reason the rewrite above was possible at all.
