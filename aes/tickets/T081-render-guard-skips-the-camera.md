---
id: T081
status: done
severity: major
decision: D003
---

# T081 — the render guard skips the camera, so it cannot see placement

## Statement

The render guards composited the sprite and the view but never the camera, so a
room drawn in the wrong place measured correct.

## Closure

The guard now composes view and camera exactly as the renderer does before it
takes a pixel. A guard that reconstructs a different pipeline from the one under
test is a second implementation, and it agrees with itself.

Verified by moving the camera in the test and requiring the measurement to
change. See `aes/decisions/D003.md`.
