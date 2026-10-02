---
id: SD-META-002
cluster: meta
title: Assert which, not only that
score: 1.0
epistemic_state: SUPPORTED
last_verified: 2026-10-02
access_count: 5
provenance: 9b5643e, 8ba982a
---

# SD-META-002

Every visual defect found in this round was a measurement that could not tell the
two cases it existed to separate apart. Not one was the drawing code drawing the
wrong picture.

- The placement guard compared the union of a room's contents against the room's
  union. An entity in the corner does not change the union, so it passed with any
  entity anywhere. Sixteen correct plus one wrong equals seventeen correct.
- `room_render_test` asked "how much did it paint". The party was reported as
  painting 3,635 pixels while standing nowhere near the floor.
- The joystick was a half turn out — push up, the party walked south — and nothing
  caught it, because the party moved and the frame changed, and those were the
  only two questions anyone had asked.
- `sprite_load_test` asserted the declared frames *tiled* the sheet. Eight frames
  of eight cells does tile it, so four blank cells per row passed.

## The rule

"It changed" is not a claim. "It changed the way the control was pointed" is, and
only the second one fails when the mapping is a half turn out. Pin the four
directions by name, not "the party moved".

The corollary is worse: a test that asserts nothing specific is worse than no test,
because it is trusted precisely when nobody is looking.
