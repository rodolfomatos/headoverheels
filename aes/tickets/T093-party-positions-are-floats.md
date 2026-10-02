---
id: T093
status: open
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

## The tension

Sub-tile positions are probably wanted for animation and for sliding. But a value
that is both the position and the animation phase cannot be asserted on either.

## What closing it needs

Two things: a `tilePosition` that is integral and is what placement and every
movement assertion use, and a fractional remainder for rendering. That is a model
change, so it is a decision record rather than a patch.
