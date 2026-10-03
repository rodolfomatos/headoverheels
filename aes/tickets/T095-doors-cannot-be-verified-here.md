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

## The frame rate, measured properly — and my first number was wrong

The number above came from counting distinct screenshots one second apart: twelve
captures, eleven distinct, so "about one frame per second". **That was a sampling
artefact and it was wrong.** Sampling once a second cannot distinguish one frame a
second from sixty; it can only produce a lower bound, and I treated the lower bound
as the value.

`scripts/browser_fps.js` counts `requestAnimationFrame` callbacks, which is the
renderer's own count of frames it drew, with no sampling and no inference:

```
4.1 fps  ( 33 frames)  angle/swiftshader  1280x800   (what verify-browser uses)
0.0 fps  (  0 frames)  angle/swiftshader   640x400
5.9 fps  ( 47 frames)  plain swiftshader  1280x800   (what browser_walk used)
4.3 fps  ( 34 frames)  headless default   1280x800
0.0 fps  (  0 frames)  angle/swiftshader   960x600
```

Four to six frames a second. Slow, but not the one I said. Two configurations
produced **zero** frames: a smaller viewport does not merely run slower, the game
never starts — the click coordinates were found at 1280x800 and land somewhere else
at a smaller one.

## The party is not blocked

In the widget test, holding east for 300 frames:

```
50f 3,1   100f 4,1   150f 6,1   200f 7,1   250f 9,1   300f 11,1
```

and then south from (11,1) to (11,11). It crosses the room freely. So the 0.42% the
browser reports is not a party stuck against something: a sprite is 64x40, 0.25% of a
1280x800 frame, and a party that has moved from x=1 to x=11 differs from where it
started by **exactly one sprite's worth of pixels** — which is what 0.42% is. The
party walked ten tiles. The frame barely moved because there is one sprite in it.

## So the real obstacle is the map, not the renderer

Ten tiles east from the spawn does not reach a door, because the door is somewhere
else along the wall. `world.json` records `exits: [{direction: east, room:
castle_cell}]` — **a direction and a destination, and no position**. A player walks
*to* a door; the map cannot say where it is; holding east walks one row and hits a
wall.

That is the whole finding, and it is a map-completeness question rather than a
performance one or a physics one. It also means the renderer's four frames a second
is an inconvenience for exploratory walking and nothing more.

## Why this is not a finding about the doors

A broken door and a walk that never goes to the door are the same picture: the party
shifts a little and the room never changes. They need different tickets, and only
one of them is a fault in this project. The measurement above says which: the party
crosses ten tiles when told to, so nothing is stuck.

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

1. **Door positions in the map.** Not positions on screen — tiles. The trigger zone
   already has them; `world.json`'s exit record does not. One field per exit, and
   the walk becomes derivable: walk to the tile, then walk through. Until that
   exists, no automated traversal is possible and every attempt is a walk into a
   wall.
2. Then the walker, which is written and works: it navigates by the map, twenty
   hops over the eleven reachable rooms.
3. A faster renderer is worth having for exploratory work, and `browser_fps.js`
   already measures it. It is not what is standing between this project and
   traversal evidence.

## What is established

The game loads in a real browser at four to six frames a second, the keyboard works
there, and the party crosses ten tiles when told to walk. Whether a door leads
anywhere is still a human with their hands on it — now for a stated reason with two
numbers attached: the map has no door positions, and the renderer is at four frames
a second rather than the sixty a walk wants.
