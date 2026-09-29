// Character state notifier for Head over Heels.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:headoverheels/entities/character_state.dart';
import 'package:headoverheels/core/isometric.dart' hide FacingDirection;
import 'package:vector_math/vector_math.dart';

/// Notifier for a single character's state (Head or Heels).
class CharacterStateNotifier extends StateNotifier<CharacterState> {
  CharacterStateNotifier({required CharacterState initialState})
    : super(initialState);

  // Physics constants
  double _accumulator = 0.0;

  // Movement
  void move(Direction8 direction) {
    state = state.copyWith(
      velocity: _directionToVector(direction) * state.walkSpeed,
      facing: FacingDirection.fromVector(direction.vector),
      animation: AnimationState.walk,
    );
  }

  void stop() {
    state = state.copyWith(
      velocity: Vector2.zero(),
      animation: AnimationState.idle,
    );
  }

  // Jumping
  void jump() {
    if (!state.canJump) return;
    state = state.copyWith(
      isGrounded: false,
      jumpPhase: 1, // Rising
      jumpFramesRemaining: state.jumpDurationFrames,
      animation: AnimationState.jumpRise,
      velocity: Vector2(
        state.velocity.x,
        -state.jumpHeight / (state.jumpDurationFrames / 60.0),
      ),
    );
  }

  /// Gives the character something to hold. This is the one slot a character
  /// carries in, so picking something up replaces what was there.
  void pickUp(CarriedItem item) {
    state = state.copyWith(carriedItem: item);
  }

  /// Puts down whatever was being held.
  void putDown() {
    state = state.copyWith(carriedItem: const CarriedItem.none());
  }

  /// Wears the magic bag. The hand is left alone: the bag is worn, and holding
  /// it used to fill the one slot a character has with an item nobody could use.
  void wearBag() {
    state = state.copyWith(hasBag: true);
  }

  /// Puts [item] in the bag, if the bag is worn and has room.
  ///
  /// Whether this character wears the magic bag.
  bool get wearsBag => state.hasBag;

  /// What the bag holds, as far as a caller is concerned.
  List<CarriedItem> get bagContents =>
      List<CarriedItem>.unmodifiable(state.bagItems);

  /// Takes everything out of the bag and hands it back, for the dispensary.
  ///
  /// The bag fills and stays full until there is somewhere to empty it, which is
  /// the dispensary in the room the party arrives in.
  List<CarriedItem> emptyBag() {
    final contents = List<CarriedItem>.of(state.bagItems);
    if (contents.isNotEmpty) state = state.copyWith(bagItems: const []);
    return contents;
  }

  /// The magic bag carries four. With no dispensary in the world to take
  /// anything out at, the bag fills and stays full: that is T061, and this is
  /// the half that is a fact about the game rather than a guess about it.
  bool stow(CarriedItem item) {
    if (!state.hasBag) return false;
    if (state.bagItems.length >= bagCapacity) return false;
    state = state.copyWith(bagItems: [...state.bagItems, item]);
    return true;
  }

  // Actions
  void carry() {
    if (!state.canCarry) return;
    // Handled by interaction system
  }

  void fire() {
    if (!state.canFire) return;
    if (state.doughnutCount <= 0) return;

    state = state.copyWith(
      doughnutCount: state.doughnutCount - 1,
      animation: AnimationState.fire,
    );
    // Projectile spawned by interaction system
  }

  void swop() {
    // Handled by DualCharacterNotifier
  }

  /// Set character position directly (for room transitions).
  void setPosition(Vector3 position) {
    state = state.copyWith(position: position);
  }

  // Physics update (fixed timestep)
  void update(double dt) {
    _accumulator += dt;
    while (_accumulator >= 1.0 / 60.0) {
      _fixedUpdate(1.0 / 60.0);
      _accumulator -= 1.0 / 60.0;
    }
  }

  void _fixedUpdate(double dt) {
    final currentState = state;

    // Apply gravity
    final velocity = Vector2(
      currentState.velocity.x,
      currentState.velocity.y + (9.8 * dt * 60.0), // Gravity scaled to tiles
    );

    // Update position
    final newPosition = Vector3(
      currentState.position.x + velocity.x * dt,
      currentState.position.y + velocity.y * dt,
      currentState.position.z,
    );

    // Ground check (simplified - real impl checks collision)
    final isGrounded = newPosition.z <= 0;
    final newVelocity = isGrounded ? Vector2(velocity.x, 0) : velocity;

    // Jump phase update
    int jumpPhase = currentState.jumpPhase;
    int jumpFramesRemaining = currentState.jumpFramesRemaining;

    if (jumpPhase > 0) {
      jumpFramesRemaining--;
      if (jumpFramesRemaining <= 0) {
        jumpPhase = 0;
        jumpFramesRemaining = 0;
      } else if (velocity.y > 0 && jumpPhase == 1) {
        jumpPhase = 2; // Peak
      } else if (velocity.y < 0 && jumpPhase == 1) {
        jumpPhase = 3; // Falling
      }
    }

    // Animation state
    AnimationState animation;
    if (!isGrounded) {
      animation = jumpPhase == 1
          ? AnimationState.jumpRise
          : AnimationState.jumpFall;
    } else if (currentState.velocity.length > 0.1) {
      animation = AnimationState.walk;
    } else {
      animation = AnimationState.idle;
    }

    state = currentState.copyWith(
      position: newPosition,
      velocity: newVelocity,
      isGrounded: isGrounded,
      jumpPhase: jumpPhase,
      jumpFramesRemaining: jumpFramesRemaining,
      animation: animation,
    );
  }

  Vector2 _directionToVector(Direction8 direction) {
    final offsets = Direction8.values.map((d) => d.vector).toList();
    return offsets[direction.index];
  }
}

/// Provider for Head character state.
final headProvider =
    StateNotifierProvider<CharacterStateNotifier, CharacterState>((ref) {
      return CharacterStateNotifier(
        initialState: CharacterState.initial(
          type: CharacterType.head,
          startPosition: Vector3(1, 1, 0),
        ),
      );
    });

/// Provider for Heels character state.
final heelsProvider =
    StateNotifierProvider<CharacterStateNotifier, CharacterState>((ref) {
      return CharacterStateNotifier(
        initialState: CharacterState.initial(
          type: CharacterType.heels,
          startPosition: Vector3(2, 2, 0),
        ),
      );
    });
