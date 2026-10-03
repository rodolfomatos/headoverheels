---
id: T096
status: open
severity: minor
found_by: a failure captured during T095's investigation
---

# T096 — an intermittent Knight Lore failure, named but not reproduced

## Named

```
games/knightlore/test/chest_placement_test.dart: every chest names an item the
game knows
```

It was seen once in four `make check` runs and **not once** in:

- three runs of the Knight Lore suite on its own,
- six runs of that suite with `--concurrency=8`,
- fifteen runs of `chest_placement_test.dart` on its own.

It only appears inside `make check`, where Knight Lore is the fifth `flutter test`
in the same shell, after Head over Heels and three package suites.

## Why it was never noticed before

Because nobody had the name. A run of `make check` reported `+174 -1` and no test
name, and the next three runs were green, so it was recorded as a flake — which is
the least useful thing you can record about a failure. Naming it took four more
`make check` runs.

## What has been hardened, and what that is worth

- Every room loop in this file iterates `List.of(session.world.rooms.keys)` rather
  than the live map's keys. `enterRoom` is synchronous and does not mutate the map
  today, so this is not the fix and it is not claimed to be; it removes one way the
  loop could skip or repeat a room if that ever changes.
- The failing assertion now reports **how many rooms and how many chests it
  checked**. "One chest of three hundred and forty is wrong" and "one chest of
  twelve is wrong" are different problems, and there was no way to tell them apart
  from the message it used to give.

That is not a fix. It is a better failure message, which is what you want when the
next occurrence is the one that gets you the answer.

## The candidates, by reading rather than by measuring

- **`session.room` read after `enterRoom`.** `enterRoom` is synchronous and sets
  the room, so this should be sound. It is the first thing to check if the next
  failure names a chest from a room that was not the one being entered.
- **`TestAssetBundle` and `await game.onLoad()`.** If the world's rooms or a room's
  triggers are populated after `onLoad` returns, the test reads a partially built
  world and how much it reads depends on scheduling. That would explain why it needs
  a loaded machine to happen and does not happen in fifteen quiet runs.
- **`KlItems.byId`.** If the catalogue builds its lookup lazily and something else
  initialises it first, `byId` could return null for an item that is really there.

## What would settle it

The next occurrence, which now prints the counts. If the counts are short, it is the
world being half-built and `onLoad` is the thing at fault. If the counts are full
and one item is named that is genuinely not in the catalogue, it is data and the
message already says which item and which room.
