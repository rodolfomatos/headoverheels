import 'package:flutter_test/flutter_test.dart';
import 'package:iso_core/iso_core.dart';
import 'package:knightlore/knightlore.dart';
import 'package:vector_math/vector_math.dart' show Vector3;

WorldGraph _world() => KnightLoreWorld.build();

Map<String, RoomTerrain> _terrain({RoomTerrain? forGatehouse}) {
  final world = _world();
  return {
    for (final room in world.rooms.values)
      room.id: forGatehouse != null && room.id == KlRooms.gatehouse
          ? forGatehouse
          : RoomTerrain.open(8, 8),
  };
}

RoomSession _session({
  RoomTerrain? gatehouse,
  CurseState? curse,
  List<String> initialItems = const [],
}) =>
    RoomSession(
      world: _world(),
      terrain: _terrain(forGatehouse: gatehouse),
      curse: curse,
      initialItems: initialItems,
    );

/// Walks the party in one direction until the room changes, the way is refused
/// or the party is stuck. Leaving a room is what happens when it steps off the
/// edge, so the tests walk instead of teleporting to the doorway.
MoveOutcome _walkUntilRoomChanges(RoomSession session, Facing direction) {
  var outcome = MoveOutcome.moved;
  for (var i = 0; i < 24 && outcome == MoveOutcome.moved; i++) {
    outcome = session.step(direction);
  }
  return outcome;
}

