import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightlore/knightlore.dart';

void main() {
  // The full asset loading path is covered by game_smoke_test.dart, which boots
  // the same KnightLoreGame from disk. This test covers the widget layer: the
  // HUD renders and the keyboard reaches the game without exceptions.
  testWidgets('the app renders the hud and forwards keys to the game', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const KnightLoreApp(
        config: KnightLoreGameConfig(daySeconds: 1000, autoCycle: false),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.textContaining('arrows / wasd walk'), findsOneWidget);
    expect(find.text('day'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

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
