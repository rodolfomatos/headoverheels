---
id: T082
status: done
severity: major
decision: D005
superseded: D004
---

# T082 — Head over Heels drew the room in a different coordinate space

## Statement

The room and its contents were both drawn, and the room landed in a different
place from every entity in it.

## What was decided, and what was retracted

`D004` held this NÃO-VERIFICÁVEL: the symptom was measured precisely and the
cause was not, because the same tile offset explained the room's placement, the
entity's, and the fact that a per-entity content check could not see a
discrepancy. That is a discriminator which had not been run, not a cause.

`D005` superseded it with SUPORTADA after discriminating the two spaces, and
`D004` was left standing unmarked. That left two live answers to one question in
`aes/decisions/`, which `scripts/aes_metrics.py conflict` now fails on.

## Closure

The tilemap was placed in the same isometric space as the contents. The guard
that was supposed to catch this measured the full-frame bounding box of the room
and therefore could not fail; the peer review of 2026-09-30 measured 3918 of
8656 content pixels sitting on bare background and `conveyor_1` entirely outside,
which is the real teeth the test never had.

See `aes/decisions/D005.md`, and T084 for the sprite-side consequence.
