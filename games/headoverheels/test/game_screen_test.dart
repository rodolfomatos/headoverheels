import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:headoverheels/features/gameplay/game.dart';
import 'package:headoverheels/features/gameplay/room/room_graph.dart';
import 'package:headoverheels/features/gameplay/room/world_loader.dart';
import 'package:headoverheels/features/ui/screens/game_screen.dart';

/// Proves the game screen shows the game.
///
/// The screen used to return a container with the words "Game Canvas (Flame
/// GameWidget goes here)", and the game was never constructed at all: the
/// provider that built it threw whenever the world had not arrived yet, and
/// nothing read it. These tests are about that, and about the loader, because a
/// screen showing a placeholder and a screen showing nothing fail in the same way
/// to a player's eye.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget screenWith(ProviderContainer container) => UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: GameScreen()),
  );

  /// A container whose world arrives when [gate] completes, or immediately.
  ProviderContainer containerWith({
    Completer<WorldGraph>? gate,
    Object? error,
  }) {
    final container = ProviderContainer(
      overrides: [
        worldGraphProvider.overrideWith((ref) {
          if (error != null) throw error;
          if (gate != null) return gate.future;
          return Future<WorldGraph>.value(_smallWorld());
        }),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  void useWindow(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('the screen says it is loading until the world arrives', (
    tester,
  ) async {
    useWindow(tester);
    final gate = Completer<WorldGraph>();

    await tester.pumpWidget(screenWith(containerWith(gate: gate)));
    await tester.pump();

    expect(find.byKey(const Key('game-loading')), findsOneWidget);
    expect(find.byKey(const Key('game-canvas')), findsNothing);
    expect(
      find.textContaining('Game Canvas'),
      findsNothing,
      reason: 'the placeholder must not come back',
    );

    // The world turns up, and the game takes its place. The real world, so the
    // real room map and the real sprites are what load.
    gate.complete(await loadWorldGraph());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('game-canvas')), findsOneWidget);
  });

  testWidgets('the world arrives and the game is on the screen', (
    tester,
  ) async {
    useWindow(tester);

    await tester.pumpWidget(screenWith(containerWith()));
    await tester.pump();

    expect(find.byKey(const Key('game-canvas')), findsOneWidget);
    expect(find.byType(GameWidget<HeadOverHeelsGame>), findsOneWidget);
  });

  testWidgets('the game is built once, not on every rebuild', (tester) async {
    useWindow(tester);
    final container = containerWith();

    await tester.pumpWidget(screenWith(container));
    await tester.pumpAndSettle();
    final first = tester
        .widget<GameWidget<HeadOverHeelsGame>>(
          find.byType(GameWidget<HeadOverHeelsGame>),
        )
        .game;

    // A rebuild, as a resize or a state change would cause.
    await tester.pump(const Duration(milliseconds: 100));
    final second = tester
        .widget<GameWidget<HeadOverHeelsGame>>(
          find.byType(GameWidget<HeadOverHeelsGame>),
        )
        .game;

    expect(
      second,
      same(first),
      reason: 'a new game would throw away the party and every sprite',
    );
  });

  testWidgets('a world that will not load says so', (tester) async {
    useWindow(tester);
    final container = containerWith(
      error: StateError('world.json is not there'),
    );

    await tester.pumpWidget(screenWith(container));
    await tester.pump();

    expect(find.byKey(const Key('game-error')), findsOneWidget);
    expect(find.textContaining('world.json is not there'), findsOneWidget);
  });

  test('the throwing game provider is gone', () {
    // It threw when the world had not loaded, which is a crash waiting for a
    // cold start. If the name comes back this fails.
    final source = File('lib/features/gameplay/game.dart').readAsStringSync();
    expect(source.contains('final gameProvider'), isFalse);
  });
}

/// A world small enough to build in a test, with the shape the loader produces.
WorldGraph _smallWorld() {
  const id = RoomId('castle_room_1');
  return WorldGraph(
    rooms: {
      'castle_room_1': RoomDefinition(
        id: id,
        theme: 'castle',
        tmxFile: 'castle_room_1.tmx',
        exits: const [],
        triggers: const [],
        spawnPoint: Vector3(2, 2, 0),
        properties: const {'planet': 'castle'},
      ),
    },
    startRoom: id,
  );
}

/// Kept so the imports the world model needs stay honest.
typedef Unused = Uint8List;
