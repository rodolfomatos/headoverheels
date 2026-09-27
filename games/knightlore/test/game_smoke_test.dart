import 'package:flutter_test/flutter_test.dart';
import 'package:knightlore/knightlore.dart';

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
  });

  test('the game responds to keys and to the day cycle', () async {
    final game = KnightLoreGame(
      config: const KnightLoreGameConfig(daySeconds: 2, autoCycle: true),
      bundle: TestAssetBundle(),
    );
    addTearDown(game.dispose);
    await game.onLoad();

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
}