void main() {
  group('terrain', () {
    test('reads walls from rows and blocks the outside', () {
      final terrain = RoomTerrain.fromRows([
        '###',
        '#.#',
        '###',
      ]);
      expect(terrain.width, 3);
      expect(terrain.height, 3);
      expect(terrain.isBlocked(0, 0), isTrue);
      expect(terrain.isBlocked(1, 1), isFalse);
      expect(terrain.isBlocked(3, 1), isTrue);
      expect(terrain.isBlocked(1, -1), isTrue);
    });

    test('rejects a grid that does not match its rows', () {
      expect(
        () => RoomTerrain.fromRows(['###', '##']),
        throwsArgumentError,
      );
      expect(() => RoomTerrain(2, 2, [true]), throwsArgumentError);
    });
  });

  group('session', () {
    test('starts in the gatehouse with the sabreman', () {
      final session = _session();
      expect(session.roomId, KlRooms.gatehouse);
      expect(session.party, hasLength(1));
      expect(session.leader.form, KnightClass.sabreman);
      expect(session.isSplit, isFalse);
      expect(session.terrain.width, 8);
    });

    test('walks one tile at a time and turns to face the step', () {
      final session = _session();
      final start = session.leader.position.clone();
      expect(session.step(Facing.east), MoveOutcome.moved);
      expect(session.leader.position.x, start.x + 1);
      expect(session.leader.position.y, start.y);
      expect(session.leader.facing, Facing.east);
    });

    test('walls stop the party', () {
      final session = _session(
        gatehouse: RoomTerrain.fromRows(const [
          '########',
          '#......#',
          '#.####.#',
          '#......#',
          '#......#',
          '#......#',
          '#......#',
          '########',
        ]),
      );
      // Row 2 holds a wall between columns 2 and 5; column 0 is the outer wall.
      session.enterRoom(KlRooms.gatehouse);
      session.leader.position = Vector3(3, 3, 0);

      expect(session.step(Facing.north), MoveOutcome.blocked);
      expect(session.leader.position, Vector3(3, 3, 0));

      expect(session.step(Facing.south), MoveOutcome.moved);
      expect(session.step(Facing.west), MoveOutcome.moved);
      expect(session.step(Facing.west), MoveOutcome.moved);
      expect(session.step(Facing.west), MoveOutcome.blocked);
      expect(session.leader.position, Vector3(1, 4, 0));
    });

    test('a corner with no exit refuses to leave the room', () {
      final session = _session();
      session.enterRoom(KlRooms.gatehouse);
      // The gatehouse only exits north and east.
      expect(
        _walkUntilRoomChanges(session, Facing.south),
        MoveOutcome.noExit,
      );
      expect(
        _walkUntilRoomChanges(session, Facing.west),
        MoveOutcome.noExit,
      );
      expect(session.roomId, KlRooms.gatehouse);
    });

    test('walking through an exit changes room and lands inside', () {
      final session = _session();
      session.enterRoom(KlRooms.gatehouse);
      session.placeItem('torch');
      expect(session.itemsHere, contains('torch'));

      expect(
        _walkUntilRoomChanges(session, Facing.north),
        MoveOutcome.changedRoom,
      );
      expect(session.roomId, KlRooms.greatHall);
      expect(session.terrain, isNotNull);
      expect(session.itemsHere, isEmpty, reason: 'items stay in the old room');
    });

    test('locked exits need the key in the inventory', () {
      final session = _session();
      session.enterRoom(KlRooms.corridor);
      expect(
        _walkUntilRoomChanges(session, Facing.west),
        MoveOutcome.refused,
      );
      expect(session.roomId, KlRooms.corridor);

      session.inventory.pickUp('jewel_key');
      expect(
        _walkUntilRoomChanges(session, Facing.west),
        MoveOutcome.changedRoom,
      );
      expect(session.roomId, KlRooms.mineEntrance);
    });

    test('a werewolf cannot use a doorway, the split knights need a spell', () {
      final session = _session();
      session.enterRoom(KlRooms.gatehouse);
      session.nightFalls();
      expect(session.curse.phase, CursePhase.werewolf);
      expect(
        _walkUntilRoomChanges(session, Facing.north),
        MoveOutcome.refused,
      );

      // A spell does not help the wolf: the curse has to split first.
      session.curse.spells.cast(SpellId.openDoor);
      expect(
        _walkUntilRoomChanges(session, Facing.north),
        MoveOutcome.refused,
      );

      session.splitParty();
      expect(session.party, hasLength(4));
      expect(
        _walkUntilRoomChanges(session, Facing.north),
        MoveOutcome.changedRoom,
      );
      expect(session.roomId, KlRooms.greatHall);
    });

    test('the split knights are refused without a spell', () {
      final session = _session();
      session.enterRoom(KlRooms.gatehouse);
      session.nightFalls();
      session.splitParty();
      expect(
        _walkUntilRoomChanges(session, Facing.north),
        MoveOutcome.refused,
      );
      expect(session.roomId, KlRooms.gatehouse);
    });

    test('every room can be reached by walking, not just by graph', () {
      final session = _session();
      // Carry the keys the world declares, so locked doors are walkable.
      for (final room in _world().rooms.values) {
        for (final exit in room.exits) {
          if (exit.isLocked && exit.keyId != null) {
            session.inventory.pickUp(exit.keyId!);
          }
        }
      }
      final visited = <String>{session.roomId};
      final queue = <String>[session.roomId];

      while (queue.isNotEmpty) {
        final from = queue.removeAt(0);
        session.enterRoom(from);
        for (final exit in session.room.exits) {
          session.enterRoom(from);
          final outcome = _walkUntilRoomChanges(
            session,
            facingForExit(exit.direction),
          );
          expect(
            outcome,
            anyOf(MoveOutcome.changedRoom, MoveOutcome.flipped),
            reason: 'exit ${exit.direction} from $from to ${exit.room}',
          );
          expect(session.roomId, exit.room);
          if (visited.add(session.roomId)) queue.add(session.roomId);
        }
      }

      expect(visited, hasLength(_world().rooms.length));
    });

    test('vertical flavour exits are doorways on the other edges', () {
      expect(exitNamesFor(Facing.north), {'north', 'up'});
      expect(exitNamesFor(Facing.south), {'south', 'down'});
      expect(exitNamesFor(Facing.east), {'east'});
      expect(facingForExit('down'), Facing.south);
      expect(facingForExit('up'), Facing.north);

      final session = _session();
      session.enterRoom(KlRooms.jungleEntrance);
      expect(
        _walkUntilRoomChanges(session, Facing.south),
        MoveOutcome.changedRoom,
      );
      expect(session.roomId, KlRooms.cauldronEntrance);

      session.enterRoom(KlRooms.cauldronEntrance);
      expect(
        _walkUntilRoomChanges(session, Facing.east),
        MoveOutcome.changedRoom,
      );
      expect(session.roomId, KlRooms.cauldronCave);
    });
  });

  group('interaction', () {
    test('picks up an item underfoot exactly once', () {
      final session = _session(initialItems: const ['diamond']);
      expect(session.itemUnderfoot, contains('diamond'));
      expect(session.interact(), InteractOutcome.pickedUp);
      expect(session.inventory.items, contains('diamond'));
      expect(session.interact(), isNot(InteractOutcome.pickedUp));
    });

    test('refuses to pick up when the inventory is full', () {
      final curse = CurseState();
      for (var i = 0; i < 16; i++) {
        curse.inventory.pickUp('filler_$i');
      }
      final session = RoomSession(
        world: _world(),
        terrain: _terrain(),
        curse: curse,
        initialItems: const ['diamond'],
      );
      expect(session.interact(), InteractOutcome.nothing);
      expect(
          session.inventory.items.where((item) => item == 'diamond'), isEmpty);
    });

    test('the wizard only speaks to the sabreman by day', () {
      final session = _session();
      session.enterRoom(KlRooms.laboratory);
      final wizard = session.room.triggers
          .firstWhere((trigger) => trigger.type == 'wizard');
      session.leader.position =
          Vector3(wizard.position.x, wizard.position.y + 1, 0);
      session.leader.facing = Facing.north;
      session.inventory.pickUp('diamond');
      expect(session.interact(), InteractOutcome.wizardSpoke);
      expect(
        session.curse.demandedIngredient,
        'pot_of_gold',
        reason: 'the wizard asks for the first ingredient still missing',
      );

      session.nightFalls();
      expect(session.interact(), InteractOutcome.wizardRefused);
    });

    test('the cauldron accepts the demanded ingredient only', () {
      final session = _session();
      session.enterRoom(KlRooms.laboratory);
      final cauldron = session.room.triggers
          .firstWhere((trigger) => trigger.type == 'cauldron');
      session.leader.position =
          Vector3(cauldron.position.x, cauldron.position.y + 1, 0);
      session.leader.facing = Facing.north;
      session.inventory.pickUp('diamond');
      session.curse.demandIngredient('chalice');
      expect(session.interact(), InteractOutcome.ingredientRefused);
      expect(session.curse.ingredientsLeft, 6);

      session.inventory.pickUp('chalice');
      expect(session.interact(), InteractOutcome.ingredientAccepted);
      expect(session.curse.ingredientsLeft, 5);
      expect(
        session.inventory.items.where((item) => item == 'chalice'),
        isEmpty,
      );
      expect(session.curse.demandedIngredient, isNull);
    });

    test('a cauldron with no demand refuses', () {
      final session = _session();
      session.enterRoom(KlRooms.laboratory);
      final cauldron = session.room.triggers
          .firstWhere((trigger) => trigger.type == 'cauldron');
      session.leader.position =
          Vector3(cauldron.position.x, cauldron.position.y + 1, 0);
      session.leader.facing = Facing.north;
      expect(session.interact(), InteractOutcome.ingredientRefused);
    });
  });

  group('split and filmation', () {
    test('the four knights appear in the same room and move together', () {
      final session = _session();
      session.nightFalls();
      session.curse.split();
      session.splitParty();

      expect(session.isSplit, isTrue);
      expect(session.party, hasLength(4));
      expect(session.party.map((k) => k.form), splitKnights);

      session.step(Facing.east);
      for (final knight in session.party) {
        expect(knight.position, session.leader.position);
      }
    });

    test('the four knights on four exits may flip the view', () {
      final session = _session();
      session.nightFalls();
      session.curse.split();
      session.splitParty();

      // Stack them on the four edge rows by hand: the party shares a position,
      // so drive the exits through the terrain edges instead.
      expect(session.canFlipHere, isFalse);

      final exits = {'north', 'south', 'east', 'west'};
      const rule = FilmRule();
      expect(
        rule.canFlip(
            knights: session.party.map((k) => k.form).toList(),
            occupiedExits: exits),
        isTrue,
      );
    });

    test('rejoining restores a single sabreman', () {
      final session = _session();
      session.nightFalls();
      session.curse.split();
      session.splitParty();
      session.rejoinParty();
      expect(session.party, hasLength(1));
      expect(session.leader.form, KnightClass.sabreman);
    });
  });

  group('day and night', () {
    test('the sundial counts down and ends the game', () {
      final session = _session();
      expect(session.curse.daysLeft, 40);
      session.advanceDay();
      expect(session.curse.daysLeft, 39);
    });

    test('dawn and night flip the phase', () {
      final session = _session();
      session.nightFalls();
      expect(session.curse.phase, CursePhase.werewolf);
      session.dawnBreaks();
      expect(session.curse.phase, CursePhase.daylight);
    });
  });

  group('chests and scrolls', () {
    test('a chest holds one catalogue item and empties once', () {
      final session = _session();
      session.enterRoom(KlRooms.gatehouse);
      final chest = session.room.triggers
          .firstWhere((trigger) => trigger.type == 'chest');
      expect(session.chestContents(chest.id), 'diamond');

      session.leader.position =
          Vector3(chest.position.x, chest.position.y + 1, 0);
      session.leader.facing = Facing.north;
      expect(session.interact(), InteractOutcome.chestOpened);
      expect(session.itemUnderfoot, contains('diamond'));
      expect(session.chestIsOpen(chest.id), isTrue);

      session.interact(); // picks the diamond up
      expect(session.interact(), InteractOutcome.chestEmpty);
    });

    test('the catalogue has six ingredients and six scrolls', () {
      expect(KlItems.ingredients, hasLength(6));
      expect(KlItems.all.where((item) => item.isScroll), hasLength(6));
      for (final id in KlItems.ingredients) {
        expect(KlItems.byId(id), isNotNull, reason: id);
      }
      for (final spell in SpellId.values) {
        expect(KlItems.scrollFor(spell), isNotNull, reason: spell.id);
      }
    });

    test('casting from a slot uses the scroll in that slot', () {
      final curse = CurseState();
      curse.inventory
        ..pickUp('diamond')
        ..pickUp('scroll_open_door');
      final session = RoomSession(
        world: _world(),
        terrain: _terrain(),
        curse: curse,
      );

      expect(session.castAtSlot(0), CastOutcome.notAScroll);
      expect(session.castAtSlot(1), CastOutcome.cast);
      expect(curse.spells.isActive(SpellId.openDoor), isTrue);
      expect(curse.spells.isActive(SpellId.shield), isFalse);
      expect(session.castAtSlot(9), CastOutcome.nothing);
    });

    test('a scroll survives being cast', () {
      final curse = CurseState()..inventory.pickUp('scroll_shield');
      RoomSession(world: _world(), terrain: _terrain(), curse: curse);
      final session = RoomSession(
        world: _world(),
        terrain: _terrain(),
        curse: curse,
      );
      expect(session.castAtSlot(0), CastOutcome.cast);
      expect(curse.inventory.items, contains('scroll_shield'));
    });

    test('the split knights can leave once a scroll is cast', () {
      final curse = CurseState()..inventory.pickUp('scroll_open_door');
      final session = RoomSession(
        world: _world(),
        terrain: _terrain(),
        curse: curse,
      );
      session.enterRoom(KlRooms.gatehouse);
      session.nightFalls();
      session.splitParty();

      expect(
        _walkUntilRoomChanges(session, Facing.north),
        MoveOutcome.refused,
      );
      expect(session.castAtSlot(0), CastOutcome.cast);
      expect(
        _walkUntilRoomChanges(session, Facing.north),
        MoveOutcome.changedRoom,
      );
      expect(session.roomId, KlRooms.greatHall);
    });

    test('the wizard never asks for something the party already holds', () {
      final curse = CurseState();
      final session = RoomSession(
        world: _world(),
        terrain: _terrain(),
        curse: curse,
      );
      session.enterRoom(KlRooms.laboratory);
      final wizard = session.room.triggers
          .firstWhere((trigger) => trigger.type == 'wizard');
      session.leader.position =
          Vector3(wizard.position.x, wizard.position.y + 1, 0);
      session.leader.facing = Facing.north;

      session.interact();
      final first = session.curse.demandedIngredient!;
      expect(curse.inventory.items.whereType<String>(), isNot(contains(first)));

      session.inventory.pickUp(first);
      session.interact();
      final second = session.curse.demandedIngredient!;
      expect(second, isNot(first));
      expect(
          curse.inventory.items.whereType<String>(), isNot(contains(second)));
    });
  });
}
