---
id: T095
status: open
severity: major
found_by: aes-peer-review follow-up while closing T091
---

# T095 — a door cannot be told from a working door in this environment

## Statement

The browser walk can load the game, hold a key and see the party move. It cannot
get the party through a door, and **nothing follows from that about the doors.**

## Measured

A twelve-way search of walks -- four single directions and twelve ordered pairs,
eleven seconds per direction -- after the room had demonstrably stopped arriving
(the settle window changed 0.00% of the frame):

```
ArrowUp+ArrowRight   0.42%   moved
ArrowLeft            0.42%   moved
ArrowUp              0.42%   moved
ArrowLeft+ArrowDown  0.42%   moved
ArrowUp+ArrowLeft    0.00%   nothing
ArrowUp+ArrowDown    0.00%   nothing
```

Sixteen walks, none over 0.42%. The party is a 64x40 sprite on a 1280x800 frame,
which is 0.25% of it, so 0.42% is the party moving about one sprite-width in
eleven seconds.

Then the frame rate, twelve captures at one-second intervals with nothing
happening:

```
captures: 12, distinct: 11, most repeated: 2 of 12
```

The game renders roughly one frame per second under SwiftShader. In the widget
tests the party covers about one tile per thirty frames, so at one frame per
second **one tile is half a minute of wall time here**. A walk across a planet is
minutes of game time and hours of wall time.

## Why this is not a finding about the doors

A broken door and a renderer too slow to walk are the same picture: the party
shifts a little and the room never changes. A player who cannot walk because the
game is stuck and a player who cannot walk because the harness runs at one frame a
second need different tickets, and only one of them is a fault in this project.

`scripts/browser_walk.py` now exits **2** for that case, which the Makefile treats
as inconclusive. It is not a pass and it is not a failure, and the code says which
in as many words.

## The earlier green, corrected

An earlier run reported `ArrowUp 14000ms -> 23.10%` and the gate printed OK. That
was **the room arriving**, not a door: the room was still loading when the key went
down. The gate could not tell those apart because it had no settle window, and it
passed while proving nothing -- the same fault this project keeps finding, in a
gate I wrote this session to fix that fault.

Both are now fixed: the walk waits for the room to stop changing, and the
evaluation refuses to call a room change unless the frame was stable beforehand.

## What would actually settle it

1. A renderer that runs at more than a few frames per second: a GPU, or a
   different software path. Worth measuring before anything else, because every
   browser claim depends on it.
2. Then the walk, which is written and works: it navigates by the game's own
   `world.json`, so the plan says where the doors are meant to be and the pixels
   say whether they are there. Eleven rooms are reachable from the start and it
   plans a twenty-hop Euler tour of all of them.
3. And a second thing the map cannot supply: door *positions*. `world.json` records
   a direction per room, which names a door and not a tile, so no player-following
   instruction can be derived from it. The party would have to walk into walls.

## What is established

The game loads in a real browser, the keyboard works there, and the party moves.
That is all. Whether a door leads anywhere is still only a human with their hands
on it -- but now for a stated reason, with a number attached, rather than as an
assumption.
