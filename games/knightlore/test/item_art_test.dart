// The things a player has to find, and whether they can be seen.
//
// Knight Lore is six ingredients and two scrolls. A player who cannot see an
// ingredient cannot pick it up, and a game that hides its own objective is
// broken however correct its rules are. Every test that mentions an item in this
// package tests the item's logic — pickup, casting, the cauldron's demands — and
// none of them asked whether the item is on the screen. These do.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math.dart' show Vector3;
import 'package:knightlore/knightlore.dart';

import 'polish_test.dart' show compareFrames, renderRoom;
import 'test_asset_bundle.dart';

void main() {
  // The sheet an item is drawn from has to be one the game loads, and it has to
  // be on disk. `scroll` was neither, for as long as the game existed: five
  // sheets were drawn, and nothing asked for them.
  test('every item has a sheet the game loads, and the sheet is on disk', () {
    final missingFromLoad = <String>[];
    final missingFromDisk = <String>[];

    for (final item in KlItems.all) {
      final sprite = KnightLoreManifest.spriteForItem(item.id);
      if (!KnightLoreManifest.propTypes.contains(sprite)) {
        missingFromLoad
            .add('${item.name} wants "$sprite", which is not loaded');
        continue;
      }
      // The runtime folds the area into the name, so the sheet that has to
      // exist is the one for an area.
      final onDisk = File(
        '${KnightLoreManifest.spritesBasePath}/props/${sprite}_${KlAreas.all.first}.png',
      );
      if (!onDisk.existsSync()) {
        missingFromDisk.add('${item.name}: ${onDisk.path} is not on disk');
      }
    }

    expect(missingFromLoad, isEmpty);
    expect(missingFromDisk, isEmpty);
  });

  test('the six ingredients and the scrolls are all in the catalogue', () {
    // The rule the whole game is built on, asserted here so that deleting an
    // ingredient is a test failure and not a mystery.
    expect(KlItems.ingredients, hasLength(6));
    final kinds = KlItems.all.map((item) => item.kind);
    expect(kinds.where((kind) => kind == ItemKind.scroll), hasLength(6));
  });

  test('opening a chest puts the item on the screen', () async {
    // The whole point, in pixels. A chest opens, the item lands on the floor at
    // the party's feet, and the room is rendered again. If the item is not
    // drawn, the two frames are identical, and this fails.
    final game = KnightLoreGame(
      config: const KnightLoreGameConfig(daySeconds: 1000, autoCycle: false),
      bundle: TestAssetBundle(),
    );
    addTearDown(game.dispose);
    await game.onLoad();

    final view = game.roomView ?? game.createView();
    if (view == null) {
      fail('the game has no room to draw: ${game.error}');
    }
    game.roomView = view;
    final session = game.session!;

    // The party is put in front of the chest *before* the first frame. Moving a
    // knight between two frames changes the picture on its own, and a test that
    // measures that is measuring the knight.
    final chest =
        session.room.triggers.firstWhere((trigger) => trigger.type == 'chest');
    session.leader.position =
        Vector3(chest.position.x, chest.position.y + 1, 0);
    session.leader.facing = Facing.north;

    final before = await renderRoom(view, shadows: true);

    expect(session.interact(), InteractOutcome.chestOpened,
        reason: 'the chest did not open, so there is nothing to see');
    expect(session.itemUnderfoot, isNotEmpty);

    final after = await renderRoom(view, shadows: true);
    final difference = compareFrames(before, after);

    // A lit sheet on a dark floor adds light. The shadow under an item is
    // drawn whether or not the item itself is, so light is the assertion that
    // says the item is *there* and not merely that something changed: with the
    // drawing switched off, this is the number that goes to zero.
    expect(difference.lighter, greaterThan(20),
        reason: 'the frame changed but got no lighter, so the item on the '
            'floor is a shadow and nothing else');
    // The bounding box of every pixel that changed, measured rather than
    // described: a Rect can print itself convincingly while saying nothing.
    expect(
      difference.changed.width * difference.changed.height,
      greaterThan(0),
      reason: 'the room looks identical after a chest opened',
    );
  });

  test('the items the world hides in chests are all drawable', () async {
    // Every chest in every room names an item. Each one has to resolve to a
    // sheet that the game loads, or that chest opens into nothing.
    final game = KnightLoreGame(
      config: const KnightLoreGameConfig(daySeconds: 1000, autoCycle: false),
      bundle: TestAssetBundle(),
    );
    addTearDown(game.dispose);
    await game.onLoad();

    final world = game.session!.world;
    final undrawable = <String>[];
    var chests = 0;
    for (final room in world.rooms.values) {
      for (final trigger in room.triggers) {
        if (trigger.type != 'chest') continue;
        chests++;
        final properties = trigger.properties['properties'];
        final itemId = properties is Map ? properties['itemId'] : null;
        if (itemId is! String) continue;
        final sprite = KnightLoreManifest.spriteForItem(itemId);
        if (!KnightLoreManifest.propTypes.contains(sprite)) {
          undrawable.add('${room.id}: ${trigger.id} wants "$sprite"');
        }
      }
    }
    expect(chests, greaterThan(0));
    expect(undrawable, isEmpty);
  });
}
