---
id: SD-CI-003
cluster: ci
title: Gravity on the tile rows means nobody can stop walking
score: 1.0
epistemic_state: SUPPORTED
last_verified: 2026-10-02
access_count: 5
provenance: T090, commit 76e8e56
---

# SD-CI-003

`_fixedUpdate` added `9.8 * dt * 60` to `velocity.y`, and `y` is a tile row. Every
party slid south at an accelerating rate, and `stop()` could not clear it because
gravity put the velocity straight back on the next tick. `isGrounded` tested `z`,
which nothing in that method wrote, so the party was never grounded.

`jump()` wrote its impulse into the same axis, as a negative `y`. The jump phases
read `velocity.y > 0` for the apex, which on a tile row means "moving south", so
the party peaked while falling and began falling while rising.

## The rule

Pick the height axis deliberately and make everything agree. Here it was `z`
because `position` was already a `Vector3`, `isGrounded` already tested it,
`gridPosition` and the renderer already treated x and y as tile coordinates, and
every jump field already described a height. `z` was the axis the model meant and
the only one nothing integrated.

A walk velocity and a vertical velocity are different quantities. Putting them in
one `Vector2` is what allowed gravity to land in the tile plane.
