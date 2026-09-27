import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../isometric/isometric.dart';

abstract interface class WorldDataSource {
  Future<String> readString(String key);
}

class AssetBundleWorldDataSource implements WorldDataSource {
  const AssetBundleWorldDataSource(this.bundle);

  final AssetBundle bundle;

  @override
  Future<String> readString(String key) => bundle.loadString(key);
}

class WorldGraph {
  WorldGraph({
    required this.rooms,
    required this.startRoom,
    required this.groups,
  });

  factory WorldGraph.fromJson(Map<String, dynamic> json) {
    final rawRooms = json['rooms'];
    final rooms = <String, RoomInfo>{};

    if (rawRooms is Map) {
      for (final entry in rawRooms.entries) {
        if (entry.value is Map) {
          rooms[entry.key.toString()] = RoomInfo.fromJson(
            entry.key.toString(),
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      }
    }

    final rawGroups = json['planets'] ?? json['groups'];
    final groups = rawGroups is List
        ? rawGroups
              .whereType<Map>()
              .map(
                (value) =>
                    WorldGroup.fromJson(Map<String, dynamic>.from(value)),
              )
              .toList()
        : <WorldGroup>[];

    return WorldGraph(
      rooms: rooms,
      startRoom: json['startRoom'] as String? ?? '',
      groups: groups,
    );
  }

  static Future<WorldGraph> load(
    String key, {
    required WorldDataSource source,
  }) async {
    final content = await source.readString(key);
    return WorldGraph.fromJson(json.decode(content) as Map<String, dynamic>);
  }

  final Map<String, RoomInfo> rooms;
  final String startRoom;
  final List<WorldGroup> groups;

  RoomInfo? getRoom(String roomId) => rooms[roomId];

  List<RoomInfo> getRoomsByTheme(String theme) {
    return rooms.values.where((room) => room.theme == theme).toList();
  }

  WorldGraph copyWith({
    Map<String, RoomInfo>? rooms,
    String? startRoom,
    List<WorldGroup>? groups,
  }) {
    return WorldGraph(
      rooms: rooms ?? this.rooms,
      startRoom: startRoom ?? this.startRoom,
      groups: groups ?? this.groups,
    );
  }

  WorldGraph upsertRoom(RoomInfo room) {
    return copyWith(rooms: {...rooms, room.id: room});
  }

  WorldGraph removeRoom(String roomId) {
    return copyWith(rooms: {...rooms}..remove(roomId));
  }

  Map<String, dynamic> toJson() => {
    'startRoom': startRoom,
    'rooms': {
      for (final entry in rooms.entries) entry.key: entry.value.toJson(),
    },
    if (groups.isNotEmpty)
      'planets': [for (final group in groups) group.toJson()],
  };

  String toJsonString({bool pretty = true}) {
    const encoder = JsonEncoder.withIndent('  ');
    return '${encoder.convert(toJson())}\n';
  }
}

class RoomInfo {
  const RoomInfo({
    required this.id,
    required this.file,
    required this.theme,
    required this.spawnPosition,
    required this.exits,
    required this.triggers,
  });

  factory RoomInfo.fromJson(String id, Map<String, dynamic> json) {
    final rawSpawn = json['spawnPoint'];
    final spawn = rawSpawn is Map
        ? Vector3(
            (rawSpawn['x'] as num?)?.toDouble() ?? 0,
            (rawSpawn['y'] as num?)?.toDouble() ?? 0,
            (rawSpawn['z'] as num?)?.toDouble() ?? 0,
          )
        : Vector3.zero();

    return RoomInfo(
      id: id,
      file: json['file'] as String? ?? '',
      theme: json['theme'] as String? ?? 'default',
      spawnPosition: spawn,
      exits: _asMapList(
        json['exits'],
      ).map(RoomExit.fromJson).toList(growable: false),
      triggers: _asMapList(
        json['triggers'],
      ).map(RoomTrigger.fromJson).toList(growable: false),
    );
  }

  final String id;
  final String file;
  final String theme;
  final Vector3 spawnPosition;
  final List<RoomExit> exits;
  final List<RoomTrigger> triggers;

  RoomInfo copyWith({
    String? file,
    String? theme,
    Vector3? spawnPosition,
    List<RoomExit>? exits,
    List<RoomTrigger>? triggers,
  }) {
    return RoomInfo(
      id: id,
      file: file ?? this.file,
      theme: theme ?? this.theme,
      spawnPosition: spawnPosition ?? this.spawnPosition,
      exits: exits ?? this.exits,
      triggers: triggers ?? this.triggers,
    );
  }

  Map<String, dynamic> toJson() => {
    'file': file,
    'theme': theme,
    'spawnPoint': {
      'x': spawnPosition.x,
      'y': spawnPosition.y,
      'z': spawnPosition.z,
    },
    'exits': [for (final exit in exits) exit.toJson()],
    'triggers': [for (final trigger in triggers) trigger.toJson()],
  };
}

class RoomExit {
  const RoomExit({
    required this.direction,
    required this.room,
    required this.entrance,
    this.isLocked = false,
    this.keyId,
    this.oneWay = false,
  });

  factory RoomExit.fromJson(Map<String, dynamic> json) {
    return RoomExit(
      direction: json['direction'] as String? ?? '',
      room: json['room'] as String? ?? '',
      entrance: json['entrance'] as String? ?? '',
      isLocked: json['isLocked'] as bool? ?? false,
      keyId: json['keyId'] as String?,
      oneWay: json['oneWay'] as bool? ?? false,
    );
  }

  final String direction;
  final String room;
  final String entrance;
  final bool isLocked;
  final String? keyId;
  final bool oneWay;

  RoomExit copyWith({
    String? direction,
    String? room,
    String? entrance,
    bool? isLocked,
    String? keyId,
    bool clearKeyId = false,
    bool? oneWay,
  }) {
    return RoomExit(
      direction: direction ?? this.direction,
      room: room ?? this.room,
      entrance: entrance ?? this.entrance,
      isLocked: isLocked ?? this.isLocked,
      keyId: clearKeyId ? null : (keyId ?? this.keyId),
      oneWay: oneWay ?? this.oneWay,
    );
  }

  Map<String, dynamic> toJson() => {
    'direction': direction,
    'room': room,
    'entrance': entrance,
    'isLocked': isLocked,
    'keyId': keyId,
    'oneWay': oneWay,
  };
}

class RoomTrigger {
  const RoomTrigger({
    required this.id,
    required this.type,
    required this.position,
    required this.size,
    required this.properties,
  });

  factory RoomTrigger.fromJson(Map<String, dynamic> json) {
    final rawPosition = json['position'];
    final rawSize = json['size'];
    final position = rawPosition is Map
        ? Vector3(
            (rawPosition['x'] as num?)?.toDouble() ?? 0,
            (rawPosition['y'] as num?)?.toDouble() ?? 0,
            (rawPosition['z'] as num?)?.toDouble() ?? 0,
          )
        : Vector3.zero();
    final size = rawSize is Map
        ? Vector2(
            (rawSize['width'] as num?)?.toDouble() ?? 0,
            (rawSize['height'] as num?)?.toDouble() ?? 0,
          )
        : Vector2.zero();

    return RoomTrigger(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      position: position,
      size: size,
      properties: Map<String, dynamic>.from(json),
    );
  }

  final String id;
  final String type;
  final Vector3 position;
  final Vector2 size;
  final Map<String, dynamic> properties;

  RoomTrigger copyWith({
    String? type,
    Vector3? position,
    Vector2? size,
    Map<String, dynamic>? properties,
  }) {
    return RoomTrigger(
      id: id,
      type: type ?? this.type,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
    );
  }

  Map<String, dynamic> toJson() {
    final json = Map<String, dynamic>.from(properties)
      ..remove('id')
      ..remove('type')
      ..remove('position')
      ..remove('size');
    return {
      'id': id,
      'type': type,
      'position': {'x': position.x, 'y': position.y, 'z': position.z},
      'size': {'width': size.x, 'height': size.y},
      ...json,
    };
  }
}

class WorldGroup {
  const WorldGroup({
    required this.id,
    required this.name,
    required this.properties,
  });

  factory WorldGroup.fromJson(Map<String, dynamic> json) {
    return WorldGroup(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      properties: Map<String, dynamic>.from(json),
    );
  }

  final String id;
  final String name;
  final Map<String, dynamic> properties;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, ...properties};
}

class RoomObject {
  const RoomObject({
    required this.id,
    required this.name,
    required this.type,
    required this.pixelPosition,
    required this.pixelSize,
    required this.properties,
  });

