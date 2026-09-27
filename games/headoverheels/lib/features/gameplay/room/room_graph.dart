// Room graph and world navigation for Head over Heels.

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vector_math/vector_math.dart';
import 'package:headoverheels/utils/json_converters.dart';

part 'room_graph.freezed.dart';
part 'room_graph.g.dart';

/// Unique identifier for a room.
@freezed
abstract class RoomId with _$RoomId {
  const factory RoomId(String value) = _RoomId;

  // Castle Blacktooth rooms
  static const RoomId castleStart = RoomId('castle_start');
  static const RoomId castleCell = RoomId('castle_cell');
  static const RoomId castleHall = RoomId('castle_hall');
  static const RoomId castleMarket = RoomId('castle_market');
  static const RoomId castleTeleport = RoomId('castle_teleport');

  // Moonbase rooms
  static const RoomId moonbaseHq = RoomId('moonbase_hq');
  static const RoomId moonbaseStation1 = RoomId('moonbase_station_1');
  static const RoomId moonbaseStation2 = RoomId('moonbase_station_2');
  static const RoomId moonbaseStation3 = RoomId('moonbase_station_3');

  // Egyptus rooms
  static const RoomId egyptusEntrance = RoomId('egyptus_entrance');
  static const RoomId egyptusPyramid1 = RoomId('egyptus_pyramid_1');
  static const RoomId egyptusPyramid2 = RoomId('egyptus_pyramid_2');
  static const RoomId egyptusTomb = RoomId('egyptus_tomb');

  // Penitentiary rooms
  static const RoomId penitentiaryEntrance = RoomId('penitentiary_entrance');
  static const RoomId penitentiaryCellBlock = RoomId('penitentiary_cell_block');
  static const RoomId penitentiaryThePit = RoomId('penitentiary_the_pit');

  // Safari rooms
  static const RoomId safariEntrance = RoomId('safari_entrance');
  static const RoomId safariJungle1 = RoomId('safari_jungle_1');
  static const RoomId safariFort = RoomId('safari_fort');

  // Book World rooms
  static const RoomId bookworldEntrance = RoomId('bookworld_entrance');
  static const RoomId bookworldLibrary1 = RoomId('bookworld_library_1');
  static const RoomId bookworldLibrary2 = RoomId('bookworld_library_2');

  // Blacktooth Castle (final)
  static const RoomId blacktoothCastle = RoomId('blacktooth_castle');
  static const RoomId blacktoothThrone = RoomId('blacktooth_throne');

  @override
  String toString() => value;
}

/// Direction for room exits.
enum ExitDirection {
  north,
  south,
  east,
  west,
  up, // Teleport up
  down, // Teleport down
}

/// Room exit definition.
@freezed
abstract class RoomExit with _$RoomExit {
  const factory RoomExit({
    required ExitDirection direction,
    @RoomIdConverter() required RoomId targetRoom,
    required String targetEntrance, // Named entrance in target room
    required bool isLocked,
    required String? keyId, // If locked, key required
    required bool oneWay, // If true, cannot return same way
  }) = _RoomExit;

  factory RoomExit.fromJson(Map<String, dynamic> json) =>
      _$RoomExitFromJson(json);
}

/// Trigger type for room transitions.
enum TriggerType {
  door,
  teleport,
  ladderUp,
  ladderDown,
  conveyor,
  switchTrigger,
  bag,
  key,
  crown,
  springItem,
  hushPuppy,
  monster,
  guardian,
}

/// Trigger zone for room transitions.
@freezed
abstract class TriggerZone with _$TriggerZone {
  const factory TriggerZone({
    required String id,
    required TriggerType type,
    @Vector3Converter()
    required Vector3 position, // Grid position (tile coordinates)
    @Vector2Converter() required Vector2 size, // Size in tiles (width, height)
    // For doors/teleports
    RoomExit? exit,
    // For ladders
    int? targetLevel, // Z-level to move to
    // For conveyors
    ExitDirection? conveyorDirection,
    double? conveyorSpeed,
    // For items/monsters/special
    Map<String, dynamic>? properties,
  }) = _TriggerZone;

  factory TriggerZone.fromJson(Map<String, dynamic> json) =>
      _$TriggerZoneFromJson(json);
}

/// Room definition with all static data.
@freezed
abstract class RoomDefinition with _$RoomDefinition {
  const factory RoomDefinition({
    @RoomIdConverter() required RoomId id,
    required String theme, // Tileset theme: castle, egyptus, etc.
    required String tmxFile, // TMX filename (relative to assets/levels/rooms/)
    required List<RoomExit> exits,
    required List<TriggerZone> triggers,
    @Vector3Converter() required Vector3 spawnPoint, // Default player spawn
    required Map<String, dynamic> properties, // Custom properties
  }) = _RoomDefinition;

  factory RoomDefinition.fromJson(Map<String, dynamic> json) =>
      _$RoomDefinitionFromJson(json);
}

/// World graph connecting all rooms.
@freezed
abstract class WorldGraph with _$WorldGraph {
  const factory WorldGraph({
    required Map<String, RoomDefinition> rooms,
    @RoomIdConverter() required RoomId startRoom,
  }) = _WorldGraph;

  factory WorldGraph.fromJson(Map<String, dynamic> json) =>
      _$WorldGraphFromJson(json);
}

/// Extension methods for WorldGraph.
extension WorldGraphExtension on WorldGraph {
  /// Get the rooms map with RoomId keys.
  Map<RoomId, RoomDefinition> get roomsById =>
      rooms.map((k, v) => MapEntry(RoomId(k), v));

  /// Get room definition by ID.
  RoomDefinition? getRoom(RoomId id) => rooms[id.value];

  /// Get all rooms in a theme/planet.
  List<RoomDefinition> getRoomsByTheme(String theme) =>
      rooms.values.where((r) => r.theme == theme).toList();

  /// Find path between rooms (simple BFS for now).
  List<RoomId>? findPath(RoomId from, RoomId to) {
    if (from == to) return [from];
    final queue = <List<RoomId>>[
      [from],
    ];
    final visited = <RoomId>{from};

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final current = path.last;

      if (current == to) return path;

      final room = rooms[current.value];
      if (room == null) continue;

      for (final exit in room.exits) {
        if (!visited.contains(exit.targetRoom)) {
          visited.add(exit.targetRoom);
          queue.add([...path, exit.targetRoom]);
        }
      }
    }
    return null;
  }

  /// Get exit from room in direction.
  RoomExit? getExit(RoomId roomId, ExitDirection direction) {
    final room = rooms[roomId.value];
    if (room == null) return null;
    for (final exit in room.exits) {
      if (exit.direction == direction) return exit;
    }
    return null;
  }
}

/// Runtime state for a room (dynamic elements).
@freezed
abstract class RoomState with _$RoomState {
  const factory RoomState({
    @RoomIdConverter() required RoomId id,
    required Set<String> collectedItems, // Items picked up in this room
    required Set<String> activatedSwitches, // Switches toggled
    required Set<String> eatenFish, // Reincarnation fish consumed
    required Map<String, dynamic> customFlags, // Arbitrary state
    required bool isCleared, // All puzzles solved
  }) = _RoomState;

  factory RoomState.initial(RoomId id) => RoomState(
    id: id,
    collectedItems: {},
    activatedSwitches: {},
    eatenFish: {},
    customFlags: {},
    isCleared: false,
  );

  factory RoomState.fromJson(Map<String, dynamic> json) =>
      _$RoomStateFromJson(json);
}
