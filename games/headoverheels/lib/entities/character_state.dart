// Character state management for Head over Heels.
//
// This module implements the dual-character system with three modes:
// - Head alone: high jump (2 tiles), slow walk (2 tiles/sec), can fire doughnuts
// - Heels alone: low jump (1 tile), fast walk (4 tiles/sec), can carry items
// - Combined: Head on Heels' shoulders — merged abilities (3 tiles/sec, 2 tiles jump)
//
// State is immutable (Freezed) and authoritative in Riverpod.
// Flame components only render; they never mutate state directly.
// library character_state; // Removed to satisfy unnecessary_library_name lint

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vector_math/vector_math.dart';
import 'package:headoverheels/utils/json_converters.dart';

part 'character_state.freezed.dart';
part 'character_state.g.dart';

/// Which character the player currently controls.
enum ControlledEntity { head, heels, combined }

/// Character type determines physics parameters and abilities.
enum CharacterType { head, heels, combined }

/// 8-directional facing for sprite selection.
enum FacingDirection {
  north,
  northEast,
  east,
  southEast,
  south,
  southWest,
  west,
  northWest;

  /// Convert from movement vector (x, y) in grid space.
  static FacingDirection fromVector(Vector2 v) {
    if (v.x == 0 && v.y == 0) return FacingDirection.south;
    final angle = v.angleTo(Vector2(0, -1)); // North = 0
    return _angleToDirection(angle);
  }

  static FacingDirection _angleToDirection(double angle) {
    while (angle < 0) {
      angle += 2 * 3.14159265359;
    }
    while (angle >= 2 * 3.14159265359) {
      angle -= 2 * 3.14159265359;
    }
    final index =
        ((angle + 3.14159265359 / 8) / (3.14159265359 / 4)).floor() % 8;
    return FacingDirection.values[index];
  }

  int get spriteRow => index;
}

/// Animation state for character rendering.
enum AnimationState {
  idle,
  walk,
  jumpRise,
  jumpPeak,
  jumpFall,
  land,
  climb,
  carry,
  fire,
  swop,
  hurt,
  death,
}

/// Item that Heels can carry (one at a time).
@freezed
abstract class CarriedItem with _$CarriedItem {
  const factory CarriedItem.none() = _None;
  const factory CarriedItem.key(String keyId) = _Key;
  const factory CarriedItem.crown() = _Crown;
  const factory CarriedItem.other(String itemId) = _Other;
}

/// Active power-up from cuddly rabbits.
@freezed
abstract class PowerUp with _$PowerUp {
  const factory PowerUp.extraLives({required int count}) = _ExtraLives;
  const factory PowerUp.invulnerable({required int framesRemaining}) =
      _Invulnerable;
  const factory PowerUp.jumpBoost({required int framesRemaining}) =
      _JumpBoost; // Heels only
  const factory PowerUp.speedBoost({required int framesRemaining}) =
      _SpeedBoost; // Head only
}

/// Extension methods for PowerUp to add behavior.
extension PowerUpExtension on PowerUp {
  bool get isExpired => when(
    extraLives: (_) => false,
    invulnerable: (frames) => frames <= 0,
    jumpBoost: (frames) => frames <= 0,
    speedBoost: (frames) => frames <= 0,
  );

  PowerUp tick() => when(
    extraLives: (c) => PowerUp.extraLives(count: c),
    invulnerable: (f) => PowerUp.invulnerable(framesRemaining: f - 1),
    jumpBoost: (f) => PowerUp.jumpBoost(framesRemaining: f - 1),
    speedBoost: (f) => PowerUp.speedBoost(framesRemaining: f - 1),
  );
}

