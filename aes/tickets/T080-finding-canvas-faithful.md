---
ticket: T080
title: The board blamed the page for a distortion that is in the game
type: finding
status: finding-recorded
produces:
  - "aes/decisions/D001.md"
created: 2026-09-30
blocks: T075
---

# T080 — the page is faithful; the game centres for a canvas twice the window

## The claim being corrected

Recorded on the board under T075, and still standing there:

> A rectangle drawn by the game at canvas (0,0) with size 400x300 appears in the
> page at `x[666..1280] y[474..800]` — a scale of 1.535 in x and 1.087 in y. […]
> The page is therefore not a faithful picture of the canvas, and a screenshot of
> a web build in this environment cannot say *where* the game draws.

The measurement of the rectangle stands. The conclusion drawn from it does not.
It is not erased; it is corrected here and dated.

## The refuting measurement

One canvas, shadow roots included:

    { "canvases": [ { "attrW": 1280, "attrH": 800, "cssW": 1280, "cssH": 800,
                      "left": 0, "top": 0, "parent": "FLT-CANVAS-CONTAINER" } ],
      "dpr": 1 }

Intrinsic 1280x800, CSS 1280x800, at the origin, dpr 1. Nothing about the page
scales or offsets anything. A screenshot here *can* say where the game draws,
and the board should stop saying it cannot.

The earlier `flutter-view` reading on which part of that conclusion rested was
insufficient, and this is the second time today a DOM-level reading of a Flutter
web page has been the wrong instrument: `querySelectorAll('canvas')` returns
nothing at all here, because the drawing surface lives inside a shadow root.

## What is still open, and it is not the page

The room's background rectangle has its top-left at (660, 470) while the game
reports `canvasSize=Size(1280, 800)`, `scale=2.4`, `offset=(25.6, 73.6)`. Those
two are consistent with a centre computed for 2560x1600: (2560-1240)/2 = 660,
(1600-664)/2 = 468. Somewhere a size twice the window is being divided by.

## How this gets falsified

Read `RoomView.render()` and find which size the centring divides by. If it
divides by a cached `_previewOffset`/`_previewScale` that some path can leave at
a 2560x1600 value, that is the fault. If it divides by `canvasSize`, which the
instrumented build reports as 1280x800, then this ticket's arithmetic is wrong
and the offset comes from somewhere else — in which case this finding is wrong
and the next step is to instrument the centring itself.

One method, no build, no browser. Seconds, not minutes.
