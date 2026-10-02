---
id: SD-CI-001
cluster: ci
title: Measure the room the game built, not the one the test rearranged
score: 0.95
epistemic_state: SUPPORTED
last_verified: 2026-10-02
access_count: 4
provenance: T089, commit 193df43
source_chunks:
  - aes/tickets/T089-placement-guard-cannot-fail.md
---

# SD-CI-001

A measurement of a scene the test has modified is not a measurement of the scene.

Three conventions were tried while a single entity measured 0 pixels with the room
present and 3200 alone:

1. Collect the removals, restore them after the loop. By the third entity the
   first two were already gone, so every number described a room emptied around
   the thing being measured.
2. Restore each entity before the next. This fixed the accumulation and broke the
   draw order: `add` appends, `children` is a `ReadOnlyOrderedSet` with no
   insert-at-index, so the 1024-wide conveyor had been re-appended *after* the
   switch. The test was manufacturing the occlusion it existed to detect.
3. What works: every child out, render, every child back in original order except
   the one under test, render, every child back.

Three entity counts were wrong under the old conventions and nobody knew:
`door_east` 3200, `spring_1` 800, `fish_1` 2400 — all inflated, because an entity
measured against a room missing its neighbours counts their disappearance as its
own contribution.

## The rule

Rebuild the scene exactly as the code built it, and assert that the rebuild is
faithful before measuring anything in it. If the restore cannot reproduce the
scene, every subsequent number is of the restore.
