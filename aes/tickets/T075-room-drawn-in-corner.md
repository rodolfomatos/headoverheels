---
id: T075
status: done
severity: major
decision: D002
---

# T075 — the room is drawn in the corner, unscaled, at runtime

## Statement

The Head over Heels room was rendered in a corner of the canvas at its native
size, unscaled, while the view reported it centred.

## Closure

The camera had no size, so the room's own component laid out at its tile size and
the camera never applied a transform. Closed by giving the camera a size derived
from the viewport and pinning it to the room's top-left anchor so the room is
centred rather than centred twice.

Verified by the off-screen render guards in `flutter test`, which measure where
the room lands rather than asking whether anything was drawn. See
`aes/decisions/D002.md`.
