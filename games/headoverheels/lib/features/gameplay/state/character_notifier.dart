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
      // Not the vertical: a party in the air keeps falling whether or not the
      // player is holding a direction.
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
      // Upward, on z. It used to be a negative y velocity, on a plane where y
      // is a tile row, so jumping moved the party north and gravity moved it
      // south. Both were the same mistake in the same place.
      verticalVelocity: state.jumpHeight / (state.jumpDurationFrames / 60.0),
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

    // Gravity acts on z and nowhere else. It acted on y, which is a tile row,
    // so the party was pushed south every frame at an accelerating rate and
    // `stop()` could not clear it: the velocity was zeroed and gravity put it
    // back on the next tick. The tile plane is flat, and nothing in this game
    // moves the party along a row because it fell.
    final vertical = currentState.verticalVelocity - (9.8 * dt * 60.0);

    // Walk across the tile plane, which is x and y only.
    final newPosition = Vector3(
      currentState.position.x + currentState.velocity.x * dt,
      currentState.position.y + currentState.velocity.y * dt,
      currentState.position.z + vertical * dt,
    );

    // Grounded means on the floor, which is z == 0. Landing clamps it, so a
    // party that overshoots does not keep sinking through the room.
    final isGrounded = newPosition.z <= 0;
    // Landing clears the *vertical*, never the walk. It used to be
    // `isGrounded ? Vector2.zero() : velocity`, which zeroed both axes, so a
    // party standing on the floor could not walk at all: every tick found it
    // grounded and threw its walk velocity away.
    final newVelocity = currentState.velocity;
    final clampedZ = isGrounded ? 0.0 : newPosition.z;
    final newVertical = isGrounded ? 0.0 : vertical;

    // Jump phase update
    int jumpPhase = currentState.jumpPhase;
    int jumpFramesRemaining = currentState.jumpFramesRemaining;

    if (jumpPhase > 0) {
      jumpFramesRemaining--;
      if (jumpFramesRemaining <= 0) {
        jumpPhase = 0;
        jumpFramesRemaining = 0;
      } else if (vertical <= 0 && jumpPhase == 1) {
        // Upward speed has run out: the apex. It read `velocity.y > 0`, which
        // on a tile row is "moving south", so the party reached its peak while
        // falling and started falling while rising.
        jumpPhase = 2;
      } else if (jumpPhase == 2 && vertical < 0) {
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
      position: Vector3(newPosition.x, newPosition.y, clampedZ),
      velocity: newVelocity,
      verticalVelocity: newVertical,
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
