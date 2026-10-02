---
id: T090
status: open
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

## Why it is not a one-line fix

`jump()` writes the jump into the same axis:

```dart
velocity: Vector2(state.velocity.x, -state.jumpHeight / (state.jumpDurationFrames / 60.0)),
```

A negative **y** velocity, on a plane where `y` is a tile row. So gravity and jump
both operate on the tile plane, while `isGrounded`, `jumpPhase` and `position.z`
all describe a height axis that is never integrated.

The model does not say which axis is up. Deciding that is a design question, not a
patch: either gravity and jump move to `z` and the tile plane is genuinely flat,
or `z` is dropped and jumping is expressed some other way. Whichever it is, the
two have to agree, and right now they do not.

Until then the party cannot stop, and T083 made that reachable by a key.

## The discriminator that remains

Whichever axis is chosen as height, the test is the same and it is cheap: hold a
key, release it, settle a second, and require the party's grid position to be
unchanged. That test fails today, in the way it should — it is written for the fix,
not for the diagnosis, and shipping it now would mean shipping a red suite.