  final int id;
  final String name;
  final String type;
  final Vector2 pixelPosition;
  final Vector2 pixelSize;
  final Map<String, dynamic> properties;
}

class RoomComponent extends Component {
  RoomComponent({required this.roomId, required this.tmxKey, Vector2? tileSize})
    : tileSize = tileSize ?? Vector2(kTileWidth, kTileHeight);

  final String roomId;
  final String tmxKey;
  final Vector2 tileSize;

  TiledComponent? _tiledComponent;
  final List<RoomObject> objects = [];

  RenderableTiledMap? get tileMap => _tiledComponent?.tileMap;

  @override
  Future<void> onLoad() async {
    final tiled = await TiledComponent.load(tmxKey, tileSize);
    _tiledComponent = tiled;
    objects.addAll(_readObjects(tiled.tileMap));
    await add(tiled);
    await super.onLoad();
  }

  List<RoomObject> _readObjects(RenderableTiledMap map) {
    final result = <RoomObject>[];
    for (final layer in map.map.layers.whereType<ObjectGroup>()) {
      for (final object in layer.objects) {
        result.add(
          RoomObject(
            id: object.id,
            name: object.name,
            type: object.type,
            pixelPosition: Vector2(object.x, object.y),
            pixelSize: Vector2(object.width, object.height),
            properties: {
              for (final property in object.properties)
                property.name: property.value,
            },
          ),
        );
      }
    }
    return result;
  }

