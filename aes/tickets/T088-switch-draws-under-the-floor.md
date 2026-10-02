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

## Resolved: it is a z-order fact, and the occluder is named

`SpriteRegistry._load` builds `Sprite(image)` with no `srcSize`, so an entity's
frame was the whole master sheet. `room_render_test` was asserting that every
entity draws something, measured by taking it out of the room and counting the
difference.

With `srcSize` applied, `switch_1` measured 0px, which reads as "the fix erased
a switch". It did not. The test now measures both ways in one run:

```
entity switch_1: 0px
alone switch_1: 3200px
```

With the room to itself the switch draws 3200px, exactly like `fish_1`. It was
never absent: it is drawn under a later sibling.

The room's children, in order:

```
0  TiledComponent    pos=[-480,0]      size=[1024,512]
2  SwitchEntity      pos=[0,96]        size=[64,32]
5  ConveyorEntity    pos=[-192,96]     size=[1024,32]
```

The floor is child 0, so it is under everything and covers nothing. The
conveyor is added after the switch, is 1024 wide, and sits at the same y=96. It
covers the switch for its whole length.

So the strip bug was the only reason the switch was ever visible: a 384x192
sheet squeezed into a 64x32 box spilled ink across neighbouring tiles that
nothing covered, and the test counted that spill as the switch being present.
The switch has been under the belt this whole time.

## What is left

Whether a switch should draw over a conveyor belt is a question about the game,
not about the renderer, and this commit does not answer it. The assertion pins
the covered set to `['switch_1']` so a second covered entity fails, and
`sprite_registry.dart`'s `srcSize` now ships: every entity draws its own cell,
and the switch draws 3200px the moment it is not covered.

## Confirmed by the solver, not by a reader

`aes/graph/render-invariants.yaml` states the project's intent and the
measurement that refutes it, and asks Z3 whether both can hold.

```
$ make gmif-check
[!!] render-invariants: UNSAT -- these claims cannot all be true
       unsat core: (a_every_entity_visible a_intent_is_false)
```

The core names the two claims and nothing else, which is the point of the
exercise: the intent "a room with a bag nobody can see is a room with no bag" and
the measurement "switch_1 draws 0 pixels" are not in tension because of a subtlety
in the renderer. The intent is simply false, and the switch is the entity that
makes it false.

This gate is deliberately not in `make check`, and that is a judgement worth
stating: it fails, and it should fail while T088 is open. Adding a permanently
red gate to `check` trains everyone to ignore red.
