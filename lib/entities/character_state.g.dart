// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CharacterStateImpl _$$CharacterStateImplFromJson(Map<String, dynamic> json) =>
    _$CharacterStateImpl(
      type: $enumDecode(_$CharacterTypeEnumMap, json['type']),
      position:
          const Vector3Converter().fromJson(json['position'] as List<double>),
      velocity:
          const Vector2Converter().fromJson(json['velocity'] as List<double>),
      animation: $enumDecode(_$AnimationStateEnumMap, json['animation']),
      facing: $enumDecode(_$FacingDirectionEnumMap, json['facing']),
      isGrounded: json['isGrounded'] as bool,
      jumpPhase: (json['jumpPhase'] as num).toInt(),
      jumpFramesRemaining: (json['jumpFramesRemaining'] as num).toInt(),
      carriedItem: const CarriedItemConverter()
          .fromJson(json['carriedItem'] as Map<String, dynamic>),
      doughnutCount: (json['doughnutCount'] as num).toInt(),
      activePowerUps: (json['activePowerUps'] as List<dynamic>)
          .map((e) =>
              const PowerUpConverter().fromJson(e as Map<String, dynamic>))
          .toList(),
      isControllable: json['isControllable'] as bool,
      isInvulnerable: json['isInvulnerable'] as bool,
      lives: (json['lives'] as num).toInt(),
    );

Map<String, dynamic> _$$CharacterStateImplToJson(
        _$CharacterStateImpl instance) =>
    <String, dynamic>{
      'type': _$CharacterTypeEnumMap[instance.type]!,
      'position': const Vector3Converter().toJson(instance.position),
      'velocity': const Vector2Converter().toJson(instance.velocity),
      'animation': _$AnimationStateEnumMap[instance.animation]!,
      'facing': _$FacingDirectionEnumMap[instance.facing]!,
      'isGrounded': instance.isGrounded,
      'jumpPhase': instance.jumpPhase,
      'jumpFramesRemaining': instance.jumpFramesRemaining,
      'carriedItem': const CarriedItemConverter().toJson(instance.carriedItem),
      'doughnutCount': instance.doughnutCount,
      'activePowerUps':
          instance.activePowerUps.map(const PowerUpConverter().toJson).toList(),
      'isControllable': instance.isControllable,
      'isInvulnerable': instance.isInvulnerable,
      'lives': instance.lives,
    };

const _$CharacterTypeEnumMap = {
  CharacterType.head: 'head',
  CharacterType.heels: 'heels',
  CharacterType.combined: 'combined',
};

const _$AnimationStateEnumMap = {
  AnimationState.idle: 'idle',
  AnimationState.walk: 'walk',
  AnimationState.jumpRise: 'jumpRise',
  AnimationState.jumpPeak: 'jumpPeak',
  AnimationState.jumpFall: 'jumpFall',
  AnimationState.land: 'land',
  AnimationState.climb: 'climb',
  AnimationState.carry: 'carry',
  AnimationState.fire: 'fire',
  AnimationState.swop: 'swop',
  AnimationState.hurt: 'hurt',
  AnimationState.death: 'death',
};

const _$FacingDirectionEnumMap = {
  FacingDirection.north: 'north',
  FacingDirection.northEast: 'northEast',
  FacingDirection.east: 'east',
  FacingDirection.southEast: 'southEast',
  FacingDirection.south: 'south',
  FacingDirection.southWest: 'southWest',
  FacingDirection.west: 'west',
  FacingDirection.northWest: 'northWest',
};

_$DualCharacterStateImpl _$$DualCharacterStateImplFromJson(
        Map<String, dynamic> json) =>
    _$DualCharacterStateImpl(
      head: CharacterState.fromJson(json['head'] as Map<String, dynamic>),
      heels: CharacterState.fromJson(json['heels'] as Map<String, dynamic>),
      controlled: $enumDecode(_$ControlledEntityEnumMap, json['controlled']),
      areCombined: json['areCombined'] as bool,
      combinedPosition: const Vector3Converter()
          .fromJson(json['combinedPosition'] as List<double>),
    );

Map<String, dynamic> _$$DualCharacterStateImplToJson(
        _$DualCharacterStateImpl instance) =>
    <String, dynamic>{
      'head': instance.head,
      'heels': instance.heels,
      'controlled': _$ControlledEntityEnumMap[instance.controlled]!,
      'areCombined': instance.areCombined,
      'combinedPosition':
          const Vector3Converter().toJson(instance.combinedPosition),
    };

const _$ControlledEntityEnumMap = {
  ControlledEntity.head: 'head',
  ControlledEntity.heels: 'heels',
  ControlledEntity.combined: 'combined',
};
