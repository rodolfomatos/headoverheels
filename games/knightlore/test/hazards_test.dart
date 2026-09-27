import 'package:flutter_test/flutter_test.dart';
import 'package:iso_core/iso_core.dart';
import 'package:knightlore/knightlore.dart';
import 'package:vector_math/vector_math.dart' show Vector3;

import 'support/room_routes.dart';

WorldGraph _world() => KnightLoreWorld.build();

Map<String, RoomTerrain> _terrain() => {
      for (final room in _world().rooms.values) room.id: RoomTerrain.open(8, 8),
    };

RoomSession _session({RoomInfo? room}) {
  final session = RoomSession(world: _world(), terrain: _terrain());
  if (room != null) session.enterRoom(room.id);
  return session;
}

RoomTrigger _trigger(String roomId, String triggerId) => _world()
    .getRoom(roomId)!
    .triggers
    .firstWhere((trigger) => trigger.id == triggerId);

void main() {
  group('hazards', () {
    test('a ball is always in the way and never hurts', () {
      final hazard = Hazard.fromTrigger(_trigger(KlRooms.greatHall, 'ball_2'));
      expect(hazard.kind, HazardKind.ball);
      for (final tick in [0, 5, 40, 400]) {
        expect(hazard.isOut(tick), isTrue);
        expect(hazard.isLethal(tick), isFalse);
      }
    });

    test('spikes come out on a cycle', () {
      final hazard = Hazard.fromTrigger(_trigger(KlRooms.corridor, 'spikes_1'));
      expect(hazard.kind, HazardKind.spikes);
      expect(hazard.period, 16);
      expect(hazard.activeFor, 8);
      expect(hazard.isOut(0), isTrue);
      expect(hazard.isOut(7), isTrue);
      expect(hazard.isOut(8), isFalse);
      expect(hazard.isOut(15), isFalse);
      expect(hazard.isOut(16), isTrue);
    });

    test('a phase shifts the cycle', () {
      final hazard =
          Hazard.fromTrigger(_trigger(KlRooms.mineVault, 'spikes_2'));
      expect(hazard.phase, 7);
      expect(hazard.isOut(0), isFalse, reason: 'still retracted at tick 0');
      expect(hazard.isOut(9), isTrue);
    });

    test('a ball blocks the way, spikes catch instead', () {
      final corridor = _world().getRoom(KlRooms.corridor)!;
      final field = HazardField.forRoom(corridor);
      final spikes = _trigger(KlRooms.corridor, 'spikes_1').position;
      final ball = _trigger(KlRooms.greatHall, 'ball_2').position;

      expect(field.blocksAt(spikes, 0), isFalse,
          reason: 'spikes do not block, they catch');
      expect(field.hitAt(spikes, 0)?.id, 'spikes_1');
      expect(field.hitAt(spikes, 9), isNull, reason: 'retracted at tick 9');
      expect(
          HazardField.forRoom(_world().getRoom(KlRooms.greatHall)!)
              .blocksAt(ball, 0),
          isTrue);
      expect(field.blocksAt(Vector3(7, 7, 0), 0), isFalse);
    });

    test('walking onto spikes costs a day and puts the party back', () {
      final room = _world().getRoom(KlRooms.corridor)!;
      final session = _session(room: room);
      final spikes = _trigger(KlRooms.corridor, 'spikes_1');
      session.leader.position =
          Vector3(spikes.position.x, spikes.position.y + 1, 0);
      final days = session.curse.daysLeft;

      // At tick zero the spikes are out, so stepping in is allowed and hurts.
      expect(session.step(Facing.north), MoveOutcome.moved);
      expect(session.lastHazardOutcome, HazardOutcome.hurt);
      expect(session.lastHazardId, 'spikes_1');
      expect(session.curse.daysLeft, days - 1);
      expect(session.leader.position, room.spawnPosition);
    });

    test('a ball is a wall, not a death', () {
      final room = _world().getRoom(KlRooms.greatHall)!;
      final session = _session(room: room);
      final ball = _trigger(KlRooms.greatHall, 'ball_2');
      session.leader.position =
          Vector3(ball.position.x, ball.position.y + 1, 0);
      final days = session.curse.daysLeft;

      expect(session.step(Facing.north), MoveOutcome.blocked);
      expect(session.lastHazardOutcome, HazardOutcome.blocked);
      expect(session.curse.daysLeft, days);
    });

    test('a demon only catches the party while it is up', () {
      final room = _world().getRoom(KlRooms.mineShaft)!;
      final session = _session(room: room);
      final demon = _trigger(KlRooms.mineShaft, 'demon_1');
      final days = session.curse.daysLeft;

      // Find a tick where the demon is up, then walk into it.
      var tick = 0;
      while (session.hazards.hitAt(demon.position, tick) == null) {
        tick++;
      }
      session.advanceTick(tick - session.tick);
      session.leader.position =
          Vector3(demon.position.x, demon.position.y + 1, 0);
      expect(session.step(Facing.north), MoveOutcome.moved);
      expect(session.lastHazardOutcome, HazardOutcome.hurt);
      expect(session.lastHazardId, 'demon_1');
      expect(session.curse.daysLeft, days - 1);
      expect(session.leader.position, room.spawnPosition);
    });

    test('every hazard in the world is declared with a sane cycle', () {
      var count = 0;
      for (final room in _world().rooms.values) {
        for (final hazard in HazardField.forRoom(room).hazards) {
          count++;
          expect(hazard.id, isNotEmpty);
          expect(hazard.covers(hazard.cell, 0) || hazard.period > 0, isTrue);
          if (hazard.kind != HazardKind.ball) {
            expect(hazard.period, greaterThan(0), reason: hazard.id);
            expect(hazard.activeFor, greaterThan(0), reason: hazard.id);
            expect(
              hazard.activeFor,
              lessThan(hazard.period),
              reason: '${hazard.id} would never retract',
            );
          }
        }
      }
      expect(count, greaterThanOrEqualTo(5));
    });

    test('no room traps its own spawn or its only doorway', () {
      for (final room in _world().rooms.values) {
        final field = HazardField.forRoom(room);
        for (var tick = 0; tick < 40; tick++) {
          expect(
            field.blocksAt(room.spawnPosition, tick),
            isFalse,
            reason: '${room.id} traps its spawn at tick $tick',
          );
        }
        for (final exit in room.exits) {
          final door = switch (exit.direction) {
            'north' => Vector3(4, 0, 0),
            'south' => Vector3(4, 7, 0),
            'west' => Vector3(0, 4, 0),
            _ => Vector3(7, 4, 0),
          };
          for (var tick = 0; tick < 40; tick++) {
            expect(
              field.blocksAt(door, tick),
              isFalse,
              reason: '${room.id} blocks its ${exit.direction} door at $tick',
            );
          }
        }
        // The spawn must also never be lethal: a party cannot be reset into a
        // trap and die again.
        for (var tick = 0; tick < 40; tick++) {
          expect(
            field.hitAt(room.spawnPosition, tick),
            isNull,
            reason: '${room.id} spawn is lethal at $tick',
          );
        }
      }
    });

    test('every room can still be crossed with the traps in place', () {
      final builder = RoomMapBuilder();
      for (final room in _world().rooms.values) {
        final terrain = builder.build(room).terrain;
        expect(
          RoomRoutes.isTraversable(room, terrain),
          isTrue,
          reason: '${room.id} cannot be crossed any more',
        );
      }
    });

    test('a trap that comes out under a standing party costs a day', () {
      final room = _world().getRoom(KlRooms.corridor)!;
      final session = _session(room: room);
      final spikes = _trigger(KlRooms.corridor, 'spikes_1');
      session.leader.position = spikes.position.clone();
      final days = session.curse.daysLeft;

      // Walk the clock until the spikes come out, exactly as the game does.
      var caught = false;
      for (var tick = 0; tick < 40 && !caught; tick++) {
        session.advanceTick();
        caught = session.lastHazardOutcome == HazardOutcome.hurt;
      }

      expect(caught, isTrue);
      expect(session.lastHazardId, 'spikes_1');
      expect(session.curse.daysLeft, days - 1);
      expect(session.leader.position, room.spawnPosition);
    });

    test('a trap fires once per visit, not once per tick', () {
      final room = _world().getRoom(KlRooms.corridor)!;
      final session = _session(room: room);
      final spikes = _trigger(KlRooms.corridor, 'spikes_1');
      final days = session.curse.daysLeft;

      // Walk onto the tile and then stand there through a full cycle.
      var tick = 0;
      while (session.hazards.hitAt(spikes.position, tick) != null) {
        tick++;
      }
      session.advanceTick(tick - session.tick);
      session.leader.position =
          Vector3(spikes.position.x, spikes.position.y + 1, 0);
      session.step(Facing.north);
      for (var i = 0; i < 32; i++) {
        session.advanceTick();
      }

      expect(
        session.curse.daysLeft,
        days - 1,
        reason: 'one visit to the spikes costs exactly one day',
      );
    });
  });
}
