---
id: T085
status: open
severity: minor
found_by: session observation
---

# T085 — the room came up empty once after a joystick drag

## Statement

Observed once in the browser and not reproduced: after a joystick drag the room
rendered with no contents.

Not reproduced across the render suite, which boots the room many times and draws
a frame each time, nor in `make verify-browser`, which confirms 12 of 12 motion
steps change.

## What closing it needs

It needs to happen again, or it needs a mechanism rather than a sighting. The
plausible mechanisms are the ones the room load has already been bitten by: a
child added before the tilemap is mounted draws nothing, and a restore that
appends rather than inserting changes the order. Both are now covered by the
convention `room_render_test` and `room_placement_test` use, and both were
confirmed by measurement rather than by reading.

Kept open rather than closed on the grounds that it has not recurred, because a
defect that has not recurred is not a fixed defect.
