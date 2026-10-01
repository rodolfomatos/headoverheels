---
id: T088
status: open
severity: major
found_by: aes-peer-review/2026-09-30-render-fidelity
related: T084
---

# T088 — `switch_1` is drawn under the floor

## Statement

With entity sprites cut to real cells (T084's `srcSize`), `switch_1` measures 0
pixels: taking it out of the room changes nothing on screen. Before `srcSize` it
measured 800px.

## What is ruled out

- Not the colour filter. Every entity's art component was read at runtime and
  none has one; `SwitchEntity._showState` passes `null` while the switch has not
  been thrown, and `tint` maps `null` to no filter.
- Not the sheet. `switch_master.png` cell (0, 0) is 2304 pixels of solid
  `(33,150,243)`, and after the generator fix every row of every entity sheet
  has at least as many filled cells as the manifest declares.
- Not a blank animation frame. The measurement now holds every entity's art on
  frame 0 (`pinArtToFirstFrame` in `room_render_test.dart`), and `switch_1` is
  still 0.
- Not the size of the cell. Fish 64x32 and monster 64x64 are both larger than
  the 64x32 entity box and both improve; switch at 48x48 does not.
- Not the position. `switch_1` sits at `[0.0, 96.0]` like any other entity.

## The likely mechanism, not yet proven

Something is drawn over the switch. The strip bug made the sprite eight cells
wide, so it extended past whatever covers it and was visible; cut to its real
48x48 cell it fits entirely underneath. That would make the strip bug the only
reason a switch has ever been on screen, which is worth knowing on its own.

`room_render_test` has a second pass that removes an entity's siblings to tell
"hidden" from "absent", but it never runs: the first assertion fails first, on
the switch. Moving the switch to a second assertFirstOrLast, or running the
"alone" pass first, would answer this in one run.

## Why the registry change is not landed with the rest of T084

The frame count and the generator are wrong independently of `srcSize` and are
fixed in this commit. `srcSize` is not, because it cannot be shown to make every
entity correct while one of them stops drawing. The registry still builds
`Sprite(image)` with no `srcSize`, so entity art is still drawn as the whole
master sheet.
