---
id: T091
status: open
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

## What closing it needs

1. `make check` stays fast and stays what runs on every save.
2. A `make verify` that includes the browser, documented as the gate that runs
   before a push rather than before a save.
3. A browser assertion that is not "the frame changes". The motion check says 12
   of 12 steps moved, which is true of a game that is alive and broken in the same
   way. What would be worth having is a walk through a door, which needs the
   keyboard that T083 landed.

## The honest boundary

Until this is done, the claim "the game works" rests on human memory and this
repository cannot make it. Both reviewers who raised this said so in nearly the
same words, from opposite directions.
