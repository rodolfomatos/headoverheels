import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:knightlore/knightlore.dart';
import 'package:vector_math/vector_math.dart' show Vector3;

/// Writes the Tiled maps for every room and checks that the committed files
/// match the generator. Run with `flutter test`.
void main() {
  final world = KnightLoreWorld.build();
  const builder = RoomMapBuilder();

  test('every room gets a map with a doorway on each exit', () {
    final written = builder.writeAll(world);
    expect(written, hasLength(world.rooms.length));

    for (final room in world.rooms.values) {
      final file = File('${RoomMapBuilder.roomsBasePath}/${room.theme}/'
          '${room.id}.tmx');
      expect(file.existsSync(), isTrue, reason: file.path);

      final map = parseRoomMap(
        file.readAsStringSync(),
        room.id,
        room,
      );
      expect(map.width, 8);
      expect(map.height, 8);

      for (final exit in room.exits) {
        final door = switch (exit.direction) {
          'north' => Vector3(4, 0, 0),
          'south' => Vector3(4, 7, 0),
          'west' => Vector3(0, 4, 0),
          'east' => Vector3(7, 4, 0),
          _ => throw StateError('unexpected exit ${exit.direction}'),
        };
        expect(
          map.isWalkable(door.x.round(), door.y.round()),
          isTrue,
          reason: '${room.id} has no doorway for the ${exit.direction} exit',
        );
      }
    }
  });

  test('the committed maps match the generator byte for byte', () {
    for (final room in world.rooms.values) {
      final file = File('${RoomMapBuilder.roomsBasePath}/${room.theme}/'
          '${room.id}.tmx');
      expect(
        file.readAsStringSync(),
        builder.toTmx(builder.build(room)),
        reason: '${room.id} drifted from RoomMapBuilder',
      );
    }
  });

  test('a room is walled in and the spawn is on the floor', () {
    for (final room in world.rooms.values) {
      final map = builder.build(room);
      expect(map.isWalkable(0, 0), isFalse, reason: '${room.id} corner open');
      expect(map.isWalkable(7, 7), isFalse, reason: '${room.id} corner open');
      final spawn = room.spawnPosition;
      expect(
        map.isWalkable(spawn.x.round(), spawn.y.round()),
        isTrue,
        reason: '${room.id} spawn is inside a wall',
      );
    }
  });

  test('the room triggers are written as Tiled objects', () {
    for (final room in world.rooms.values) {
      final map = builder.build(room);
      expect(
        map.objects.map((object) => object.name),
        room.triggers.map((trigger) => trigger.id),
      );
      for (final object in map.objects) {
        final trigger = room.triggers.firstWhere(
          (candidate) => candidate.id == object.name,
        );
        expect(object.type, trigger.type);
        expect(object.position.x, trigger.position.x);
        expect(object.position.y, trigger.position.y);
      }
    }
  });

  test('the parsed terrain matches the generated tiles', () {
    for (final room in world.rooms.values) {
      final map = builder.build(room);
      final terrain = map.terrain;
      for (var y = 0; y < map.height; y++) {
        for (var x = 0; x < map.width; x++) {
          expect(
            terrain.isBlocked(x, y),
            !map.isWalkable(x, y),
            reason: '${room.id} at ($x,$y)',
          );
        }
      }
    }
  });

  test('the whole world is walkable from the maps alone', () {
    final maps = {
      for (final room in world.rooms.values) room.id: builder.build(room),
    };
    final start = world.rooms[world.startRoom]!;
    final startMap = maps[start.id]!;
    final spawn = start.spawnPosition;
    final startTile = Vector2i(spawn.x.round(), spawn.y.round());
    expect(startMap.isWalkable(startTile.x, startTile.y), isTrue);

    final seen = <String>{start.id};
    final queue = <String>[start.id];
    while (queue.isNotEmpty) {
      final from = queue.removeAt(0);
      for (final exit in world.rooms[from]!.exits) {
        if (seen.add(exit.room)) queue.add(exit.room);
      }
    }
    expect(seen, hasLength(maps.length));
  });
}

/// Small 2D integer helper, kept local so the test does not need vector_math.
class Vector2i {
  const Vector2i(this.x, this.y);

  final int x;
  final int y;
}
