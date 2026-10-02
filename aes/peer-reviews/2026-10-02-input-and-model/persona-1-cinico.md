# Persona 1 — Cínico

Scope `2e10061..a39801d`. Fourteen commits, forty files. Judged on whether the
evidence would survive an attempt to believe the opposite.

## BLOCKER 1 — the render priority sorts, and nothing proves the sort is stable

`RoomComponent._spawnEntities` sorts by `renderPriority` with the map index as a
tiebreak, and the tiebreak's justification is that two entities of equal priority
keep the order the map declared. That justification is asserted in a comment and in
D008, and **tested nowhere**. Every render measurement in this project depends on a
room being reproducible; if the sort is not stable the measurements are of a sort,
not of a room.

## MAJOR 2 — `verticalVelocity` is unconstrained

The whole T090 fix rests on the tile plane being flat, and nothing enforces it.
`verticalVelocity` is a plain `double` on the state and `_fixedUpdate` will happily
integrate it into `position.y` the moment something adds a sideways component to a
`Vector2` velocity again. The decision is recorded in D007; the decision is not
enforced. Walking should never change `position.z`, and an unpressed party should
keep `position.z == 0`.

## MAJOR 3 — the transition test cannot fail for the reason it names

`room_transition_test.dart` breaks out of its sampling loop as soon as
`currentRoomId == targetRoomId`. The loop that samples "the party is in a tree at
every step" therefore stops at the moment the room id changes — before the rest of
`_loadRoom` finishes, and before `_frameRoom`. The invariant is asserted over the
window where it is least likely to be violated, and the rest of the transition is
not sampled at all.

A fixed number of steps, regardless, would close it.

## MINOR 4 — `blank frames` and `findable()` share one loop with an early exit

Two independent claims coupled by a `break`: a rendering measurement now depends on
how long the party stayed findable, and if the invariant fails the blank count is
truncated too, so one failure reports both. Record both, assert both at the end.

## MINOR 5 — `aes-conflict` checks a decision citing a missing ticket, not the reverse

Seven of the ten decisions have a ticket. A decision that governs nothing is either
a decision in general or a record that missed its ticket, and both are worth
knowing.

## What I could not attack

The GMIF island. `scripts/gmif_check.py` fails on anything that is not a clean sat
or unsat, refuses unparseable claims as PARTIAL, and has 19 tests that are each a
route to a false pass. I could not make it report success without having asked Z3.
That is the first time I have been unable to find the soft edge in one of this
project's own gates.
