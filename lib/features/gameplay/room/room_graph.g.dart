// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_graph.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RoomExitImpl _$$RoomExitImplFromJson(Map<String, dynamic> json) =>
    _$RoomExitImpl(
      direction: $enumDecode(_$ExitDirectionEnumMap, json['direction']),
      targetRoom:
          const RoomIdConverter().fromJson(json['targetRoom'] as String),
      targetEntrance: json['targetEntrance'] as String,
      isLocked: json['isLocked'] as bool,
      keyId: json['keyId'] as String?,
      oneWay: json['oneWay'] as bool,
    );

Map<String, dynamic> _$$RoomExitImplToJson(_$RoomExitImpl instance) =>
    <String, dynamic>{
      'direction': _$ExitDirectionEnumMap[instance.direction]!,
      'targetRoom': const RoomIdConverter().toJson(instance.targetRoom),
      'targetEntrance': instance.targetEntrance,
      'isLocked': instance.isLocked,
      'keyId': instance.keyId,
      'oneWay': instance.oneWay,
    };

const _$ExitDirectionEnumMap = {
  ExitDirection.north: 'north',
  ExitDirection.south: 'south',
  ExitDirection.east: 'east',
  ExitDirection.west: 'west',
  ExitDirection.up: 'up',
  ExitDirection.down: 'down',
};

_$TriggerZoneImpl _$$TriggerZoneImplFromJson(Map<String, dynamic> json) =>
    _$TriggerZoneImpl(
      id: json['id'] as String,
      type: $enumDecode(_$TriggerTypeEnumMap, json['type']),
      position:
          const Vector3Converter().fromJson(json['position'] as List<double>),
      size: const Vector2Converter().fromJson(json['size'] as List<double>),
      exit: json['exit'] == null
          ? null
          : RoomExit.fromJson(json['exit'] as Map<String, dynamic>),
      targetLevel: (json['targetLevel'] as num?)?.toInt(),
      conveyorDirection: $enumDecodeNullable(
          _$ExitDirectionEnumMap, json['conveyorDirection']),
      conveyorSpeed: (json['conveyorSpeed'] as num?)?.toDouble(),
      properties: json['properties'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$TriggerZoneImplToJson(_$TriggerZoneImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$TriggerTypeEnumMap[instance.type]!,
      'position': const Vector3Converter().toJson(instance.position),
      'size': const Vector2Converter().toJson(instance.size),
      'exit': instance.exit,
      'targetLevel': instance.targetLevel,
      'conveyorDirection': _$ExitDirectionEnumMap[instance.conveyorDirection],
      'conveyorSpeed': instance.conveyorSpeed,
      'properties': instance.properties,
    };

const _$TriggerTypeEnumMap = {
  TriggerType.door: 'door',
  TriggerType.teleport: 'teleport',
  TriggerType.ladderUp: 'ladderUp',
  TriggerType.ladderDown: 'ladderDown',
  TriggerType.conveyor: 'conveyor',
  TriggerType.switchTrigger: 'switchTrigger',
  TriggerType.bag: 'bag',
  TriggerType.key: 'key',
  TriggerType.crown: 'crown',
  TriggerType.springItem: 'springItem',
  TriggerType.hushPuppy: 'hushPuppy',
  TriggerType.monster: 'monster',
  TriggerType.guardian: 'guardian',
};

_$RoomDefinitionImpl _$$RoomDefinitionImplFromJson(Map<String, dynamic> json) =>
    _$RoomDefinitionImpl(
      id: const RoomIdConverter().fromJson(json['id'] as String),
      theme: json['theme'] as String,
      tmxFile: json['tmxFile'] as String,
      exits: (json['exits'] as List<dynamic>)
          .map((e) => RoomExit.fromJson(e as Map<String, dynamic>))
          .toList(),
      triggers: (json['triggers'] as List<dynamic>)
          .map((e) => TriggerZone.fromJson(e as Map<String, dynamic>))
          .toList(),
      spawnPoint:
          const Vector3Converter().fromJson(json['spawnPoint'] as List<double>),
      properties: json['properties'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$$RoomDefinitionImplToJson(
        _$RoomDefinitionImpl instance) =>
    <String, dynamic>{
      'id': const RoomIdConverter().toJson(instance.id),
      'theme': instance.theme,
      'tmxFile': instance.tmxFile,
      'exits': instance.exits,
      'triggers': instance.triggers,
      'spawnPoint': const Vector3Converter().toJson(instance.spawnPoint),
      'properties': instance.properties,
    };

_$WorldGraphImpl _$$WorldGraphImplFromJson(Map<String, dynamic> json) =>
    _$WorldGraphImpl(
      rooms: (json['rooms'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, RoomDefinition.fromJson(e as Map<String, dynamic>)),
      ),
      startRoom: const RoomIdConverter().fromJson(json['startRoom'] as String),
    );

Map<String, dynamic> _$$WorldGraphImplToJson(_$WorldGraphImpl instance) =>
    <String, dynamic>{
      'rooms': instance.rooms,
      'startRoom': const RoomIdConverter().toJson(instance.startRoom),
    };

_$RoomStateImpl _$$RoomStateImplFromJson(Map<String, dynamic> json) =>
    _$RoomStateImpl(
      id: const RoomIdConverter().fromJson(json['id'] as String),
      collectedItems: (json['collectedItems'] as List<dynamic>)
          .map((e) => e as String)
          .toSet(),
      activatedSwitches: (json['activatedSwitches'] as List<dynamic>)
          .map((e) => e as String)
          .toSet(),
      eatenFish:
          (json['eatenFish'] as List<dynamic>).map((e) => e as String).toSet(),
      customFlags: json['customFlags'] as Map<String, dynamic>,
      isCleared: json['isCleared'] as bool,
    );

Map<String, dynamic> _$$RoomStateImplToJson(_$RoomStateImpl instance) =>
    <String, dynamic>{
      'id': const RoomIdConverter().toJson(instance.id),
      'collectedItems': instance.collectedItems.toList(),
      'activatedSwitches': instance.activatedSwitches.toList(),
      'eatenFish': instance.eatenFish.toList(),
      'customFlags': instance.customFlags,
      'isCleared': instance.isCleared,
    };
