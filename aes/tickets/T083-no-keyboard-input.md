---
id: T083
status: open
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
