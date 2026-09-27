// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_graph.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$RoomId {
  String get value => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $RoomIdCopyWith<RoomId> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoomIdCopyWith<$Res> {
  factory $RoomIdCopyWith(RoomId value, $Res Function(RoomId) then) =
      _$RoomIdCopyWithImpl<$Res, RoomId>;
  @useResult
  $Res call({String value});
}

/// @nodoc
class _$RoomIdCopyWithImpl<$Res, $Val extends RoomId>
    implements $RoomIdCopyWith<$Res> {
  _$RoomIdCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? value = null}) {
    return _then(
      _value.copyWith(
            value: null == value
                ? _value.value
                : value // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RoomIdImplCopyWith<$Res> implements $RoomIdCopyWith<$Res> {
  factory _$$RoomIdImplCopyWith(
    _$RoomIdImpl value,
    $Res Function(_$RoomIdImpl) then,
  ) = __$$RoomIdImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String value});
}

/// @nodoc
class __$$RoomIdImplCopyWithImpl<$Res>
    extends _$RoomIdCopyWithImpl<$Res, _$RoomIdImpl>
    implements _$$RoomIdImplCopyWith<$Res> {
  __$$RoomIdImplCopyWithImpl(
    _$RoomIdImpl _value,
    $Res Function(_$RoomIdImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? value = null}) {
    return _then(
      _$RoomIdImpl(
        null == value
            ? _value.value
            : value // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$RoomIdImpl implements _RoomId {
  const _$RoomIdImpl(this.value);

  @override
  final String value;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoomIdImpl &&
            (identical(other.value, value) || other.value == value));
  }

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RoomIdImplCopyWith<_$RoomIdImpl> get copyWith =>
      __$$RoomIdImplCopyWithImpl<_$RoomIdImpl>(this, _$identity);
}

abstract class _RoomId implements RoomId {
  const factory _RoomId(final String value) = _$RoomIdImpl;

  @override
  String get value;
  @override
  @JsonKey(ignore: true)
  _$$RoomIdImplCopyWith<_$RoomIdImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RoomExit _$RoomExitFromJson(Map<String, dynamic> json) {
  return _RoomExit.fromJson(json);
}

/// @nodoc
mixin _$RoomExit {
  ExitDirection get direction => throw _privateConstructorUsedError;
  @RoomIdConverter()
  RoomId get targetRoom => throw _privateConstructorUsedError;
  String get targetEntrance =>
      throw _privateConstructorUsedError; // Named entrance in target room
  bool get isLocked => throw _privateConstructorUsedError;
  String? get keyId =>
      throw _privateConstructorUsedError; // If locked, key required
  bool get oneWay => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RoomExitCopyWith<RoomExit> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoomExitCopyWith<$Res> {
  factory $RoomExitCopyWith(RoomExit value, $Res Function(RoomExit) then) =
      _$RoomExitCopyWithImpl<$Res, RoomExit>;
  @useResult
  $Res call({
    ExitDirection direction,
    @RoomIdConverter() RoomId targetRoom,
    String targetEntrance,
    bool isLocked,
    String? keyId,
    bool oneWay,
  });

  $RoomIdCopyWith<$Res> get targetRoom;
}

/// @nodoc
class _$RoomExitCopyWithImpl<$Res, $Val extends RoomExit>
    implements $RoomExitCopyWith<$Res> {
  _$RoomExitCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? direction = null,
    Object? targetRoom = null,
    Object? targetEntrance = null,
    Object? isLocked = null,
    Object? keyId = freezed,
    Object? oneWay = null,
  }) {
    return _then(
      _value.copyWith(
            direction: null == direction
                ? _value.direction
                : direction // ignore: cast_nullable_to_non_nullable
                      as ExitDirection,
            targetRoom: null == targetRoom
                ? _value.targetRoom
                : targetRoom // ignore: cast_nullable_to_non_nullable
                      as RoomId,
            targetEntrance: null == targetEntrance
                ? _value.targetEntrance
                : targetEntrance // ignore: cast_nullable_to_non_nullable
                      as String,
            isLocked: null == isLocked
                ? _value.isLocked
                : isLocked // ignore: cast_nullable_to_non_nullable
                      as bool,
            keyId: freezed == keyId
                ? _value.keyId
                : keyId // ignore: cast_nullable_to_non_nullable
                      as String?,
            oneWay: null == oneWay
                ? _value.oneWay
                : oneWay // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  $RoomIdCopyWith<$Res> get targetRoom {
    return $RoomIdCopyWith<$Res>(_value.targetRoom, (value) {
      return _then(_value.copyWith(targetRoom: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RoomExitImplCopyWith<$Res>
    implements $RoomExitCopyWith<$Res> {
  factory _$$RoomExitImplCopyWith(
    _$RoomExitImpl value,
    $Res Function(_$RoomExitImpl) then,
  ) = __$$RoomExitImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    ExitDirection direction,
    @RoomIdConverter() RoomId targetRoom,
    String targetEntrance,
    bool isLocked,
    String? keyId,
    bool oneWay,
  });

  @override
  $RoomIdCopyWith<$Res> get targetRoom;
}

/// @nodoc
class __$$RoomExitImplCopyWithImpl<$Res>
    extends _$RoomExitCopyWithImpl<$Res, _$RoomExitImpl>
    implements _$$RoomExitImplCopyWith<$Res> {
  __$$RoomExitImplCopyWithImpl(
    _$RoomExitImpl _value,
    $Res Function(_$RoomExitImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? direction = null,
    Object? targetRoom = null,
    Object? targetEntrance = null,
    Object? isLocked = null,
    Object? keyId = freezed,
    Object? oneWay = null,
  }) {
    return _then(
      _$RoomExitImpl(
        direction: null == direction
            ? _value.direction
            : direction // ignore: cast_nullable_to_non_nullable
                  as ExitDirection,
        targetRoom: null == targetRoom
            ? _value.targetRoom
            : targetRoom // ignore: cast_nullable_to_non_nullable
                  as RoomId,
        targetEntrance: null == targetEntrance
            ? _value.targetEntrance
            : targetEntrance // ignore: cast_nullable_to_non_nullable
                  as String,
        isLocked: null == isLocked
            ? _value.isLocked
            : isLocked // ignore: cast_nullable_to_non_nullable
                  as bool,
        keyId: freezed == keyId
            ? _value.keyId
            : keyId // ignore: cast_nullable_to_non_nullable
                  as String?,
        oneWay: null == oneWay
            ? _value.oneWay
            : oneWay // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RoomExitImpl implements _RoomExit {
  const _$RoomExitImpl({
    required this.direction,
    @RoomIdConverter() required this.targetRoom,
    required this.targetEntrance,
    required this.isLocked,
    required this.keyId,
    required this.oneWay,
  });

  factory _$RoomExitImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoomExitImplFromJson(json);

  @override
  final ExitDirection direction;
  @override
  @RoomIdConverter()
  final RoomId targetRoom;
  @override
  final String targetEntrance;
  // Named entrance in target room
  @override
  final bool isLocked;
  @override
  final String? keyId;
  // If locked, key required
  @override
  final bool oneWay;

  @override
  String toString() {
    return 'RoomExit(direction: $direction, targetRoom: $targetRoom, targetEntrance: $targetEntrance, isLocked: $isLocked, keyId: $keyId, oneWay: $oneWay)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoomExitImpl &&
            (identical(other.direction, direction) ||
                other.direction == direction) &&
            (identical(other.targetRoom, targetRoom) ||
                other.targetRoom == targetRoom) &&
            (identical(other.targetEntrance, targetEntrance) ||
                other.targetEntrance == targetEntrance) &&
            (identical(other.isLocked, isLocked) ||
                other.isLocked == isLocked) &&
            (identical(other.keyId, keyId) || other.keyId == keyId) &&
            (identical(other.oneWay, oneWay) || other.oneWay == oneWay));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    direction,
    targetRoom,
    targetEntrance,
    isLocked,
    keyId,
    oneWay,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RoomExitImplCopyWith<_$RoomExitImpl> get copyWith =>
      __$$RoomExitImplCopyWithImpl<_$RoomExitImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RoomExitImplToJson(this);
  }
}

abstract class _RoomExit implements RoomExit {
  const factory _RoomExit({
    required final ExitDirection direction,
    @RoomIdConverter() required final RoomId targetRoom,
    required final String targetEntrance,
    required final bool isLocked,
    required final String? keyId,
    required final bool oneWay,
  }) = _$RoomExitImpl;

  factory _RoomExit.fromJson(Map<String, dynamic> json) =
      _$RoomExitImpl.fromJson;

  @override
  ExitDirection get direction;
  @override
  @RoomIdConverter()
  RoomId get targetRoom;
  @override
  String get targetEntrance;
  @override // Named entrance in target room
  bool get isLocked;
  @override
  String? get keyId;
  @override // If locked, key required
  bool get oneWay;
  @override
  @JsonKey(ignore: true)
  _$$RoomExitImplCopyWith<_$RoomExitImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TriggerZone _$TriggerZoneFromJson(Map<String, dynamic> json) {
  return _TriggerZone.fromJson(json);
}

/// @nodoc
mixin _$TriggerZone {
  String get id => throw _privateConstructorUsedError;
  TriggerType get type => throw _privateConstructorUsedError;
  @Vector3Converter()
  Vector3 get position => throw _privateConstructorUsedError; // Grid position (tile coordinates)
  @Vector2Converter()
  Vector2 get size => throw _privateConstructorUsedError; // Size in tiles (width, height)
  // For doors/teleports
  RoomExit? get exit => throw _privateConstructorUsedError; // For ladders
  int? get targetLevel =>
      throw _privateConstructorUsedError; // Z-level to move to
  // For conveyors
  ExitDirection? get conveyorDirection => throw _privateConstructorUsedError;
  double? get conveyorSpeed =>
      throw _privateConstructorUsedError; // For items/monsters/special
  Map<String, dynamic>? get properties => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TriggerZoneCopyWith<TriggerZone> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TriggerZoneCopyWith<$Res> {
  factory $TriggerZoneCopyWith(
    TriggerZone value,
    $Res Function(TriggerZone) then,
  ) = _$TriggerZoneCopyWithImpl<$Res, TriggerZone>;
  @useResult
  $Res call({
    String id,
    TriggerType type,
    @Vector3Converter() Vector3 position,
    @Vector2Converter() Vector2 size,
    RoomExit? exit,
    int? targetLevel,
    ExitDirection? conveyorDirection,
    double? conveyorSpeed,
    Map<String, dynamic>? properties,
  });

  $RoomExitCopyWith<$Res>? get exit;
}

/// @nodoc
class _$TriggerZoneCopyWithImpl<$Res, $Val extends TriggerZone>
    implements $TriggerZoneCopyWith<$Res> {
  _$TriggerZoneCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? position = null,
    Object? size = null,
    Object? exit = freezed,
    Object? targetLevel = freezed,
    Object? conveyorDirection = freezed,
    Object? conveyorSpeed = freezed,
    Object? properties = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as TriggerType,
            position: null == position
                ? _value.position
                : position // ignore: cast_nullable_to_non_nullable
                      as Vector3,
            size: null == size
                ? _value.size
                : size // ignore: cast_nullable_to_non_nullable
                      as Vector2,
            exit: freezed == exit
                ? _value.exit
                : exit // ignore: cast_nullable_to_non_nullable
                      as RoomExit?,
            targetLevel: freezed == targetLevel
                ? _value.targetLevel
                : targetLevel // ignore: cast_nullable_to_non_nullable
                      as int?,
            conveyorDirection: freezed == conveyorDirection
                ? _value.conveyorDirection
                : conveyorDirection // ignore: cast_nullable_to_non_nullable
                      as ExitDirection?,
            conveyorSpeed: freezed == conveyorSpeed
                ? _value.conveyorSpeed
                : conveyorSpeed // ignore: cast_nullable_to_non_nullable
                      as double?,
            properties: freezed == properties
                ? _value.properties
                : properties // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
          )
          as $Val,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  $RoomExitCopyWith<$Res>? get exit {
    if (_value.exit == null) {
      return null;
    }

    return $RoomExitCopyWith<$Res>(_value.exit!, (value) {
      return _then(_value.copyWith(exit: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TriggerZoneImplCopyWith<$Res>
    implements $TriggerZoneCopyWith<$Res> {
  factory _$$TriggerZoneImplCopyWith(
    _$TriggerZoneImpl value,
    $Res Function(_$TriggerZoneImpl) then,
  ) = __$$TriggerZoneImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    TriggerType type,
    @Vector3Converter() Vector3 position,
    @Vector2Converter() Vector2 size,
    RoomExit? exit,
    int? targetLevel,
    ExitDirection? conveyorDirection,
    double? conveyorSpeed,
    Map<String, dynamic>? properties,
  });

  @override
  $RoomExitCopyWith<$Res>? get exit;
}

/// @nodoc
class __$$TriggerZoneImplCopyWithImpl<$Res>
    extends _$TriggerZoneCopyWithImpl<$Res, _$TriggerZoneImpl>
    implements _$$TriggerZoneImplCopyWith<$Res> {
  __$$TriggerZoneImplCopyWithImpl(
    _$TriggerZoneImpl _value,
    $Res Function(_$TriggerZoneImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? position = null,
    Object? size = null,
    Object? exit = freezed,
    Object? targetLevel = freezed,
    Object? conveyorDirection = freezed,
    Object? conveyorSpeed = freezed,
    Object? properties = freezed,
  }) {
    return _then(
      _$TriggerZoneImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as TriggerType,
        position: null == position
            ? _value.position
            : position // ignore: cast_nullable_to_non_nullable
                  as Vector3,
        size: null == size
            ? _value.size
            : size // ignore: cast_nullable_to_non_nullable
                  as Vector2,
        exit: freezed == exit
            ? _value.exit
            : exit // ignore: cast_nullable_to_non_nullable
                  as RoomExit?,
        targetLevel: freezed == targetLevel
            ? _value.targetLevel
            : targetLevel // ignore: cast_nullable_to_non_nullable
                  as int?,
        conveyorDirection: freezed == conveyorDirection
            ? _value.conveyorDirection
            : conveyorDirection // ignore: cast_nullable_to_non_nullable
                  as ExitDirection?,
        conveyorSpeed: freezed == conveyorSpeed
            ? _value.conveyorSpeed
            : conveyorSpeed // ignore: cast_nullable_to_non_nullable
                  as double?,
        properties: freezed == properties
            ? _value._properties
            : properties // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TriggerZoneImpl implements _TriggerZone {
  const _$TriggerZoneImpl({
    required this.id,
    required this.type,
    @Vector3Converter() required this.position,
    @Vector2Converter() required this.size,
    this.exit,
    this.targetLevel,
    this.conveyorDirection,
    this.conveyorSpeed,
    final Map<String, dynamic>? properties,
  }) : _properties = properties;

  factory _$TriggerZoneImpl.fromJson(Map<String, dynamic> json) =>
      _$$TriggerZoneImplFromJson(json);

  @override
  final String id;
  @override
  final TriggerType type;
  @override
  @Vector3Converter()
  final Vector3 position;
  // Grid position (tile coordinates)
  @override
  @Vector2Converter()
  final Vector2 size;
  // Size in tiles (width, height)
  // For doors/teleports
  @override
  final RoomExit? exit;
  // For ladders
  @override
  final int? targetLevel;
  // Z-level to move to
  // For conveyors
  @override
  final ExitDirection? conveyorDirection;
  @override
  final double? conveyorSpeed;
  // For items/monsters/special
  final Map<String, dynamic>? _properties;
  // For items/monsters/special
  @override
  Map<String, dynamic>? get properties {
    final value = _properties;
    if (value == null) return null;
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'TriggerZone(id: $id, type: $type, position: $position, size: $size, exit: $exit, targetLevel: $targetLevel, conveyorDirection: $conveyorDirection, conveyorSpeed: $conveyorSpeed, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TriggerZoneImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.exit, exit) || other.exit == exit) &&
            (identical(other.targetLevel, targetLevel) ||
                other.targetLevel == targetLevel) &&
            (identical(other.conveyorDirection, conveyorDirection) ||
                other.conveyorDirection == conveyorDirection) &&
            (identical(other.conveyorSpeed, conveyorSpeed) ||
                other.conveyorSpeed == conveyorSpeed) &&
            const DeepCollectionEquality().equals(
              other._properties,
              _properties,
            ));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    type,
    position,
    size,
    exit,
    targetLevel,
    conveyorDirection,
    conveyorSpeed,
    const DeepCollectionEquality().hash(_properties),
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TriggerZoneImplCopyWith<_$TriggerZoneImpl> get copyWith =>
      __$$TriggerZoneImplCopyWithImpl<_$TriggerZoneImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TriggerZoneImplToJson(this);
  }
}

abstract class _TriggerZone implements TriggerZone {
  const factory _TriggerZone({
    required final String id,
    required final TriggerType type,
    @Vector3Converter() required final Vector3 position,
    @Vector2Converter() required final Vector2 size,
    final RoomExit? exit,
    final int? targetLevel,
    final ExitDirection? conveyorDirection,
    final double? conveyorSpeed,
    final Map<String, dynamic>? properties,
  }) = _$TriggerZoneImpl;

  factory _TriggerZone.fromJson(Map<String, dynamic> json) =
      _$TriggerZoneImpl.fromJson;

  @override
  String get id;
  @override
  TriggerType get type;
  @override
  @Vector3Converter()
  Vector3 get position;
  @override // Grid position (tile coordinates)
  @Vector2Converter()
  Vector2 get size;
  @override // Size in tiles (width, height)
  // For doors/teleports
  RoomExit? get exit;
  @override // For ladders
  int? get targetLevel;
  @override // Z-level to move to
  // For conveyors
  ExitDirection? get conveyorDirection;
  @override
  double? get conveyorSpeed;
  @override // For items/monsters/special
  Map<String, dynamic>? get properties;
  @override
  @JsonKey(ignore: true)
  _$$TriggerZoneImplCopyWith<_$TriggerZoneImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RoomDefinition _$RoomDefinitionFromJson(Map<String, dynamic> json) {
  return _RoomDefinition.fromJson(json);
}

/// @nodoc
mixin _$RoomDefinition {
  @RoomIdConverter()
  RoomId get id => throw _privateConstructorUsedError;
  String get theme =>
      throw _privateConstructorUsedError; // Tileset theme: castle, egyptus, etc.
  String get tmxFile =>
      throw _privateConstructorUsedError; // TMX filename (relative to assets/levels/rooms/)
  List<RoomExit> get exits => throw _privateConstructorUsedError;
  List<TriggerZone> get triggers => throw _privateConstructorUsedError;
  @Vector3Converter()
  Vector3 get spawnPoint => throw _privateConstructorUsedError; // Default player spawn
  Map<String, dynamic> get properties => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RoomDefinitionCopyWith<RoomDefinition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoomDefinitionCopyWith<$Res> {
  factory $RoomDefinitionCopyWith(
    RoomDefinition value,
    $Res Function(RoomDefinition) then,
  ) = _$RoomDefinitionCopyWithImpl<$Res, RoomDefinition>;
  @useResult
  $Res call({
    @RoomIdConverter() RoomId id,
    String theme,
    String tmxFile,
    List<RoomExit> exits,
    List<TriggerZone> triggers,
    @Vector3Converter() Vector3 spawnPoint,
    Map<String, dynamic> properties,
  });

  $RoomIdCopyWith<$Res> get id;
}

/// @nodoc
class _$RoomDefinitionCopyWithImpl<$Res, $Val extends RoomDefinition>
    implements $RoomDefinitionCopyWith<$Res> {
  _$RoomDefinitionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? theme = null,
    Object? tmxFile = null,
    Object? exits = null,
    Object? triggers = null,
    Object? spawnPoint = null,
    Object? properties = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as RoomId,
            theme: null == theme
                ? _value.theme
                : theme // ignore: cast_nullable_to_non_nullable
                      as String,
            tmxFile: null == tmxFile
                ? _value.tmxFile
                : tmxFile // ignore: cast_nullable_to_non_nullable
                      as String,
            exits: null == exits
                ? _value.exits
                : exits // ignore: cast_nullable_to_non_nullable
                      as List<RoomExit>,
            triggers: null == triggers
                ? _value.triggers
                : triggers // ignore: cast_nullable_to_non_nullable
                      as List<TriggerZone>,
            spawnPoint: null == spawnPoint
                ? _value.spawnPoint
                : spawnPoint // ignore: cast_nullable_to_non_nullable
                      as Vector3,
            properties: null == properties
                ? _value.properties
                : properties // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
          )
          as $Val,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  $RoomIdCopyWith<$Res> get id {
    return $RoomIdCopyWith<$Res>(_value.id, (value) {
      return _then(_value.copyWith(id: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RoomDefinitionImplCopyWith<$Res>
    implements $RoomDefinitionCopyWith<$Res> {
  factory _$$RoomDefinitionImplCopyWith(
    _$RoomDefinitionImpl value,
    $Res Function(_$RoomDefinitionImpl) then,
  ) = __$$RoomDefinitionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @RoomIdConverter() RoomId id,
    String theme,
    String tmxFile,
    List<RoomExit> exits,
    List<TriggerZone> triggers,
    @Vector3Converter() Vector3 spawnPoint,
    Map<String, dynamic> properties,
  });

  @override
  $RoomIdCopyWith<$Res> get id;
}

/// @nodoc
class __$$RoomDefinitionImplCopyWithImpl<$Res>
    extends _$RoomDefinitionCopyWithImpl<$Res, _$RoomDefinitionImpl>
    implements _$$RoomDefinitionImplCopyWith<$Res> {
  __$$RoomDefinitionImplCopyWithImpl(
    _$RoomDefinitionImpl _value,
    $Res Function(_$RoomDefinitionImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? theme = null,
    Object? tmxFile = null,
    Object? exits = null,
    Object? triggers = null,
    Object? spawnPoint = null,
    Object? properties = null,
  }) {
    return _then(
      _$RoomDefinitionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as RoomId,
        theme: null == theme
            ? _value.theme
            : theme // ignore: cast_nullable_to_non_nullable
                  as String,
        tmxFile: null == tmxFile
            ? _value.tmxFile
            : tmxFile // ignore: cast_nullable_to_non_nullable
                  as String,
        exits: null == exits
            ? _value._exits
            : exits // ignore: cast_nullable_to_non_nullable
                  as List<RoomExit>,
        triggers: null == triggers
            ? _value._triggers
            : triggers // ignore: cast_nullable_to_non_nullable
                  as List<TriggerZone>,
        spawnPoint: null == spawnPoint
            ? _value.spawnPoint
            : spawnPoint // ignore: cast_nullable_to_non_nullable
                  as Vector3,
        properties: null == properties
            ? _value._properties
            : properties // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RoomDefinitionImpl implements _RoomDefinition {
  const _$RoomDefinitionImpl({
    @RoomIdConverter() required this.id,
    required this.theme,
    required this.tmxFile,
    required final List<RoomExit> exits,
    required final List<TriggerZone> triggers,
    @Vector3Converter() required this.spawnPoint,
    required final Map<String, dynamic> properties,
  }) : _exits = exits,
       _triggers = triggers,
       _properties = properties;

  factory _$RoomDefinitionImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoomDefinitionImplFromJson(json);

  @override
  @RoomIdConverter()
  final RoomId id;
  @override
  final String theme;
  // Tileset theme: castle, egyptus, etc.
  @override
  final String tmxFile;
  // TMX filename (relative to assets/levels/rooms/)
  final List<RoomExit> _exits;
  // TMX filename (relative to assets/levels/rooms/)
  @override
  List<RoomExit> get exits {
    if (_exits is EqualUnmodifiableListView) return _exits;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exits);
  }

  final List<TriggerZone> _triggers;
  @override
  List<TriggerZone> get triggers {
    if (_triggers is EqualUnmodifiableListView) return _triggers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_triggers);
  }

  @override
  @Vector3Converter()
  final Vector3 spawnPoint;
  // Default player spawn
  final Map<String, dynamic> _properties;
  // Default player spawn
  @override
  Map<String, dynamic> get properties {
    if (_properties is EqualUnmodifiableMapView) return _properties;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_properties);
  }

  @override
  String toString() {
    return 'RoomDefinition(id: $id, theme: $theme, tmxFile: $tmxFile, exits: $exits, triggers: $triggers, spawnPoint: $spawnPoint, properties: $properties)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoomDefinitionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.theme, theme) || other.theme == theme) &&
            (identical(other.tmxFile, tmxFile) || other.tmxFile == tmxFile) &&
            const DeepCollectionEquality().equals(other._exits, _exits) &&
            const DeepCollectionEquality().equals(other._triggers, _triggers) &&
            (identical(other.spawnPoint, spawnPoint) ||
                other.spawnPoint == spawnPoint) &&
            const DeepCollectionEquality().equals(
              other._properties,
              _properties,
            ));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    theme,
    tmxFile,
    const DeepCollectionEquality().hash(_exits),
    const DeepCollectionEquality().hash(_triggers),
    spawnPoint,
    const DeepCollectionEquality().hash(_properties),
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RoomDefinitionImplCopyWith<_$RoomDefinitionImpl> get copyWith =>
      __$$RoomDefinitionImplCopyWithImpl<_$RoomDefinitionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RoomDefinitionImplToJson(this);
  }
}

abstract class _RoomDefinition implements RoomDefinition {
  const factory _RoomDefinition({
    @RoomIdConverter() required final RoomId id,
    required final String theme,
    required final String tmxFile,
    required final List<RoomExit> exits,
    required final List<TriggerZone> triggers,
    @Vector3Converter() required final Vector3 spawnPoint,
    required final Map<String, dynamic> properties,
  }) = _$RoomDefinitionImpl;

  factory _RoomDefinition.fromJson(Map<String, dynamic> json) =
      _$RoomDefinitionImpl.fromJson;

  @override
  @RoomIdConverter()
  RoomId get id;
  @override
  String get theme;
  @override // Tileset theme: castle, egyptus, etc.
  String get tmxFile;
  @override // TMX filename (relative to assets/levels/rooms/)
  List<RoomExit> get exits;
  @override
  List<TriggerZone> get triggers;
  @override
  @Vector3Converter()
  Vector3 get spawnPoint;
  @override // Default player spawn
  Map<String, dynamic> get properties;
  @override
  @JsonKey(ignore: true)
  _$$RoomDefinitionImplCopyWith<_$RoomDefinitionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WorldGraph _$WorldGraphFromJson(Map<String, dynamic> json) {
  return _WorldGraph.fromJson(json);
}

/// @nodoc
mixin _$WorldGraph {
  Map<String, RoomDefinition> get rooms => throw _privateConstructorUsedError;
  @RoomIdConverter()
  RoomId get startRoom => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorldGraphCopyWith<WorldGraph> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorldGraphCopyWith<$Res> {
  factory $WorldGraphCopyWith(
    WorldGraph value,
    $Res Function(WorldGraph) then,
  ) = _$WorldGraphCopyWithImpl<$Res, WorldGraph>;
  @useResult
  $Res call({
    Map<String, RoomDefinition> rooms,
    @RoomIdConverter() RoomId startRoom,
  });

  $RoomIdCopyWith<$Res> get startRoom;
}

/// @nodoc
class _$WorldGraphCopyWithImpl<$Res, $Val extends WorldGraph>
    implements $WorldGraphCopyWith<$Res> {
  _$WorldGraphCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? rooms = null, Object? startRoom = null}) {
    return _then(
      _value.copyWith(
            rooms: null == rooms
                ? _value.rooms
                : rooms // ignore: cast_nullable_to_non_nullable
                      as Map<String, RoomDefinition>,
            startRoom: null == startRoom
                ? _value.startRoom
                : startRoom // ignore: cast_nullable_to_non_nullable
                      as RoomId,
          )
          as $Val,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  $RoomIdCopyWith<$Res> get startRoom {
    return $RoomIdCopyWith<$Res>(_value.startRoom, (value) {
      return _then(_value.copyWith(startRoom: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$WorldGraphImplCopyWith<$Res>
    implements $WorldGraphCopyWith<$Res> {
  factory _$$WorldGraphImplCopyWith(
    _$WorldGraphImpl value,
    $Res Function(_$WorldGraphImpl) then,
  ) = __$$WorldGraphImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Map<String, RoomDefinition> rooms,
    @RoomIdConverter() RoomId startRoom,
  });

  @override
  $RoomIdCopyWith<$Res> get startRoom;
}

/// @nodoc
class __$$WorldGraphImplCopyWithImpl<$Res>
    extends _$WorldGraphCopyWithImpl<$Res, _$WorldGraphImpl>
    implements _$$WorldGraphImplCopyWith<$Res> {
  __$$WorldGraphImplCopyWithImpl(
    _$WorldGraphImpl _value,
    $Res Function(_$WorldGraphImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? rooms = null, Object? startRoom = null}) {
    return _then(
      _$WorldGraphImpl(
        rooms: null == rooms
            ? _value._rooms
            : rooms // ignore: cast_nullable_to_non_nullable
                  as Map<String, RoomDefinition>,
        startRoom: null == startRoom
            ? _value.startRoom
            : startRoom // ignore: cast_nullable_to_non_nullable
                  as RoomId,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$WorldGraphImpl implements _WorldGraph {
  const _$WorldGraphImpl({
    required final Map<String, RoomDefinition> rooms,
    @RoomIdConverter() required this.startRoom,
  }) : _rooms = rooms;

  factory _$WorldGraphImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorldGraphImplFromJson(json);

  final Map<String, RoomDefinition> _rooms;
  @override
  Map<String, RoomDefinition> get rooms {
    if (_rooms is EqualUnmodifiableMapView) return _rooms;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_rooms);
  }

  @override
  @RoomIdConverter()
  final RoomId startRoom;

  @override
  String toString() {
    return 'WorldGraph(rooms: $rooms, startRoom: $startRoom)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorldGraphImpl &&
            const DeepCollectionEquality().equals(other._rooms, _rooms) &&
            (identical(other.startRoom, startRoom) ||
                other.startRoom == startRoom));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_rooms),
    startRoom,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorldGraphImplCopyWith<_$WorldGraphImpl> get copyWith =>
      __$$WorldGraphImplCopyWithImpl<_$WorldGraphImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorldGraphImplToJson(this);
  }
}

abstract class _WorldGraph implements WorldGraph {
  const factory _WorldGraph({
    required final Map<String, RoomDefinition> rooms,
    @RoomIdConverter() required final RoomId startRoom,
  }) = _$WorldGraphImpl;

  factory _WorldGraph.fromJson(Map<String, dynamic> json) =
      _$WorldGraphImpl.fromJson;

  @override
  Map<String, RoomDefinition> get rooms;
  @override
  @RoomIdConverter()
  RoomId get startRoom;
  @override
  @JsonKey(ignore: true)
  _$$WorldGraphImplCopyWith<_$WorldGraphImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RoomState _$RoomStateFromJson(Map<String, dynamic> json) {
  return _RoomState.fromJson(json);
}

/// @nodoc
mixin _$RoomState {
  @RoomIdConverter()
  RoomId get id => throw _privateConstructorUsedError;
  Set<String> get collectedItems =>
      throw _privateConstructorUsedError; // Items picked up in this room
  Set<String> get activatedSwitches =>
      throw _privateConstructorUsedError; // Switches toggled
  Set<String> get eatenFish =>
      throw _privateConstructorUsedError; // Reincarnation fish consumed
  Map<String, dynamic> get customFlags =>
      throw _privateConstructorUsedError; // Arbitrary state
  bool get isCleared => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RoomStateCopyWith<RoomState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoomStateCopyWith<$Res> {
  factory $RoomStateCopyWith(RoomState value, $Res Function(RoomState) then) =
      _$RoomStateCopyWithImpl<$Res, RoomState>;
  @useResult
  $Res call({
    @RoomIdConverter() RoomId id,
    Set<String> collectedItems,
    Set<String> activatedSwitches,
    Set<String> eatenFish,
    Map<String, dynamic> customFlags,
    bool isCleared,
  });

  $RoomIdCopyWith<$Res> get id;
}

/// @nodoc
class _$RoomStateCopyWithImpl<$Res, $Val extends RoomState>
    implements $RoomStateCopyWith<$Res> {
  _$RoomStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? collectedItems = null,
    Object? activatedSwitches = null,
    Object? eatenFish = null,
    Object? customFlags = null,
    Object? isCleared = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as RoomId,
            collectedItems: null == collectedItems
                ? _value.collectedItems
                : collectedItems // ignore: cast_nullable_to_non_nullable
                      as Set<String>,
            activatedSwitches: null == activatedSwitches
                ? _value.activatedSwitches
                : activatedSwitches // ignore: cast_nullable_to_non_nullable
                      as Set<String>,
            eatenFish: null == eatenFish
                ? _value.eatenFish
                : eatenFish // ignore: cast_nullable_to_non_nullable
                      as Set<String>,
            customFlags: null == customFlags
                ? _value.customFlags
                : customFlags // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>,
            isCleared: null == isCleared
                ? _value.isCleared
                : isCleared // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  $RoomIdCopyWith<$Res> get id {
    return $RoomIdCopyWith<$Res>(_value.id, (value) {
      return _then(_value.copyWith(id: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$RoomStateImplCopyWith<$Res>
    implements $RoomStateCopyWith<$Res> {
  factory _$$RoomStateImplCopyWith(
    _$RoomStateImpl value,
    $Res Function(_$RoomStateImpl) then,
  ) = __$$RoomStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @RoomIdConverter() RoomId id,
    Set<String> collectedItems,
    Set<String> activatedSwitches,
    Set<String> eatenFish,
    Map<String, dynamic> customFlags,
    bool isCleared,
  });

  @override
  $RoomIdCopyWith<$Res> get id;
}

/// @nodoc
class __$$RoomStateImplCopyWithImpl<$Res>
    extends _$RoomStateCopyWithImpl<$Res, _$RoomStateImpl>
    implements _$$RoomStateImplCopyWith<$Res> {
  __$$RoomStateImplCopyWithImpl(
    _$RoomStateImpl _value,
    $Res Function(_$RoomStateImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? collectedItems = null,
    Object? activatedSwitches = null,
    Object? eatenFish = null,
    Object? customFlags = null,
    Object? isCleared = null,
  }) {
    return _then(
      _$RoomStateImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as RoomId,
        collectedItems: null == collectedItems
            ? _value._collectedItems
            : collectedItems // ignore: cast_nullable_to_non_nullable
                  as Set<String>,
        activatedSwitches: null == activatedSwitches
            ? _value._activatedSwitches
            : activatedSwitches // ignore: cast_nullable_to_non_nullable
                  as Set<String>,
        eatenFish: null == eatenFish
            ? _value._eatenFish
            : eatenFish // ignore: cast_nullable_to_non_nullable
                  as Set<String>,
        customFlags: null == customFlags
            ? _value._customFlags
            : customFlags // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
        isCleared: null == isCleared
            ? _value.isCleared
            : isCleared // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RoomStateImpl implements _RoomState {
  const _$RoomStateImpl({
    @RoomIdConverter() required this.id,
    required final Set<String> collectedItems,
    required final Set<String> activatedSwitches,
    required final Set<String> eatenFish,
    required final Map<String, dynamic> customFlags,
    required this.isCleared,
  }) : _collectedItems = collectedItems,
       _activatedSwitches = activatedSwitches,
       _eatenFish = eatenFish,
       _customFlags = customFlags;

  factory _$RoomStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoomStateImplFromJson(json);

  @override
  @RoomIdConverter()
  final RoomId id;
  final Set<String> _collectedItems;
  @override
  Set<String> get collectedItems {
    if (_collectedItems is EqualUnmodifiableSetView) return _collectedItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_collectedItems);
  }

  // Items picked up in this room
  final Set<String> _activatedSwitches;
  // Items picked up in this room
  @override
  Set<String> get activatedSwitches {
    if (_activatedSwitches is EqualUnmodifiableSetView)
      return _activatedSwitches;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_activatedSwitches);
  }

  // Switches toggled
  final Set<String> _eatenFish;
  // Switches toggled
  @override
  Set<String> get eatenFish {
    if (_eatenFish is EqualUnmodifiableSetView) return _eatenFish;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_eatenFish);
  }

  // Reincarnation fish consumed
  final Map<String, dynamic> _customFlags;
  // Reincarnation fish consumed
  @override
  Map<String, dynamic> get customFlags {
    if (_customFlags is EqualUnmodifiableMapView) return _customFlags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_customFlags);
  }

  // Arbitrary state
  @override
  final bool isCleared;

  @override
  String toString() {
    return 'RoomState(id: $id, collectedItems: $collectedItems, activatedSwitches: $activatedSwitches, eatenFish: $eatenFish, customFlags: $customFlags, isCleared: $isCleared)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoomStateImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality().equals(
              other._collectedItems,
              _collectedItems,
            ) &&
            const DeepCollectionEquality().equals(
              other._activatedSwitches,
              _activatedSwitches,
            ) &&
            const DeepCollectionEquality().equals(
              other._eatenFish,
              _eatenFish,
            ) &&
            const DeepCollectionEquality().equals(
              other._customFlags,
              _customFlags,
            ) &&
            (identical(other.isCleared, isCleared) ||
                other.isCleared == isCleared));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    const DeepCollectionEquality().hash(_collectedItems),
    const DeepCollectionEquality().hash(_activatedSwitches),
    const DeepCollectionEquality().hash(_eatenFish),
    const DeepCollectionEquality().hash(_customFlags),
    isCleared,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RoomStateImplCopyWith<_$RoomStateImpl> get copyWith =>
      __$$RoomStateImplCopyWithImpl<_$RoomStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RoomStateImplToJson(this);
  }
}

abstract class _RoomState implements RoomState {
  const factory _RoomState({
    @RoomIdConverter() required final RoomId id,
    required final Set<String> collectedItems,
    required final Set<String> activatedSwitches,
    required final Set<String> eatenFish,
    required final Map<String, dynamic> customFlags,
    required final bool isCleared,
  }) = _$RoomStateImpl;

  factory _RoomState.fromJson(Map<String, dynamic> json) =
      _$RoomStateImpl.fromJson;

  @override
  @RoomIdConverter()
  RoomId get id;
  @override
  Set<String> get collectedItems;
  @override // Items picked up in this room
  Set<String> get activatedSwitches;
  @override // Switches toggled
  Set<String> get eatenFish;
  @override // Reincarnation fish consumed
  Map<String, dynamic> get customFlags;
  @override // Arbitrary state
  bool get isCleared;
  @override
  @JsonKey(ignore: true)
  _$$RoomStateImplCopyWith<_$RoomStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
