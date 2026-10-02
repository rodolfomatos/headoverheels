# Synthesis — render fidelity, round 2

Scope `da02f9e..13078b9`. Rubric `templates/review-rubric.md`, hash
`7f375dc0acc2ccfa325259a81eeca0f628b3554fe3e71075dc4f13b9e584aba0`.
Four personas: Cínico, Purista, Pragmático, Utilizador. All four ran.

## What the round found, and what happened to it

| # | Finding | Persona | Severity | State |
|---|---|---|---|---|
| 1 | `Makefile` claimed the page distorts the canvas and blamed the browser | Cínico, Purista | BLOCKER | fixed `41a8985` |
| 2 | `room_placement_test` cannot fail — full-frame bbox | Cínico | BLOCKER | **open** |
| 3 | `transitionTo` throws, party detached from every tree | Pragmático | BLOCKER | fixed `41a8985`, **no test possible** (D006) |
| 4 | `switch_1` is not visible to a player | Utilizador | BLOCKER | **open** (T088) |
| 5 | Entity art drawn as the whole master sheet | Utilizador | MAJOR | fixed `fe27b6a` |
| 6 | Manifest declared 8 frames of sheets holding 4 | Cínico | MAJOR | fixed `f248ce1` |
| 7 | Generator wrote rows outside its own sheet | Cínico | MAJOR | fixed `f248ce1` |
| 8 | No keyboard input | Utilizador | MAJOR | **open** (T083) |
| 9 | Entity pixel counts measured a playing animation | Purista | MAJOR | fixed `f248ce1` |

## The two findings still open are the two that matter

**The placement guard cannot fail.** It measures the room's bounding box, which
covers the whole frame, so it passes whether the room is on the floor or in the
corner. Every placement defect in this project's history passed it, because it
was never measuring placement. This is the same class of fault as the strip bug:
a test that constructs the condition it is looking for by accident, or not at all.
Replacing it with a per-entity presence check against the floor is the work.

**The switch is invisible.** Not a rendering fault — a z-order one, and the only
one the reviewer could reach that a player would notice on the first screen.

## What this round is worth saying about the process

Three of the nine findings were in the tooling that was supposed to catch the
other six: a guard that cannot fail, a measurement of a playing animation, and a
frame count that tiled a sheet instead of fitting in it. Two more were in the
reviewer tooling itself — `gmif-check.sh` reporting SAT on islands Z3 rejected,
and a scanner that reported its own output as a conflict.

That is the pattern worth carrying forward: **the checks are the code, and they
are where the bugs are.** No finding in this round was "the game drew the wrong
picture because the drawing code was wrong". Every one was a measurement that
could not distinguish the two cases it existed to separate.

## Recommendation

Do not close the round. Two blockers are open, and one of them is the instrument
the next round would rely on.