/// Complete immutable state for one character (or combined).
@freezed
abstract class CharacterState with _$CharacterState {
  const factory CharacterState({
    required CharacterType type,
    @Vector3Converter() required Vector3 position,
    @Vector2Converter() required Vector2 velocity,
    required AnimationState animation,
    required FacingDirection facing,

    /// Vertical speed, in tiles per second, positive upward.
    ///
    /// It is separate from [velocity] because [velocity] is the walk across the
    /// tile plane and this is the only thing off it. They used to be the same
    /// axis, which put gravity on the tile rows: the party slid south every
    /// frame, and `stop()` could not clear it because gravity put it straight
    /// back. See aes/tickets/T090.
    required double verticalVelocity,
    required bool isGrounded,
    required int jumpPhase,
    required int jumpFramesRemaining,
    @CarriedItemConverter() required CarriedItem carriedItem,

    /// Whether this character wears the magic bag.
    ///
    /// The bag is worn, not held: it used to be recorded as the hand's item, which
    /// made the hand full of a bag nobody could use, so the item on the floor
    /// could no longer be picked up. The bag's own slots are [bagItems].
    @Default(false) bool hasBag,

    /// What the bag holds, on top of the one item in the hand.
    ///
    /// The magic bag carries four. Nothing empties it yet: the world has no
    /// dispensary to take the items out at, which is T061.
    @Default(<CarriedItem>[])
    @CarriedItemsConverter()
    List<CarriedItem> bagItems,
    required int doughnutCount,
    @PowerUpConverter() required List<PowerUp> activePowerUps,
    required bool isControllable,
    required bool isInvulnerable,
    required int lives,
  }) = _CharacterState;

  factory CharacterState.fromJson(Map<String, dynamic> json) =>
      _$CharacterStateFromJson(json);

  /// Create initial state for a new game.
  factory CharacterState.initial({
    required CharacterType type,
    required Vector3 startPosition,
    int initialLives = 3,
  }) {
    return CharacterState(
      type: type,
      position: startPosition,
      velocity: Vector2.zero(),
      verticalVelocity: 0,
      animation: AnimationState.idle,
      facing: FacingDirection.south,
      isGrounded: true,
      jumpPhase: 0,
      jumpFramesRemaining: 0,
      carriedItem: const CarriedItem.none(),
      hasBag: false,
      bagItems: const [],
      doughnutCount: 0,
      activePowerUps: [],
      isControllable: true,
      isInvulnerable: false,
      lives: initialLives,
    );
  }
}

/// What the magic bag carries. Four, with the one in the hand on top.
const int bagCapacity = 4;

/// Extension methods for CharacterState to add computed properties.
extension CharacterStateExtension on CharacterState {
  /// Whether this character can jump (grounded and not in jump).
  bool get canJump => isGrounded && jumpPhase == 0;

  /// Whether this character can fire (Head or combined with doughnuts).
  bool get canFire =>
      (type == CharacterType.head || type == CharacterType.combined) &&
      doughnutCount > 0;

  /// Whether this character can carry (Heels or combined).
  bool get canCarry =>
      type == CharacterType.heels || type == CharacterType.combined;

  /// Whether this character can climb ladders (Head or combined).
  bool get canClimb =>
      type == CharacterType.head || type == CharacterType.combined;

  /// Current walk speed in tiles/second.
  double get walkSpeed {
    final baseSpeed = switch (type) {
      CharacterType.head => 2.0,
      CharacterType.heels => 4.0,
      CharacterType.combined => 3.0,
    };
    final hasSpeedBoost = activePowerUps.any(
      (p) => p.when(
        extraLives: (_) => false,
        invulnerable: (_) => false,
        jumpBoost: (_) => false,
        speedBoost: (frames) => frames > 0,
      ),
    );
    return hasSpeedBoost ? baseSpeed * 1.5 : baseSpeed;
  }

  /// Current jump height in tiles.
  double get jumpHeight {
    final baseHeight = switch (type) {
      CharacterType.head => 2.0,
      CharacterType.heels => 1.0,
      CharacterType.combined => 2.0,
    };
    final hasJumpBoost = activePowerUps.any(
      (p) => p.when(
        extraLives: (_) => false,
        invulnerable: (_) => false,
        jumpBoost: (frames) => frames > 0,
        speedBoost: (_) => false,
      ),
    );
    return hasJumpBoost ? baseHeight * 1.5 : baseHeight;
  }

  /// Current jump duration in frames @ 60Hz.
  int get jumpDurationFrames {
    return switch (type) {
      CharacterType.head => 30,
      CharacterType.heels => 20,
      CharacterType.combined => 30,
    };
  }

