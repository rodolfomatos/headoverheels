---
id: T096
status: closed
severity: minor
found_by: a failure captured during T095's investigation
---

# T096 — CLOSED: every candidate cause was falsified, and the claim moved

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


## Closed: the claim moved to a test that has nothing to be flaky about

I did not reproduce it. Twenty-five quiet runs had already failed to, and adding
more would not have produced an explanation -- only more of the same absence.

So I read all three candidates instead, and **none of them survives**:

- **`session.room` after `enterRoom`.** `room_session.dart:341` validates the
  room, throws on an unknown id, and assigns `_roomId` before returning;
  `room` is `world.getRoom(_roomId)!`, a plain `rooms[roomId]` lookup
  (`iso_core/lib/src/levels/levels.dart`). There is no window.
- **`onLoad` and a half-built world.** `_loadWorld` parses the world from JSON
  *synchronously* before its first await, then loads every TMX, and only then
  constructs `RoomSession`. A world that was short would have to be missing rooms
  from `world.rooms`, which is finished before anything is awaited.
- **`KlItems.byId` built lazily.** `items.dart:86` is `static final` over a
  `static const` list, with no mutator anywhere. A `static final` in Dart has no
  window in which it is half-built.

The data is also clean and fixed: **15 rooms, 13 chests, every `itemId` resolves**,
read straight out of `knightlore_world.json`.

## What that leaves, and what I did about it

Nothing in the game. What the flaky test did not need was the game.

To ask whether a chest names a real item, you need the world's triggers. The test
got them by constructing the whole thing -- `onLoad`, every TMX, a `RoomSession` --
and then walking rooms by calling `enterRoom` and reading `session.room` back. That
is a great deal of machinery between the question and the data, and it is the only
thing in the file that was not sound.

`games/knightlore/test/chest_catalogue_test.dart` now asks it directly:

```dart
final world = WorldGraph.fromJson(
    jsonDecode(await bundle.loadString(KnightLoreWorld.worldKey))
        as Map<String, dynamic>);
```

No game, no session, no `enterRoom`, nothing to schedule. It also asserts its own
counts -- `expect(rooms, greaterThan(0))` and `expect(chests, greaterThan(0))` --
so it cannot pass by looking at nothing, which is the failure mode this repository
keeps meeting. The version in `chest_placement_test.dart` is gone; that file keeps
the reachability assertions, which genuinely do need a session.

## One thing worth recording, found while reading

`RoomTrigger.fromJson` (`iso_core/lib/src/levels/levels.dart:275`) stores

```dart
properties: Map<String, dynamic>.from(json),
```

-- the **entire trigger object**, not its `properties` sub-object. So a chest's own
properties sit one level down, at `trigger.properties['properties']['itemId']`. I
read the raw JSON first, saw `properties.itemId` flat, and briefly had evidence
that all thirteen chests were nameless. The data was fine; my reading was not. The
nesting is load-bearing and undocumented, and it is the kind of thing that makes a
test look broken when the world is not.

## Honest limits

The flake's mechanism is still unknown. What is claimed here is narrower and
supported: the three named causes are false, the data is correct, and the claim
now lives in a test with no scheduling in it. If this ever fails again, it will be
a real finding rather than a harness artefact.
