---
id: T090
status: done
severity: blocker
found_by: aes-peer-review follow-up while closing T083
---

# T090 — the party does not stop, and gravity is pulling it south

## Statement

Releasing the movement control does not stop the party. It keeps walking south,
faster, for as long as the room is running.

## Measured

Holding the right arrow for 60 frames, then releasing:

```
released at 2.87,28.77
after 60 more frames at 2.87,38.24
```

x is frozen, so the party did stop moving east. y climbs at a steady rate, and
that rate is not a coast: it is the same over both halves of the run.

## The cause, located

`CharacterStateNotifier._fixedUpdate`:

```dart
final velocity = Vector2(
  currentState.velocity.x,
  currentState.velocity.y + (9.8 * dt * 60.0),   // gravity, on the tile plane
);

final newPosition = Vector3(
  currentState.position.x + velocity.x * dt,
  currentState.position.y + velocity.y * dt,      // ...integrating into y
  currentState.position.z,
);

final isGrounded = newPosition.z <= 0;
final newVelocity = isGrounded ? Vector2(velocity.x, 0) : velocity;
```

Gravity is added to `velocity.y`, and `y` is a tile row: the party's own row went
from 28 to 38. `stop()` sets `velocity` to zero, and gravity puts it straight back
on the next tick, which is why releasing the control changes nothing. The velocity
is only cleared when `isGrounded`, and `isGrounded` is a test on **z**, which
nothing in this method ever changes — so on a floorless plane the party is never
grounded and never stops.

The conveyor is not involved. Measured with `conveyor_1` removed from the room:
the party still walks, at the same rate. That rules out the hypothesis this ticket
opened with.

## Closed: z is the height, and the tile plane is flat

Decided rather than guessed. `position` was already a `Vector3`, `isGrounded`
already tested `z`, `gridPosition` and the render layer already treated x and y as
tile coordinates, and `jumpPhase`, `jumpHeight` and `jumpFramesRemaining` all
described a height axis. `z` was the axis the model meant and the one nothing
integrated.

**`verticalVelocity` is a new field on `CharacterState`, separate from
`velocity`.** `velocity` is the walk across the tile plane and the plane is flat:
nothing in this game moves the party along a row because it fell.

- Gravity subtracts from `verticalVelocity` and integrates `position.z`.
- `isGrounded = position.z <= 0` clamps `z` to zero and clears the vertical, so a
  party that overshoots does not sink through the room.
- `jump()` sets an upward `verticalVelocity` instead of a negative `y`.
- The jump phases read the vertical: rising while it is positive, apex when it
  runs out, falling when it is negative. They used to read `velocity.y > 0` for
  the apex, which on a tile row means "moving south", so the party reached its
  peak while falling and began falling while rising.

`stop()` still clears only the walk, deliberately: a party in the air keeps
falling whether or not the player is holding a direction.

## One bug of my own, on the way

Landing was first written as `isGrounded ? Vector2.zero() : velocity`, which zeroed
both axes, so a party standing on the floor could not walk: every tick found it
grounded and threw its walk velocity away. The east test caught it immediately —
the party moved 0.03 tiles instead of 1.87. Landing clears the vertical and
nothing else.

## Measured

    key east:      1.0,1.0 -> 2.87,1.0
    released at    2.87,1.0
    a second later 2.87,1.0

y holds at 1.0 while walking east, which is the claim that was false before: the
party used to slide south at an accelerating rate with nothing pressing anything.

## One widget test, not three

This harness boots the world through `loadRealGame`, and a second `testWidgets` in
the same file reports "the game never finished loading" for reasons unrelated to
the game — the registry is a singleton and the teardown must take the widget down
before it disposes. So the sequence runs in one game, which is also the better
test: it is the same party throughout.
