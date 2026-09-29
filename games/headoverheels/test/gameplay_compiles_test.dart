import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math.dart' show Vector2, Vector3;
import 'package:headoverheels/entities/character_state.dart';
import 'package:headoverheels/features/gameplay/entities/character_component.dart';
import 'package:headoverheels/features/gameplay/game.dart';
import 'package:headoverheels/features/gameplay/room/room_graph.dart';
import 'package:headoverheels/features/gameplay/room/world_loader.dart';
import 'package:headoverheels/features/gameplay/state/character_notifier.dart';
import 'package:headoverheels/features/gameplay/entities/dispensary_entity.dart';
import 'package:headoverheels/features/gameplay/entities/guardian_entity.dart';
import 'package:headoverheels/features/gameplay/room/room_component.dart';
import 'package:headoverheels/features/gameplay/entities/crown_entity.dart';
import 'package:headoverheels/features/gameplay/entities/entity_factory.dart';

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

  test('every guardian says which planet it guards', () async {
    // The throne room of a planet opens for the crowns of that planet. A guardian
    // whose trigger does not say which planet it is would have to count every
    // crown in the game, and that is how it was: four crowns from one planet
    // opened all five.
    final graph = await loadWorldGraph();
    final guardians = <TriggerZone>[];
    for (final room in graph.rooms.values) {
      for (final trigger in room.triggers) {
        if (trigger.type == TriggerType.guardian) guardians.add(trigger);
      }
    }

    expect(guardians, isNotEmpty, reason: 'the world has no guardians at all');
    for (final guardian in guardians) {
      expect(
        guardian.properties?['planetId'],
        isNotNull,
        reason: '${guardian.id} does not say which planet it guards',
      );
    }
  });

  test(
    'a crown built from the world belongs to the planet of its room',
    () async {
      // The data was right and the game was wrong: the factory read a `planet`
      // key that no trigger has and fell back to `castle`, so every crown in the
      // game was Blacktooth's. No test built an entity out of the real world, so
      // the four crowns that open a throne room opened the castle one and the
      // other four planets could never be finished.
      final graph = await loadWorldGraph();
      var crowns = 0;
      for (final room in graph.rooms.values) {
        for (final trigger in room.triggers) {
          if (trigger.type != TriggerType.crown) continue;
          crowns++;
          final entity = EntityFactory.create(trigger, room.id);
          expect(
            entity,
            isA<CrownEntity>(),
            reason: '${trigger.id} did not build a crown',
          );
          expect(
            (entity! as CrownEntity).planetId,
            room.theme,
            reason: '${trigger.id} in ${room.id} is not ${room.theme}\'s',
          );
        }
      }
      expect(crowns, greaterThan(0), reason: 'the world has no crowns at all');
    },
  );

  test('a guardian guards the planet its room is on', () async {
    // The planet of a room is its theme, and the crowns in it agree: a throne
    // room asking for crowns of another planet is not a throne room.
    final graph = await loadWorldGraph();
    for (final room in graph.rooms.values) {
      final crownPlanets = room.triggers
          .where((trigger) => trigger.type == TriggerType.crown)
          .map((trigger) => trigger.properties?['planetId'])
          .whereType<String>()
          .toSet();
      for (final trigger in room.triggers) {
        if (trigger.type != TriggerType.guardian) continue;
        final planet = trigger.properties?['planetId'];
        expect(
          planet,
          room.theme,
          reason: '${trigger.id} in ${room.id} guards another planet',
        );
        if (crownPlanets.isNotEmpty) {
          expect(crownPlanets, {
            planet,
          }, reason: 'the crowns in ${room.id} are not of its planet');
        }
      }
    }
  });

  group('the notifications the puzzle entities send', () {
    late ProviderContainer container;
    late HeadOverHeelsGame game;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
      game = HeadOverHeelsGame(container.read(_refProvider), _emptyGraph());
    });

    test('a crown is counted against its own planet only', () {
      // There is no total on purpose. A guardian asks for the crowns of the
      // planet whose throne room it guards, and a total let a party beat a
      // guardian it had never earned: four crowns from anywhere opened every
      // throne room, and the four a throne room asked for went uncounted
      // anywhere else.
      game.collectCrown('egyptus');
      game.collectCrown('egyptus');
      game.collectCrown('safari');

      expect(game.crownsFor('egyptus'), 2);
      expect(game.crownsFor('safari'), 1);
      expect(game.crownsFor('bookworld'), 0, reason: 'a planet with no crowns');
    });

    test('a guardian counts only the crowns of its own planet', () async {
      // Four crowns of the wrong planet used to be enough: the guardian added
      // up everything the party had ever collected.
      for (var count = 0; count < GuardianEntity.requiredCrowns; count++) {
        game.collectCrown('safari');
      }
      final wrongPlanet = await _guardian(game, container, planetId: 'egyptus');
      wrongPlanet.onInteract(_character(container));

      expect(
        game.guardianDefeated,
        isFalse,
        reason: 'four crowns from another planet opened this throne room',
      );
    });

    test('a guardian opens for the crowns of its planet', () async {
      for (var count = 0; count < GuardianEntity.requiredCrowns; count++) {
        game.collectCrown('egyptus');
      }
      final guardian = await _guardian(game, container, planetId: 'egyptus');
      guardian.onInteract(_character(container));

      expect(game.guardianDefeated, isTrue);
    });

    test('a guardian with three crowns of its planet still blocks', () async {
      for (var count = 0; count < GuardianEntity.requiredCrowns - 1; count++) {
        game.collectCrown('egyptus');
      }
      final guardian = await _guardian(game, container, planetId: 'egyptus');
      guardian.onInteract(_character(container));

      expect(
        game.guardianDefeated,
        isFalse,
        reason: 'three crowns are not four',
      );
    });

    test('the bag is worn, and it leaves the hand free', () async {
      // The bag used to be recorded as the hand's item, so the one slot a
      // character carries in held a bag nobody could use, and the key on the
      // floor could not be picked up after it.
      final notifier = container.read(heelsProvider.notifier);
      notifier.pickUp(const CarriedItem.key('key_1'));
      game.onBagCollected(_character(container, CharacterType.heels));

      expect(
        notifier.state.carriedItem,
        const CarriedItem.key('key_1'),
        reason: 'wearing the bag took the hand',
      );
      expect(notifier.state.hasBag, isTrue);
    });

    test('the bag carries four, and the fifth stays behind', () async {
      // The magic bag carries four. Anything more and there is nowhere to put it:
      // the world has no dispensary, which is T061.
      final notifier = container.read(heelsProvider.notifier);
      game.onBagCollected(_character(container, CharacterType.heels));

      for (var slot = 0; slot < bagCapacity; slot++) {
        expect(
          notifier.stow(CarriedItem.other('item_$slot')),
          isTrue,
          reason: 'slot $slot of the bag should take its item',
        );
      }
      expect(notifier.state.bagItems, hasLength(bagCapacity));
      expect(
        notifier.stow(const CarriedItem.other('item_overflow')),
        isFalse,
        reason: 'the bag carried five',
      );
      expect(notifier.state.bagItems, hasLength(bagCapacity));
    });

    test('a character with no bag cannot stow anything', () async {
      final notifier = container.read(heelsProvider.notifier);
      expect(notifier.stow(const CarriedItem.other('item_0')), isFalse);
      expect(notifier.state.bagItems, isEmpty);
    });

    test('the dispensary empties the bag onto the floor', () async {
      // The bag fills and stays full: there was nothing in the world to empty it,
      // and no trigger type for a place that did. The dispensary is that place.
      final notifier = container.read(heelsProvider.notifier);
      final heels = _character(container, CharacterType.heels);
      game.onBagCollected(heels);
      notifier.stow(const CarriedItem.key('key_a'));
      notifier.stow(const CarriedItem.other('spring'));

      final room = await _loadedRoom(container);
      final dispensary = DispensaryEntity(
        id: 'dispensary_test',
        triggerZone: TriggerZone(
          id: 'dispensary_test',
          type: TriggerType.dispensary,
          position: Vector3(1, 1, 0),
          size: Vector2(1, 1),
          properties: const {'planetId': 'castle'},
        ),
      );
      await room.add(dispensary);
      final before = room.entities.length;

      dispensary.onInteract(heels);

      expect(notifier.bagContents, isEmpty, reason: 'the bag is still full');
      expect(notifier.wearsBag, isTrue, reason: 'the bag was taken off');
      expect(
        room.entities.length,
        before + 2,
        reason: 'the items are on the floor, not in the bag',
      );
    });

    test('a character with no bag, or an empty one, changes nothing', () async {
      final room = await _loadedRoom(container);
      final dispensary = DispensaryEntity(
        id: 'dispensary_test',
        triggerZone: TriggerZone(
          id: 'dispensary_test',
          type: TriggerType.dispensary,
          position: Vector3(1, 1, 0),
          size: Vector2(1, 1),
          properties: const {'planetId': 'castle'},
        ),
      );
      await room.add(dispensary);
      final before = room.entities.length;

      final heels = _character(container, CharacterType.heels);
      dispensary.onInteract(heels);
      expect(
        room.entities.length,
        before,
        reason: 'a character with no bag emptied one',
      );

      final notifier = container.read(heelsProvider.notifier);
      game.onBagCollected(heels);
      notifier.stow(const CarriedItem.key('key_a'));
      dispensary.onInteract(heels);
      expect(
        room.entities.length,
        before + 1,
        reason: 'an item in a bag comes out',
      );
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

/// The world's start room, loaded on its own.
///
/// The room, not the game: `HeadOverHeelsGame.onLoad` starts the planet's music,
/// and audioplayers has no implementation in a plain test, so a test about a
/// dispensary should not be asking for one.
Future<RoomComponent> _loadedRoom(ProviderContainer container) async {
  final world = await loadWorldGraph();
  // Any real room: the dispensary needs a floor to put things on, not the start
  // room in particular. Looking the start room up by key is its own puzzle.
  final definition = world.rooms.values.first;
  final room = RoomComponent(roomId: definition.id, definition: definition);
  // The game is built and never loaded: an entity that needs the game, like a
  // dispensary, has to find one, and the game's own load starts the planet's
  // music, which a plain test has no plugin for.
  // The test's own container, so the game and the test read and write the same
  // character state rather than two copies of it.
  final game = HeadOverHeelsGame(container.read(_refProvider), world);
  addTearDown(game.dispose);
  await game.add(room);
  return room;
}

/// A guardian built the way the factory builds one, so the test goes through the
/// data rather than around it, and attached to the game: an entity that is not
/// in the tree cannot find the game it asks about the crowns.
Future<GuardianEntity> _guardian(
  HeadOverHeelsGame game,
  ProviderContainer container, {
  required String planetId,
}) async {
  final trigger = TriggerZone(
    id: 'guardian_test',
    type: TriggerType.guardian,
    position: Vector3(1, 1, 0),
    size: Vector2(1, 1),
    properties: {'planetId': planetId, 'patrolPoints': ''},
  );
  final guardian =
      EntityFactory.create(trigger, const RoomId('test_room'))!
          as GuardianEntity;
  await game.add(guardian);
  return guardian;
}

CharacterComponent _character(
  ProviderContainer container, [
  CharacterType type = CharacterType.head,
]) => CharacterComponent(type: type, ref: container.read(_refProvider));

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