  /// Air control factor (0.0 = no control, 1.0 = full control).
  double get airControl {
    return switch (type) {
      CharacterType.head => 0.5,
      CharacterType.heels => 0.2,
      CharacterType.combined => 0.4,
    };
  }
}

/// Combined game state for both characters.
@freezed
abstract class DualCharacterState with _$DualCharacterState {
  const factory DualCharacterState({
    required CharacterState head,
    required CharacterState heels,
    required ControlledEntity controlled,
    required bool areCombined,
    @Vector3Converter() required Vector3 combinedPosition,
  }) = _DualCharacterState;

  factory DualCharacterState.fromJson(Map<String, dynamic> json) =>
      _$DualCharacterStateFromJson(json);

  /// Create initial separated state.
  factory DualCharacterState.initial({
    required Vector3 headStart,
    required Vector3 heelsStart,
    int initialLives = 3,
  }) => DualCharacterState(
    head: CharacterState.initial(
      type: CharacterType.head,
      startPosition: headStart,
      initialLives: initialLives,
    ),
    heels: CharacterState.initial(
      type: CharacterType.heels,
      startPosition: heelsStart,
      initialLives: initialLives,
    ),
    controlled: ControlledEntity.head,
    areCombined: false,
    combinedPosition: Vector3.zero(),
  );
}

/// Extension methods for DualCharacterState.
extension DualCharacterStateExtension on DualCharacterState {
  /// Get the currently controlled character state.
  CharacterState get controlledState {
    return switch (controlled) {
      ControlledEntity.head => head,
      ControlledEntity.heels => heels,
      ControlledEntity.combined => head,
    };
  }

  /// Get the non-controlled character state (for AI/follow behavior).
  CharacterState? get nonControlledState {
    return switch (controlled) {
      ControlledEntity.head => heels,
      ControlledEntity.heels => head,
      ControlledEntity.combined => null,
    };
  }

  /// Create combined state (Head on Heels).
  DualCharacterState combine() {
    if (areCombined) return this;
    final avgPos = Vector3(
      (head.position.x + heels.position.x) / 2,
      (head.position.y + heels.position.y) / 2,
      (head.position.z + heels.position.z) / 2,
    );
    final mergedPowerUps = [...head.activePowerUps, ...heels.activePowerUps];
    return copyWith(
      head: head.copyWith(
        type: CharacterType.combined,
        position: avgPos,
        isControllable: true,
        carriedItem: heels.carriedItem,
        doughnutCount: head.doughnutCount,
        activePowerUps: mergedPowerUps,
      ),
      heels: heels.copyWith(
        type: CharacterType.combined,
        position: avgPos,
        isControllable: false,
      ),
      controlled: ControlledEntity.combined,
      areCombined: true,
      combinedPosition: avgPos,
    );
  }

  /// Separate combined characters.
  DualCharacterState separate({required ControlledEntity controlWhich}) {
    if (!areCombined) return this;
    final offset = Vector3(0.5, 0, 0);
    final headPos = combinedPosition + offset;
    final heelsPos = combinedPosition - offset;
    final controlledIsHead = controlWhich == ControlledEntity.head;

    return DualCharacterState(
      head: head.copyWith(
        type: CharacterType.head,
        position: headPos,
        isControllable: controlledIsHead,
        carriedItem: const CarriedItem.none(),
        activePowerUps: head.activePowerUps
            .where(
              (p) => p.when(
                extraLives: (_) => true,
                invulnerable: (_) => true,
                jumpBoost: (_) => true,
                speedBoost: (_) => false,
              ),
            )
            .toList(),
      ),
      heels: heels.copyWith(
        type: CharacterType.heels,
        position: heelsPos,
        isControllable: !controlledIsHead,
        doughnutCount: 0,
        activePowerUps: heels.activePowerUps
            .where(
              (p) => p.when(
                extraLives: (_) => true,
                invulnerable: (_) => true,
                jumpBoost: (_) => false,
                speedBoost: (_) => true,
              ),
            )
            .toList(),
      ),
      controlled: controlWhich,
      areCombined: false,
      combinedPosition: Vector3.zero(),
    );
  }
}
