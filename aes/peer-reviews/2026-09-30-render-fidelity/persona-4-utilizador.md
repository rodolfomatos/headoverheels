# Persona 4 — Utilizador

Written after the three previous reviewers, against the tree as it stands at
`13078b9` rather than at `eb92dca`. Everything here is judged by what a person
sees and can do, and every finding names the evidence it rests on.

## BLOCKER 1 — a switch is in the room and cannot be seen

`room_render_test.dart` measures `switch_1` at **0px** with the room as it is, and
**3200px** with the room to itself. It is drawn under the `ConveyorEntity` at the
same `y`, which is 1024 wide and added after it.

A player walks into a room with a switch, a belt across the floor, and a switch
they cannot see. The switch is the only interaction in the room that is not
obvious from the picture — a belt you can walk on, a door you can see, a bag you
can see — so the one object the player has to read off the screen is the one that
is not there.

The renderer is not at fault. `srcSize` cut the sprite from 384x192 to its real
48x48 cell, and the switch stopped being an 8-cell streak that spilled ink onto
neighbouring tiles. The switch was hidden before the fix too; the fix stopped
hiding it. Recorded in T088, and Z3's unsat core names the intent it breaks
(`a_every_entity_visible`, `a_intent_is_false`).

## MAJOR 2 — a door can be walked through and nothing happens

Not on the first try: the second time. `transitionTo` threw
`ConcurrentModificationError` because it removed each character from the list it
was iterating, and `removeCharacter` detached the party from its only parent, so
with the room gone the party was in no tree at all. A `FlameGame` draws no tree
but its own: the party did not move rooms, it disappeared.

Fixed in `41a8985` — the party now lives in `world` between rooms and is
reparented into the room it stands in. What is missing is a test, and the reason
is not an excuse: a room change cannot be driven from `testWidgets`, because
`runAsync`, `pump` and `resumeEngine` are mutually exclusive (D006). So the fix
rests on review alone. A player is the only instrument that will ever exercise
this, which is exactly the situation where a fix should not be trusted.

## MAJOR 3 — no keyboard

The joystick and the on-screen buttons move the party and change the frame. The
keyboard does nothing. Nothing in the input layer reads a key. A player who
reaches for the arrow keys, because every game they have played this year uses
them, gets a character standing still in a room that is otherwise alive.

T083, open, not started.

## MINOR 4 — party animation is a single pose per direction

Four directions, one pose each, so walking is sliding. The frame changes, and
`browser_motion.py` confirms 12 of 12 steps moved, so nothing is stuck — the
motion is just locomotion without a gait. This is the most visible thing left on
screen and the least likely to be noticed by anyone who has not compared it with
the original.

## MINOR 5 — the layout is now right and looks it

Worth recording as an observation, not a finding. The room is centred, the party
stands on the floor rather than a tile above and to the left of it, and entities
sit on the floor instead of floating. Two of the three reviewers' blockers from
the previous round are gone. The remaining pixel-level problem is the placement
guard, which measures the room's full-frame bounding box and so cannot fail; the
reviewer measured 3918 of 8656 content pixels on bare background and `conveyor_1`
entirely outside, which means the test is not holding the line it was written to
hold.
