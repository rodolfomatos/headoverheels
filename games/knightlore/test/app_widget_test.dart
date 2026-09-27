import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightlore/knightlore.dart';

import 'test_asset_bundle.dart';

void main() {
  late KnightLoreGame loadedGame;

  setUp(() async {
    loadedGame = KnightLoreGame(
      config: const KnightLoreGameConfig(daySeconds: 1000, autoCycle: false),
      bundle: TestAssetBundle(),
    );
    await loadedGame.onLoad();
  });

  tearDown(() => loadedGame.dispose());
  // The full asset loading path is covered by game_smoke_test.dart, which boots
  // the same KnightLoreGame from disk. This test covers the widget layer: the
  // HUD renders and the keyboard reaches the game without exceptions.
  testWidgets('the app renders the hud and forwards keys to the game', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Loading decodes images, which is real async work, so it happens inside
    // runAsync: futures started in the fake clock never complete.
    late KnightLoreGame game;
    await tester.runAsync(() async {
      game = KnightLoreGame(
        config: const KnightLoreGameConfig(daySeconds: 1000, autoCycle: false),
        bundle: TestAssetBundle(),
      );
      await game.onLoad();
    });
    addTearDown(game.dispose);
    expect(game.assetsReady, isTrue, reason: '${game.error}');

    await tester.pumpWidget(
      KnightLoreApp(
        config: const KnightLoreGameConfig(daySeconds: 1000, autoCycle: false),
        game: game,
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // The game opens on the title screen.
    expect(find.text('KNIGHT LORE'), findsOneWidget);
    expect(find.textContaining('press space to begin'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('arrows / wasd walk'), findsOneWidget);
    expect(find.textContaining('1-9 cast'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsWidgets);

    // Pause and the status scroll both have their own screens.
    await tester.sendKeyEvent(LogicalKeyboardKey.keyI);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('STATUS SCROLL'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyI);
    await tester.pump(const Duration(milliseconds: 50));

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Paused'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 50));

    for (final key in [
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.keyF,
    ]) {
      await tester.sendKeyEvent(key);
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull, reason: '$key broke the game');
    }
  });
}
