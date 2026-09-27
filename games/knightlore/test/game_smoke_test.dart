import 'package:flutter_test/flutter_test.dart';
import 'package:knightlore/knightlore.dart';
import 'package:vector_math/vector_math.dart' show Vector3;

import 'test_asset_bundle.dart';

void main() {
  test('the manifest describes the party, the furniture and the areas',
      () async {
    KnightLoreManifest.write();
    final manifest = KnightLoreManifest.build();

    expect(manifest.getAsset('character.sabreman.idle.down'), isNotNull);
    for (final knight in splitKnights) {
      expect(
        manifest.getAsset('character.${knight.id}.walk.down'),
        isNotNull,
        reason: '${knight.id} has no sheet',
      );
    }
    for (final area in KlAreas.all) {
      for (final prop in KnightLoreManifest.propTypes) {
        expect(
          manifest.assets.where((entry) => entry.file.endsWith('_$area.png')),
          isNotEmpty,
          reason: 'no $prop art for $area',
        );
      }
    }
  });

  test('the game boots, loads the world and can be played', () async {
    final game = KnightLoreGame(
      config: const KnightLoreGameConfig(daySeconds: 1000, autoCycle: false),
      bundle: TestAssetBundle(),
    );
    addTearDown(game.dispose);

    await game.onLoad();
    expect(game.error, isNull, reason: '${game.error}');
    expect(game.assetsReady, isTrue);
    expect(game.session, isNotNull);
    expect(game.session!.roomId, KlRooms.gatehouse);
    expect(game.session!.terrain.width, 8);
    expect(game.screen, GameScreen.title,
        reason: 'the game opens on the title');
  });

  test('the title screen hands over to the game and back', () async {
    final game = KnightLoreGame(
      config: const KnightLoreGameConfig(daySeconds: 1000, autoCycle: false),
      bundle: TestAssetBundle(),
    );
    addTearDown(game.dispose);
    await game.onLoad();

    game.handleKey(' ');
    expect(game.screen, GameScreen.playing);

    game.handleKey('p');
    expect(game.screen, GameScreen.paused);
    game.handleKey('p');
    expect(game.screen, GameScreen.playing);

    game.handleKey('i');
    expect(game.screen, GameScreen.status);
    game.handleKey('i');
    expect(game.screen, GameScreen.playing);

    game.handleKey('escape');
    expect(game.screen, GameScreen.paused);
    game.handleKey('escape');
    expect(game.screen, GameScreen.playing);
  });

  test('winning and running out of days change the screen', () async {
    final game = KnightLoreGame(
      config: const KnightLoreGameConfig(daySeconds: 1000, autoCycle: false),
      bundle: TestAssetBundle(),
    );
    addTearDown(game.dispose);
    await game.onLoad();
    game.handleKey(' ');

    // Deliver the six ingredients the same way the cauldron does.
    final session = game.session!;
    for (var trip = 0; trip < KlItems.ingredients.length; trip++) {
      session.curse.demandIngredient(KlItems.ingredients[trip]);
      session.inventory.pickUp(KlItems.ingredients[trip]);
      session.enterRoom(KlRooms.laboratory);
      final cauldron = session.room.triggers
          .firstWhere((trigger) => trigger.type == 'cauldron');
      session.leader.position = Vector3(
        cauldron.position.x,
        cauldron.position.y + 1,
        0,
      );
      session.leader.facing = Facing.north;
      game.handleKey(' ');
    }
    expect(game.isWon, isTrue);
    expect(game.screen, GameScreen.victory);
    expect(game.message, contains('curse is broken'));

    // Back to the title, then lose on time.
    game.handleKey(' ');
    expect(game.screen, GameScreen.title);
    game.handleKey(' ');
    game.session!.curse.daysLeft = 0;
    game.update(0.016);
    expect(game.screen, GameScreen.defeat);
  });

  test('the game responds to keys and to the day cycle', () async {
    final game = KnightLoreGame(
      config: const KnightLoreGameConfig(daySeconds: 2, autoCycle: true),
      bundle: TestAssetBundle(),
    );
    addTearDown(game.dispose);
    await game.onLoad();

    game.handleKey(' ');
    final start = game.session!.leader.position.clone();
    game.handleKey('arrowRight');
    expect(game.session!.leader.position.x, start.x + 1);

    game.handleKey(' ');
    expect(game.message, isNotEmpty);

    // Let the sundial reach nightfall (a day is 2 seconds here).
    for (var i = 0; i < 30; i++) {
      game.update(0.05);
    }
    expect(game.isNight, isTrue);
    expect(game.session!.party, hasLength(4),
        reason: 'the curse splits the party at night');
  });

  test('traps catch a party that stands still', () async {
    final game = KnightLoreGame(
      config: const KnightLoreGameConfig(daySeconds: 1000, autoCycle: false),
      bundle: TestAssetBundle(),
    );
    addTearDown(game.dispose);
    await game.onLoad();

    // Stand the sabreman on the corridor spikes and let the clock run.
    game.session!.enterRoom(KlRooms.corridor);
    final spikes = game.session!.room.triggers
        .firstWhere((trigger) => trigger.id == 'spikes_1');
    game.session!.leader.position = spikes.position.clone();
    final days = game.session!.curse.daysLeft;

    for (var i = 0; i < 200; i++) {
      game.update(1 / 60);
      if (game.session!.lastHazardOutcome == HazardOutcome.hurt) break;
    }

    expect(game.session!.lastHazardOutcome, HazardOutcome.hurt);
    expect(game.session!.lastHazardId, 'spikes_1');
    expect(game.session!.curse.daysLeft, days - 1);
    expect(game.message, contains('day is gone'));
  });
}
