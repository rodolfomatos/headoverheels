import 'package:iso_core/iso_core.dart';
import 'package:knightlore/knightlore.dart';
import 'package:vector_math/vector_math.dart' show Vector3;

/// Test support: route finding over a room.
///
/// The party cannot pass a wall or a ball, so a room is only usable if there
/// is a route from the spawn to each of its doors. Periodic traps do not block
/// permanently, so they are ignored here and waited out while walking.
class RoomRoutes {
  const RoomRoutes._();

  static Set<String> _blockers(RoomInfo room, RoomTerrain terrain) {
    final blocked = <String>{};
    for (var y = 0; y < terrain.height; y++) {
      for (var x = 0; x < terrain.width; x++) {
        if (terrain.isBlocked(x, y)) blocked.add('$x,$y');
      }
    }
    for (final hazard in HazardField.forRoom(room).hazards) {
      if (hazard.isBlocking) {
        blocked.add(
          '${hazard.cell.x.round()},${hazard.cell.y.round()}',
        );
      }
    }
    return blocked;
  }

  /// The cells from [from] to [to] inclusive, or empty when there is no route.
  static List<Vector3> find(
    RoomInfo room,
    RoomTerrain terrain,
    Vector3 from,
    Vector3 to,
  ) {
    final blocked = _blockers(room, terrain);
    final startKey = '${from.x.round()},${from.y.round()}';
    final goalKey = '${to.x.round()},${to.y.round()}';
    final cameFrom = <String, Vector3?>{startKey: null};
    final queue = <Vector3>[from];

    while (queue.isNotEmpty) {
      final cell = queue.removeAt(0);
      final cellKey = '${cell.x.round()},${cell.y.round()}';
      if (cellKey == goalKey) {
        final path = <Vector3>[];
        Vector3? walk = cell;
        while (walk != null) {
          path.add(walk);
          walk = cameFrom['${walk.x.round()},${walk.y.round()}'];
        }
        return path.reversed.toList();
      }
      for (final facing in Facing.values) {
        if (facing.dx == 0 && facing.dy == 0) continue;
        final next = Vector3(
          cell.x + facing.dx,
          cell.y + facing.dy,
          cell.z,
        );
        final key = '${next.x.round()},${next.y.round()}';
        if (cameFrom.containsKey(key) || blocked.contains(key)) continue;
        cameFrom[key] = cell;
        queue.add(next);
      }
    }
    return const [];
  }

  /// The tile a room's exit in [direction] starts from.
  static Vector3 doorTile(RoomExit exit) => switch (exit.direction) {
        'north' => Vector3(4, 0, 0),
        'south' => Vector3(4, 7, 0),
        'west' => Vector3(0, 4, 0),
        _ => Vector3(7, 4, 0),
      };

  /// Whether every door of the room can be walked to from its spawn.
  static bool isTraversable(
    RoomInfo room,
    RoomTerrain terrain,
  ) {
    for (final exit in room.exits) {
      if (find(room, terrain, room.spawnPosition, doorTile(exit)).isEmpty) {
        return false;
      }
    }
    return true;
  }
}
