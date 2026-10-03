// The same claim as `chest_placement_test.dart`'s "every chest names an item the
// game knows", without the game.
//
// That version fails about once in four `make check` runs and not once in
// twenty-five runs of its own file, which is a fact about the *test*, not about
// the game. It builds the whole game -- `onLoad`, every TMX, a RoomSession -- and
// then walks rooms by calling `enterRoom` and reading `session.room` back. Three
// candidate causes were read and falsified:
//
//   * `enterRoom` is synchronous, validates the room, and assigns `_roomId`
//     before returning; `room` is `world.getRoom(_roomId)!`.
//   * the world is parsed from JSON synchronously before the first await, and
//     `session` is constructed only after every TMX has loaded.
//   * `KlItems._byId` is a `static final` over a `const` list with no mutator.
//
// So the traversal is sound and the data is fixed, and neither explains a
// failure that only appears on a loaded machine. What is left is that the test
// depends on state it does not need: to ask whether a chest names a real item,
// nothing here requires the game to be running.
//
// This version reads the world file and answers the question. If it is
// deterministic and green, the flake was the harness rather than the world -- and
// the older test keeps its stronger reachability assertions, which do need a
// session.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:iso_core/iso_core.dart' show WorldGraph;
import 'package:knightlore/knightlore.dart' show KlItems, KnightLoreWorld;

import 'test_asset_bundle.dart';

void main() {
  test('every chest in the world names an item the catalogue has', () async {
    final bundle = TestAssetBundle();
    final world = WorldGraph.fromJson(
      jsonDecode(await bundle.loadString(KnightLoreWorld.worldKey))
          as Map<String, dynamic>,
    );

    final problems = <String>[];
    var rooms = 0;
    var chests = 0;

    for (final entry in world.rooms.entries) {
      rooms++;
      for (final trigger in entry.value.triggers) {
        if (trigger.type != 'chest') continue;
        chests++;
        // `RoomTrigger.fromJson` stores the whole trigger object under
        // `properties`, so the chest's own properties are nested one level in.
        // Reading `properties` directly finds nothing and would call every chest
        // nameless.
        final nested = trigger.properties['properties'];
        final itemId = nested is Map ? nested['itemId'] : null;
        if (itemId is! String) {
          problems.add('${entry.key}/${trigger.id}: no itemId');
        } else if (KlItems.byId(itemId) == null) {
          problems.add('${entry.key}/${trigger.id}: "$itemId" is not a '
              'catalogue item');
        }
      }
    }

    // Zero chests would make the loop above vacuously green, which is the failure
    // this repository keeps meeting. The counts are asserted, not just reported.
    expect(rooms, greaterThan(0), reason: 'the world has no rooms');
    expect(chests, greaterThan(0), reason: 'the world has no chests');
    expect(problems, isEmpty,
        reason: 'checked $rooms rooms and $chests chests. problems:\n'
            '${problems.join("\n")}');
  });

  test('the catalogue lookup is not a lazy cache that can come up empty', () {
    // The third candidate cause. A `static final` map built from `const` data has
    // no window in which it is half-built, so asking twice must agree -- and the
    // second ask is the one that would expose an initialisation order problem.
    final first = KlItems.all.length;
    final again = KlItems.byId(KlItems.all.first.id);

    expect(KlItems.all.length, first);
    expect(again, isNotNull);
  });
}
