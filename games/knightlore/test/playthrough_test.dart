import 'package:flutter_test/flutter_test.dart';
import 'package:iso_core/iso_core.dart';
import 'package:knightlore/knightlore.dart';
import 'package:vector_math/vector_math.dart' show Vector3;

WorldGraph _world() => KnightLoreWorld.build();

Map<String, RoomTerrain> _terrain() => {
      for (final room in _world().rooms.values) room.id: RoomTerrain.open(8, 8),
    };

RoomSession _session() => RoomSession(world: _world(), terrain: _terrain());

/// Walks the party to the tile below [trigger] and acts, the way a player
/// standing in front of a chest would.
/// Finds the container that holds [itemId] anywhere in the world.
({String room, RoomTrigger trigger}) _containerHolding(String itemId) {
  for (final room in _world().rooms.values) {
    for (final trigger in room.triggers) {
      if (trigger.type != 'chest' && trigger.type != 'statue') continue;
      final properties = trigger.properties['properties'];
      final held = properties is Map ? properties['itemId'] : null;
      if (held == itemId) return (room: room.id, trigger: trigger);
    }
  }
  throw StateError('nothing holds $itemId');
}

InteractOutcome _actOn(RoomSession session, RoomTrigger trigger) {
  session.leader.position =
      Vector3(trigger.position.x, trigger.position.y + 1, 0);
  session.leader.facing = Facing.north;
  return session.interact();
}

void main() {
  group('the game can be finished', () {
    test('every container in the world holds a catalogue item', () {
      for (final room in _world().rooms.values) {
        for (final trigger in room.triggers) {
          if (trigger.type != 'chest' && trigger.type != 'statue') continue;
          final properties = trigger.properties['properties'];
          final itemId = properties is Map ? properties['itemId'] : null;
          expect(
            itemId,
            isA<String>(),
            reason: '${room.id}/${trigger.id} has no itemId',
          );
          expect(
            KlItems.byId(itemId!),
            isNotNull,
            reason: '${trigger.id} holds unknown item $itemId',
          );
        }
      }
    });

    test('every ingredient is reachable in some container', () {
      final reachable = <String>{};
      for (final room in _world().rooms.values) {
        for (final trigger in room.triggers) {
          final properties = trigger.properties['properties'];
          final itemId = properties is Map ? properties['itemId'] : null;
          if (itemId is String) reachable.add(itemId);
        }
      }
      for (final ingredient in KlItems.ingredients) {
        expect(
          reachable,
          contains(ingredient),
          reason: '$ingredient cannot be found anywhere',
        );
      }
    });

    test('every key that a locked door needs can be carried', () {
      final items = KlItems.all.map((item) => item.id).toSet();
      for (final room in _world().rooms.values) {
        for (final exit in room.exits) {
          if (!exit.isLocked) continue;
          expect(
            items,
            contains(exit.keyId),
            reason: '${room.id} needs the unknown key ${exit.keyId}',
          );
        }
      }
    });

    test('a full playthrough lifts the curse, one ingredient at a time', () {
      final session = _session();
      final wizard = _world()
          .getRoom(KlRooms.laboratory)!
          .triggers
          .firstWhere((trigger) => trigger.type == 'wizard');
      final cauldron = _world()
          .getRoom(KlRooms.laboratory)!
          .triggers
          .firstWhere((trigger) => trigger.type == 'cauldron');

      for (var trip = 0; trip < KlItems.ingredients.length; trip++) {
        // The wizard names what the cauldron wants next.
        session.enterRoom(KlRooms.laboratory);
        expect(_actOn(session, wizard), InteractOutcome.wizardSpoke);
        final wanted = session.curse.demandedIngredient!;
        expect(wanted, KlItems.ingredients[trip]);

        // Go and find it, open whatever holds it and take it.
        final source = _containerHolding(wanted);
        session.enterRoom(source.room);
        expect(
          _actOn(session, source.trigger),
          InteractOutcome.chestOpened,
          reason: '$wanted was in ${source.trigger.id} and would not open',
        );
        expect(session.interact(), InteractOutcome.pickedUp);

        // Back to the cauldron with it.
        session.enterRoom(KlRooms.laboratory);
        expect(_actOn(session, cauldron), InteractOutcome.ingredientAccepted);
        expect(
          session.inventory.items.whereType<String>(),
          isNot(contains(wanted)),
          reason: 'the cauldron should have taken $wanted',
        );
      }

      expect(session.isWon, isTrue);
      expect(session.curse.ingredientsLeft, 0);
    });

    test('the six ingredients never all have to fit in the bag', () {
      // One trip at a time means the party only ever carries what the cauldron
      // asked for, so the sixteen slots are never the bottleneck.
      final totalContainers = _world()
          .rooms
          .values
          .expand((room) => room.triggers)
          .where(
            (trigger) => trigger.type == 'chest' || trigger.type == 'statue',
          )
          .length;
      expect(totalContainers, greaterThan(KlItems.ingredients.length));
      expect(Inventory.defaultSlotCount, greaterThanOrEqualTo(8));
    });

    test('the wizard asks for ingredients in a stable order', () {
      final session = _session();
      final wizard = _world()
          .getRoom(KlRooms.laboratory)!
          .triggers
          .firstWhere((trigger) => trigger.type == 'wizard');
      final cauldron = _world()
          .getRoom(KlRooms.laboratory)!
          .triggers
          .firstWhere((trigger) => trigger.type == 'cauldron');

      final asked = <String>[];
      for (var trip = 0; trip < 3; trip++) {
        session.enterRoom(KlRooms.laboratory);
        _actOn(session, wizard);
        final wanted = session.curse.demandedIngredient!;
        asked.add(wanted);
        session.inventory.pickUp(wanted);
        _actOn(session, cauldron);
      }
      expect(asked, KlItems.ingredients.take(3).toList());
    });

    test('the mine door opens with the golden key and not before', () {
      final session = _session();
      final corridor = _world().getRoom(KlRooms.corridor)!;
      final locked = corridor.exits.firstWhere((exit) => exit.isLocked);
      expect(locked.keyId, 'golden_key');

      session.enterRoom(KlRooms.corridor);
      for (var step = 0; step < 8; step++) {
        if (session.step(Facing.west) != MoveOutcome.moved) break;
      }
      expect(session.step(Facing.west), MoveOutcome.refused);

      session.inventory.pickUp('golden_key');
      expect(session.step(Facing.west), MoveOutcome.changedRoom);
      expect(session.roomId, locked.room);
    });
  });
}
