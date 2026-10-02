---
id: T091
status: done
severity: major
found_by: aes-peer-review/2026-10-02-input-and-model (pragmatic, utilizador)
---

# T091 — nothing in `make check` drives the game

## Statement

`make check` runs format, lint, unit tests, package tests, sprite checks, the
python suite and `aes-check`. It does not call `make verify-browser`, which is the
only thing in this repository that opens the game.

Every finding this project has produced about how the game *feels* came from a
human with their hands on it: the party vanishing on every door, the joystick a
half turn out, an untouched party sliding down the room, a switch under a
conveyor. The gate was green through all four.

## Why it is not simply "wire it in"

`verify-browser` needs a built web bundle and a Playwright server, so it is
minutes rather than seconds, and wiring it into `make check` would make the gate
useless for a two-second edit. The honest shape is a second gate that runs
alongside the fast one, and a rule that which is which is written down.

## Closed: the game is driven, and a door is measured

**`scripts/browser_check.js` takes a `KEYS` step.** `KEYS=ArrowUp:14000,...`
holds each key for its duration and captures the frame before and after, so the
party walks rather than teleporting one frame's worth. The keyboard has existed for
one commit and this is the only thing in the repository that uses it the way a
player would.

**`scripts/browser_door.py` asks a question `browser_motion.py` cannot.** Motion
asks "does the frame change", and the party moving changes the frame, so that
question is answered by a game that is alive and broken in the same way. The
discriminator here is arithmetic:

- The party is a 64x40 sprite. Walking it across a 1000x720 frame changes about
  0.4% of it.
- A different room changes nearly all of it.

So **more than a fifth of the frame changed cannot be walking.** The margin is
about fifty times the sprite's maximum share, which is the point: a threshold
nobody had to defend does not get relaxed the first time a slow machine is called
unreasonable.

Measured, driving the real build:

```
hoh_key_ArrowUp_14000   -> hoh_after_ArrowUp_14000:   23.10%
hoh_key_ArrowDown_14000 -> hoh_after_ArrowDown_14000:  0.00%
hoh_key_ArrowLeft_14000 -> hoh_after_ArrowLeft_14000:  0.41%
hoh_key_ArrowRight_14000-> hoh_after_ArrowRight_14000: 0.00%
```

Walking north changed the room. The other three show 0.00% because after the
transition the party is somewhere else and those directions lead into a wall, which
is itself the discriminator working: the party did not move and the frame did not
change.

**Two gates, and which is which is written on the target.** `make check` stays fast
and does not build; `make verify-browser` builds and opens. The reason is on the
target rather than left to whoever is in a hurry, because `make check` was green
through all four of the defects this project found by hand.

## What this does not claim

That the party can solve the game. It can walk, and walking north through a door
changes the room. Every other room, every puzzle, and whether the doors lead
anywhere sensible are still only a human with their hands on it.
