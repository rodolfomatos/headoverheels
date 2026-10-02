---
id: SD-CI-002
cluster: ci
title: add() appends, so a restore is a reordering
score: 0.95
epistemic_state: SUPPORTED
last_verified: 2026-10-02
access_count: 3
provenance: T088, T089, commits 8e27a07 and 193df43
---

# SD-CI-002

`Component.add` appends. Flame's `children` is a `ReadOnlyOrderedSet` with no
insert-at-index, so there is no way to put a component back where it was.

Any test or restore that removes a child and re-adds it has changed the draw
order as a side effect. In Flame, draw order is insertion order, so this is not a
cosmetic difference: it decides what covers what.

## Where it bit

- A switch covered by a conveyor read 0 pixels after a remove-and-restore, and
  3200 pixels in the room as the game built it. The test was creating the bug.
- `switch_1` was invisible to a player because `ConveyorEntity` was added after
  it. The real fix was a declared priority — floor treatment first — and the
  sort carries the map index as a tiebreak so a room stays reproducible.

## The rule

To restore order, rebuild the whole list in its original order. `add` alone is
never a restore.
