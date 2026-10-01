---
id: T084
status: open
severity: major
supersedes: the "bars" symptom previously noted as T084
---

# T084 — entity sprites are drawn as the whole sheet

## Symptom

Entity art arrives on screen as a wide streak with four copies of the sprite in
it, squeezed into the entity's own box.

## Cause, confirmed by measurement

`SpriteRegistry._load` builds `Sprite(image)` with no `srcPosition` and no
`srcSize`, so the frame is the entire master sheet. A sheet is a grid: eight
cells wide, four rows. `entity.fish.swim`'s file is 512x128 with a `runtime_size`
of 64x32, so one cell is exactly one runtime cell, and the registry draws all
eight of them as one frame.

The same omission is in the per-frame `Sprite` of `_entityAnimations`: without
`srcSize` each frame still claims the whole sheet and only its origin moves.

## Two further faults found on the way

- `frameWidth = image.width ~/ frames` treats the frames as tiling the sheet.
  They do not: the sheet is eight cells wide and holds four frames per row, so
  that arithmetic makes each frame two cells wide, showing half of its
  neighbour. The cell is always the manifest's `runtime_size.width`.
- `scripts/generate_entity_masters.py` writes `row = i * 4 + frame // 8`. With
  four frames per animation `frame // 8` is always zero, so `row = i * 4` and
  animations two, three and four land at rows 4, 8 and 12 of a four-row sheet.
  PIL pastes them nowhere. Verified after regenerating: all 14 entity sheets went
  from one filled row to at least two.

## What applying the fix does, measured

With `srcSize` on both the sprite and every frame, the 14 manifest entries
corrected from `frames: 8` to `frames: 4` (four frames per animation exist; the
other four of the eight cells were blank), and the generator's row fixed:

```
                    before     after
  fish_1              800px    3200px
  monster_1          1200px    3200px
  switch_1            800px       0px
```

Two of three improved. `switch_1` went from 800px to **0px**: removing the
entity from the room no longer changed a single pixel, which `room_render_test`
reports as "in the room and drawing nothing".

## What is not yet known

The registry is correct at runtime — measured for `switch`:

```
sprite src=[0.0,0.0] size=[48.0,48.0]
frames=4 at x=0, 48, 96, 144, each 48x48
```

and `switch_master.png` cell (0, 0) is 2304 pixels of solid `(33,150,243)`, with
row 0 columns 0-3 filled. The new sheet with the old registry still measures
800px, so the sheet is not the cause and neither is the manifest count. The
regression is in how the sized sprite reaches the canvas for this one entity,
and that has not been traced.

`SwitchEntity` is not special-cased: it calls the same `showManifestSprite('switch')`
as the fish and the monster, and tints only when it has been thrown.

## Why nothing was committed

A fix that makes two entities legible and one invisible is not a fix. The whole
change was reverted; 97 tests pass and the tree is clean. The measurements above
are the input to the next attempt.

## Next

Instrument `SpriteAnimationComponent`'s render for `switch_1` alone and compare
the draw call against `fish_1`. The suspect is size: a 48x48 cell is square,
and a square cell is the only shape here where the sprite is as large as the
box the caller gives it.
