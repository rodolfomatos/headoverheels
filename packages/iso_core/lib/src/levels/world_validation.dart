import 'levels.dart';

enum WorldIssueSeverity { error, warning, info }

enum WorldIssueKind {
  missingStartRoom,
  unknownTarget,
  selfLoop,
  duplicateDirection,
  unreachable,
  deadEnd,
  missingFile,
  emptyTheme,
  triggerUnknownRoom,
  asymmetricExit,
  emptyGraph,
}

class WorldIssue {
  const WorldIssue({
    required this.kind,
    required this.severity,
    required this.roomId,
    required this.message,
    this.targetRoom,
  });

  final WorldIssueKind kind;
  final WorldIssueSeverity severity;
  final String roomId;
  final String? targetRoom;
  final String message;

  bool get isError => severity == WorldIssueSeverity.error;

  @override
  String toString() => '[${severity.name}] ${kind.name} $roomId: $message';
}

class WorldValidation {
  const WorldValidation(this.issues);

  final List<WorldIssue> issues;

  Iterable<WorldIssue> get errors =>
      issues.where((issue) => issue.severity == WorldIssueSeverity.error);

  Iterable<WorldIssue> get warnings =>
      issues.where((issue) => issue.severity == WorldIssueSeverity.warning);

  bool get isValid => errors.isEmpty;
}

WorldValidation validateWorld(WorldGraph graph) {
  final issues = <WorldIssue>[];

  void add(
    WorldIssueKind kind,
    WorldIssueSeverity severity,
    String roomId,
    String message, [
    String? targetRoom,
  ]) {
    issues.add(
      WorldIssue(
        kind: kind,
        severity: severity,
        roomId: roomId,
        targetRoom: targetRoom,
        message: message,
      ),
    );
  }

  if (graph.rooms.isEmpty) {
    add(
      WorldIssueKind.emptyGraph,
      WorldIssueSeverity.error,
      graph.startRoom,
      'The world graph has no rooms',
    );
    return WorldValidation(issues);
  }

  if (!graph.rooms.containsKey(graph.startRoom)) {
    add(
      WorldIssueKind.missingStartRoom,
      WorldIssueSeverity.error,
      graph.startRoom,
      'Start room is not defined in the graph',
    );
  }

  for (final room in graph.rooms.values) {
    if (room.file.isEmpty) {
      add(
        WorldIssueKind.missingFile,
        WorldIssueSeverity.error,
        room.id,
        'Room has no TMX file',
      );
    }
    if (room.theme.isEmpty) {
      add(
        WorldIssueKind.emptyTheme,
        WorldIssueSeverity.warning,
        room.id,
        'Room has no theme, tileset lookup will fall back',
      );
    }

    final seenDirections = <String, String>{};
    for (final exit in room.exits) {
      if (exit.direction.isEmpty) {
        add(
          WorldIssueKind.duplicateDirection,
          WorldIssueSeverity.error,
          room.id,
          'Exit to ${exit.room} has no direction',
          exit.room,
        );
        continue;
      }
      final previous = seenDirections[exit.direction];
      if (previous != null) {
        add(
          WorldIssueKind.duplicateDirection,
          WorldIssueSeverity.error,
          room.id,
          'Two exits share the ${exit.direction} direction '
          '($previous and ${exit.room})',
          exit.room,
        );
      }
      seenDirections[exit.direction] = exit.room;

      if (exit.room == room.id) {
        add(
          WorldIssueKind.selfLoop,
          WorldIssueSeverity.warning,
          room.id,
          'Exit points at its own room',
          exit.room,
        );
        continue;
      }

      final target = graph.rooms[exit.room];
      if (target == null) {
        add(
          WorldIssueKind.unknownTarget,
          WorldIssueSeverity.error,
          room.id,
          'Exit to unknown room "${exit.room}"',
          exit.room,
        );
        continue;
      }

      if (!exit.oneWay && !_hasExitBack(target, room.id)) {
        add(
          WorldIssueKind.asymmetricExit,
          WorldIssueSeverity.warning,
          room.id,
          'No way back from ${exit.room} to this room',
          exit.room,
        );
      }
    }

    if (room.exits.isEmpty && room.id != graph.startRoom) {
      add(
        WorldIssueKind.deadEnd,
        WorldIssueSeverity.info,
        room.id,
        'Room has no exits',
      );
    }

    for (final trigger in room.triggers) {
      final targetRoom = roomTargetOf(trigger);
      if (targetRoom != null && !graph.rooms.containsKey(targetRoom)) {
        add(
          WorldIssueKind.triggerUnknownRoom,
          WorldIssueSeverity.warning,
          room.id,
          'Trigger "${trigger.id}" targets unknown room "$targetRoom"',
          targetRoom,
        );
      }
    }
  }

  final reachable = _reachable(graph);
  for (final room in graph.rooms.keys) {
    if (!reachable.contains(room)) {
      add(
        WorldIssueKind.unreachable,
        WorldIssueSeverity.warning,
        room,
        'Room cannot be reached from ${graph.startRoom}',
      );
    }
  }

  return WorldValidation(issues);
}

/// Room a trigger points at, if any. Accepts both a top level `room` and the
/// nested `properties: {room: ...}` shape used by generated world files.
String? roomTargetOf(RoomTrigger trigger) {
  final direct = _asString(trigger.properties['room']);
  if (direct != null) return direct;
  final nested = trigger.properties['properties'];
  if (nested is Map) return _asString(nested['room']);
  return null;
}

/// Object/entity a trigger points at inside its own room, if any.
String? localTargetOf(RoomTrigger trigger) {
  final direct = _asString(trigger.properties['targetId']);
  if (direct != null) return direct;
  final nested = trigger.properties['properties'];
  if (nested is Map) return _asString(nested['targetId']);
  return null;
}

String? _asString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

bool _hasExitBack(RoomInfo room, String targetId) =>
    room.exits.any((exit) => exit.room == targetId);

Set<String> _reachable(WorldGraph graph) {
  final visited = <String>{};
  final start = graph.rooms[graph.startRoom];
  if (start == null) return visited;
  final queue = <String>[start.id];
  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    if (!visited.add(current)) continue;
    final room = graph.rooms[current];
    if (room == null) continue;
    for (final exit in room.exits) {
      if (!visited.contains(exit.room)) queue.add(exit.room);
    }
  }
  return visited;
}
