---
id: T093
status: done
severity: minor
found_by: aes-peer-review/2026-10-02-input-and-model (pragmatic)
---

# T093 — the party is on a tile grid and its position is a float

## Statement

`gridPosition` returns doubles. The party walks on tiles, so its position is a tile
index, and every movement test in this project compensates for that:

```
key east: 1.0,1.0 -> 2.87,1.0
```

A single frame moves 0.001 tiles and rounds to the same integer, which is why the
east test needs sixty frames before it sees anything. Every movement test is
therefore sixty times slower than it needs to be, and as coarse as it looks: an
assertion of `moved.x > start.x` would pass for a drift of a hundredth of a tile
just as readily as for a tile of movement.

## Closed, and the claim it started with was wrong

`gridPosition` is integral. `exactPosition` keeps the fraction and is what the
renderer reads. Recorded in D011.

The ticket opened by saying every movement test was "sixty times slower than it
needs to be". Measured, that is false: the walk is one tile a second, so a whole
tile takes sixty frames and the tests already spent sixty. The sixty was never the
cost of a float — it is the cost of a tile.

What the float made impossible was asserting anything **smaller** than a tile.
`gridPosition` moved 0.001 per frame and rounded back to the same integer, so "it
moved" was only observable once a whole tile had gone by. There is now a sub-tile
claim, asserted on `exactPosition` after six frames, and a whole-tile claim sixty
frames later:

```
six frames:   the party has moved at all
sixty frames: the party travelled a whole tile east, 1.0 -> 3.0
```

Two claims where there was one weak one, which is the actual improvement.

`position` was already Flame's own `Vector2` on the component, so the fractional
getter is `exactPosition`. Shadowing it would have broken the transform.