  Gid? getTileAt(String layerName, int x, int y) {
    final map = tileMap;
    if (map == null) return null;
    final layer = map.getLayer<TileLayer>(layerName);
    final layerId = layer?.id;
    if (layerId == null) return null;
    return map.getTileData(layerId: layerId, x: x, y: y);
  }
}

class WorldLoader {
  WorldLoader({
    required this.worldGraph,
    required this.roomsBasePath,
    required Component parent,
  }) : _parent = parent;

  final WorldGraph worldGraph;
  final String roomsBasePath;
  final Component _parent;

  RoomComponent? _currentRoom;
  String? _currentRoomId;

  RoomComponent? get currentRoom => _currentRoom;
  String? get currentRoomId => _currentRoomId;

  Future<RoomComponent> loadRoom(String roomId) async {
    final room = worldGraph.getRoom(roomId);
    if (room == null) {
      throw StateError('Unknown room: $roomId');
    }

    final previous = _currentRoom;
    previous?.removeFromParent();

    final key = p.posix.join(roomsBasePath, room.file);
    final component = RoomComponent(roomId: roomId, tmxKey: key);
    final addResult = _parent.add(component);
    if (addResult is Future<void>) {
      await addResult;
    }

    _currentRoom = component;
    _currentRoomId = roomId;
    return component;
  }

  bool canTransition(String direction) {
    final room = _currentRoomId == null
        ? null
        : worldGraph.getRoom(_currentRoomId!);
    return room?.exits.any((exit) => exit.direction == direction) ?? false;
  }

  Future<RoomComponent?> transition(String direction) async {
    final room = _currentRoomId == null
        ? null
        : worldGraph.getRoom(_currentRoomId!);
    if (room == null) return null;

    for (final exit in room.exits) {
      if (exit.direction == direction && exit.room.isNotEmpty) {
        return loadRoom(exit.room);
      }
    }
    return null;
  }
}

List<Map<String, dynamic>> _asMapList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(entry))
      .toList(growable: false);
}
