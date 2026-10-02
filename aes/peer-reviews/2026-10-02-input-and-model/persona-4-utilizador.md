# Persona 4 — Utilizador

Judged by what a person sees and can do.

## BLOCKER 1 — I still cannot walk into a door

The party stops now, which was not true an hour ago, and the joystick points the way
it is pushed, which was also not true. But there is no evidence from a player's seat
that a door works. `make check` never opens the browser. The one transition test
cannot await the transition, which means the room the player walks into has never
been watched arriving by anything.

I pressed keys. The party moved. I do not know that walking through a door works,
and neither does this repository.

## MAJOR 2 — the party still slides, it just slides correctly now

Gravity was the wrong axis, so an untouched party no longer drifts. But the four
directions have one pose each, and holding a key slides the party rather than walks
it. `browser_motion.py` reports 12 of 12 steps moving, so nothing is stuck, and it is
still the most visible thing left on screen.

## MAJOR 3 — the keyboard does nothing until the canvas has focus

`_KeyboardControls` requests focus in `initState`. On the game screen that is the
only focusable thing, so it works — and if anything ever takes focus, a player
holding the right arrow gets nothing, with no indication the key was received.
There is no key hint in the HUD, so a player who does not try the arrow keys never
learns they work.

## MINOR 4 — the switch is visible now, and I could not see it before

Worth recording because it is the kind of thing that gets lost. `switch_1` was under
the conveyor for the whole project, and what made it look present was the sprite bug.
Every visual defect in this round had a second defect behind it.

## What I would want next

One thing, and it is not a test: open the game, walk into a door, and watch what
happens. Every other measurement here is about pixels and trees. The one claim nobody
can make is that the thing is playable.
