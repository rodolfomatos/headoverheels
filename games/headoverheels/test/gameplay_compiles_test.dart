import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math.dart' show Vector3;
import 'package:headoverheels/entities/character_state.dart';
import 'package:headoverheels/features/gameplay/entities/character_component.dart';
import 'package:headoverheels/features/gameplay/game.dart';
import 'package:headoverheels/features/gameplay/room/room_graph.dart';
import 'package:headoverheels/features/gameplay/room/world_loader.dart';
import 'package:headoverheels/features/gameplay/state/character_notifier.dart';

/// Compiles the gameplay layer and checks the notifications the puzzle
/// entities send.
///
/// This file exists as much for what it imports as for what it asserts. Ten
/// `// ignore: undefined_identifier` comments once sat over `gameRef`, which
/// does not exist anywhere: the analyzer was clean because those comments
/// silenced it, `flutter test` could not compile the layer, and no test imported
/// the entities so nobody noticed. A test that does nothing but import the
/// gameplay layer is what stops that from happening again.
void main() {
  // The world is loaded from the asset bundle, so the binding has to exist
  // before anything reads it.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the gameplay layer compiles, because this test imports it', () {
    // Nothing to assert: reaching this line is the assertion.
    expect(HeadOverHeelsGame, isNotNull);
    expect(CharacterComponent, isNotNull);
  });

  test('the world loads and has a start room', () async {
    final graph = await loadWorldGraph();
    expect(graph.rooms, isNotEmpty, reason: 'the world has no rooms');
    expect(graph.roomsById, isNotEmpty);
  });

  group('the notifications the puzzle entities send', () {
    late ProviderContainer container;
    late HeadOverHeelsGame game;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
      game = HeadOverHeelsGame(container.read(_refProvider), _emptyGraph());
    });

    test('a crown is counted, per planet and in total', () {
      expect(game.crownsCollected, 0);
      game.collectCrown('egyptus');
      game.collectCrown('egyptus');
      game.collectCrown('safari');

      expect(game.crownsFor('egyptus'), 2);
      expect(game.crownsFor('safari'), 1);
      expect(game.crownsFor('bookworld'), 0, reason: 'a planet with no crowns');
      expect(game.crownsCollected, 3);
    });

    test('the guardian reports itself beaten', () {
      expect(game.guardianDefeated, isFalse);
      game.onGuardianDefeated();
      expect(game.guardianDefeated, isTrue);
    });

    test('a picked up item reaches the character', () {
      final character = CharacterComponent(
        type: CharacterType.head,
        ref: container.read(_refProvider),
      );
      game.onItemPickedUp(character, const CarriedItem.key('gold_key'));

      expect(
        container.read(headProvider).carriedItem,
        const CarriedItem.key('gold_key'),
        reason: 'the key never reached the character',
      );
    });

    test('the bag is carried, even though it does nothing yet', () {
      final character = CharacterComponent(
        type: CharacterType.heels,
        ref: container.read(_refProvider),
      );
      game.onBagCollected(character);

      expect(
        container.read(heelsProvider).carriedItem,
        const CarriedItem.other('bag'),
        reason: 'T056: the bag has no effect, but it should not be lost',
      );
    });
  });

  group('a character holds one thing at a time', () {
    test('picking up replaces what was held', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(headProvider.notifier);

      notifier.pickUp(const CarriedItem.key('gold_key'));
      expect(
        container.read(headProvider).carriedItem,
        const CarriedItem.key('gold_key'),
      );

      notifier.pickUp(const CarriedItem.crown());
      expect(
        container.read(headProvider).carriedItem,
        const CarriedItem.crown(),
      );

      notifier.putDown();
      expect(
        container.read(headProvider).carriedItem,
        const CarriedItem.none(),
      );
    });
  });
}

/// A way to get hold of a [Ref] without a widget: the game wants one.
final _refProvider = Provider<Ref>((ref) => ref);

/// The notifications never read the world, so the tests hand the game a graph
/// with one empty room rather than loading a thousand.
WorldGraph _emptyGraph() {
  const id = RoomId('test_room');
  return WorldGraph(
    rooms: {
      'test_room': RoomDefinition(
        id: id,
        theme: 'castle',
        tmxFile: 'test_room.tmx',
        exits: const [],
        triggers: const [],
        spawnPoint: Vector3(1, 1, 0),
        properties: const {},
      ),
    },
    startRoom: id,
  );
}
