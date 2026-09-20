// World loader for Head over Heels - loads world graph from JSON.

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:headoverheels/features/gameplay/room/room_graph.dart';
import 'package:vector_math/vector_math.dart';

/// Loads the world graph from assets/levels/world.json.
Future<WorldGraph> loadWorldGraph() async {
  final jsonString = await rootBundle.loadString('assets/levels/world.json');
  final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

  final roomsJson = jsonMap['rooms'] as Map<String, dynamic>;
  final rooms = <String, RoomDefinition>{};

  for (final entry in roomsJson.entries) {
    final roomJson = entry.value as Map<String, dynamic>;
    rooms[entry.key] = _parseRoomDefinition(roomJson);
  }

  final startRoomStr = jsonMap['startRoom'] as String;
  final startRoom = RoomId(startRoomStr);

  return WorldGraph(rooms: rooms, startRoom: startRoom);
}

RoomDefinition _parseRoomDefinition(Map<String, dynamic> json) {
  final exitsJson = json['exits'] as List<dynamic>? ?? [];
  final triggersJson = json['triggers'] as List<dynamic>? ?? [];

  final exits = exitsJson.map<RoomExit>((e) => _parseRoomExit(e as Map<String, dynamic>)).toList();
  final triggers = triggersJson.map<TriggerZone>((t) => _parseTriggerZone(t as Map<String, dynamic>)).toList();

  final spawnPointJson = json['spawnPoint'] as Map<String, dynamic>;
  final spawnPoint = Vector3(
    (spawnPointJson['x'] as num).toDouble(),
    (spawnPointJson['y'] as num).toDouble(),
    (spawnPointJson['z'] as num).toDouble(),
  );

  return RoomDefinition(
    id: RoomId(json['file'] as String? ?? ''),
    theme: json['theme'] as String,
    tmxFile: 'assets/levels/rooms/${json['file'] as String}',
    exits: exits,
    triggers: triggers,
    spawnPoint: spawnPoint,
    properties: Map<String, dynamic>.from(json['properties'] as Map? ?? {}),
  );
}

RoomExit _parseRoomExit(Map<String, dynamic> json) {
  return RoomExit(
    direction: ExitDirection.values.byName(json['direction'] as String),
    targetRoom: RoomId(json['room'] as String),
    targetEntrance: json['entrance'] as String,
    isLocked: json['isLocked'] as bool? ?? false,
    keyId: json['keyId'] as String?,
    oneWay: json['oneWay'] as bool? ?? false,
  );
}

TriggerZone _parseTriggerZone(Map<String, dynamic> json) {
  final positionJson = json['position'] as Map<String, dynamic>;
  final sizeJson = json['size'] as Map<String, dynamic>;

  final position = Vector3(
    (positionJson['x'] as num).toDouble(),
    (positionJson['y'] as num).toDouble(),
    (positionJson['z'] as num?)?.toDouble() ?? 0.0,
  );

  final size = Vector2(
    (sizeJson['width'] as num).toDouble(),
    (sizeJson['height'] as num).toDouble(),
  );

  TriggerType type;
  switch (json['type'] as String) {
    case 'door':
      type = TriggerType.door;
      break;
    case 'teleport':
      type = TriggerType.teleport;
      break;
    case 'ladderUp':
      type = TriggerType.ladderUp;
      break;
    case 'ladderDown':
      type = TriggerType.ladderDown;
      break;
    case 'conveyor':
      type = TriggerType.conveyor;
      break;
    case 'switch':
      type = TriggerType.switchTrigger;
      break;
    case 'bag':
      type = TriggerType.bag;
      break;
    case 'key':
      type = TriggerType.key;
      break;
    case 'crown':
      type = TriggerType.crown;
      break;
    case 'spring':
      type = TriggerType.springItem;
      break;
    case 'hushPuppy':
      type = TriggerType.hushPuppy;
      break;
    case 'monster':
      type = TriggerType.monster;
      break;
    case 'guardian':
      type = TriggerType.guardian;
      break;
    default:
      type = TriggerType.switchTrigger;
  }

  RoomExit? exit;
  if (json['exit'] != null) {
    exit = _parseRoomExit(json['exit'] as Map<String, dynamic>);
  }

  return TriggerZone(
    id: json['id'] as String,
    type: type,
    position: position,
    size: size,
    exit: exit,
    targetLevel: json['targetLevel'] as int?,
    conveyorDirection: json['conveyorDirection'] != null
        ? ExitDirection.values.byName(json['conveyorDirection'] as String)
        : null,
    conveyorSpeed: (json['conveyorSpeed'] as num?)?.toDouble(),
    properties: Map<String, dynamic>.from(json['properties'] as Map? ?? {}),
  );
}