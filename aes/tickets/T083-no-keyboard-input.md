---
id: T083
status: done
severity: major
found_by: aes-peer-review/2026-09-30-render-fidelity (utilizador)
---

# T083 — Head over Heels has no keyboard at all

## Statement

The joystick and the on-screen buttons move the party and change the frame. No
key does anything. Nothing in the input layer reads a key.

A player who reaches for the arrow keys gets a character standing still in a room
that is otherwise alive.

## Why it is still open

Not started. The peer review raised it as the first thing a player would notice
that is not a rendering fault, and it has not been picked up.

## What closing it needs

`InputSystem` reads the joystick and the buttons. Keyboard means mapping keys onto
the same two axes plus the action button, and the test that matters is not "a key
produces an event" — it is that the party moves in the direction the key names and
that the frame changes. `room_render_test` already measures whether the party
follows its state, so the check exists and is not wired to a key.


## Closed, and the second fault underneath it

The keyboard is landed: arrows and WASD move, space and Z jump, X and C carry,
V and F fire, tab and Q swop. Direction is accumulated from the held keys and
normalised, because a joystick cannot be pushed past its radius and an
unnormalised diagonal moves at sqrt(2) times the speed.

While testing it, the joystick itself turned out to be **a half turn out**:

    push up    -> south
    push right -> west
    push down  -> north
    push left  -> east

`_offsetToDirection` subtracted `pi/2` where it needed to add it.
`Direction8.values` starts at north and counts clockwise, so `fromAngle`
reads 0 as north and a screen offset is a quarter turn away from north.

It has been backwards for as long as it has existed and nothing caught it,
because nothing asserted *which* direction a push produced. The party moved, the
frame changed, and those were the only two questions anyone had asked. That is
the same shape as every other finding in this round: the measurement could not
distinguish the two cases it existed to separate.

`InputSystem.directionOfOffset` is the tested seam, and the four pushes are
pinned by name.

## What closing it uncovered

The party does not stop when the control is released. That is T090 and it is a
blocker, because a player who cannot stop cannot play. It is reachable by a key
now, so every key press became a permanent commitment the moment this landed.
