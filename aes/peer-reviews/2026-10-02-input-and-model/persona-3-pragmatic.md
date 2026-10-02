# Persona 3 — Pragmático

## BLOCKER 1 — nothing in the gate drives the game

`make check` is green and `room_transition_test.dart` passes. But `make check` does
not call `make verify-browser` — that is a separate target — so **nothing in the gate
drives the game**. Every finding this project has produced about how the game feels
came from a human with their hands on it.

The transition fix was reviewed into existence and is covered by one widget test
that cannot await the thing it tests. If a door is broken again the gate will be
green, exactly as it was green when the party vanished on every door.

## MAJOR 2 — the party's position is a float and the movement tests assert floats

`key east: 1.0,1.0 -> 2.87,1.0`. The party is on a tile grid, so its position should
be a tile index. `gridPosition` being a `double` is why the east test needed sixty
frames before it saw anything: a single frame moves 0.001 tiles and rounds to the
same integer. Every movement test in that file is sixty times slower than it needs to
be and correspondingly less precise than it looks.

## MAJOR 3 — T085's blank-frame budget of two frames is unexplained

The test asserts `lessThanOrEqualTo(2)` and the comment says "two frames is the
ceiling". Measured is zero. So the budget is a number someone chose, and it will be
raised the first time a slow machine makes a transition take three frames and someone
decides the test is being unreasonable. Either it is derived from something — the
frames the tileset decode is observed to take, plus one — or it should be zero, since
zero is what is measured.

## MINOR 4 — `keyboard_input_test` runs a real game for one assertion

`partyFollowsTheKeys` boots the world, renders frames and settles sixty of them to
assert that a held key moves the party east. Most of that is harness cost and none
of it is the claim. It is the right trade, but the file does not say why the
expensive assertion is expensive.

## What I approve

Dropping `runAsync`, `pump` and `resumeEngine` from the requirement list and
asserting the invariant *during* the transition rather than after it. The three are
genuinely incompatible and the way out was to stop needing all three.
