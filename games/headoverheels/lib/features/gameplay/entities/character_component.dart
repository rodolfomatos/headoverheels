// Character component for Head over Heels.

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:headoverheels/core/assets/sprite_registry.dart';
import 'package:headoverheels/core/assets/visual_state_resolver.dart';
import 'package:headoverheels/core/isometric.dart';
import 'package:headoverheels/entities/character_state.dart';
import 'package:headoverheels/features/gameplay/state/character_notifier.dart';

/// Character component that renders and syncs with Riverpod state.
class CharacterComponent extends PositionComponent with CollisionCallbacks {
  final CharacterType type;
  final Ref ref;

  late SpriteAnimationComponent _animation;

  CharacterComponent({required this.type, required this.ref})
    : super(
        position: Vector2.zero(),
        size: Vector2(
          IsometricCoordinates.tileWidth * 0.8,
          IsometricCoordinates.tileHeight * 0.8,
        ),
        anchor: Anchor.center,
      );

  @override
  Future<void> onLoad() async {
    // Add hitbox for collision
    add(RectangleHitbox()..collisionType = CollisionType.passive);

    // The art, centred in this component's box.
    //
    // A `PositionComponent` with `Anchor.center` moves the canvas by
    // `position - size / 2`, and a child with `Anchor.center` moves it by
    // `-size / 2` again. Both did, so the sprite was drawn at
    // `position - size`: a whole box up and to the left of where the character
    // stands. The character's world x is negative over the left half of a room,
    // so half a room put the party off the side of the screen. Measured: the
    // party drew 0 pixels, and 12 of the room's 16 entities with it.
    //
    // The art starts at this component's centre, so between the two of them
    // there is exactly one subtraction, and the art can be any size and stay
    // centred on the character.
    _animation = SpriteAnimationComponent(
      position: size / 2,
      size: size,
      anchor: Anchor.center,
    );
    add(_animation);

    final provider = type == CharacterType.head ? headProvider : heelsProvider;
    final registry = SpriteRegistry();
    // Only the animation this character stands in while the game is arriving.
    // The registry used to load all 65 entries here, and then a character's
    // twelve: both made the first frame wait for sprites nobody was looking at.
    await registry.loadCharacter(_spriteKeyFor(type));

    // When the rest of the manifest arrives, take up the animation the state
    // asks for. The state does not change by itself, so without this a
    // character would stand in idle for ever.
    registry.addLoadListener(() {
      if (isMounted) _syncFromState(ref.read(provider));
    });

    // Listen to state changes via Riverpod's ref.listen
    ref.listen(provider, (_, next) {
      _syncFromState(next);
    });
    _syncFromState(ref.read(provider));

    super.onLoad();
  }

  @override
  void onRemove() {
    // No subscription to clean up with ref.listen
    super.onRemove();
  }

  void _syncFromState(CharacterState state) {
    // Convert grid position to screen
    position = IsometricCoordinates.gridToScreen(state.position);

    // Resolve the correct animation asset ID based on state
    final assetId = VisualStateResolver.resolveCharacterAssetId(
      characterType: state.type,
      animation: state.animation,
      facing: state.facing,
      isCombined: state.type == CharacterType.combined,
    );

    // Load and set the correct animation
    final animation = SpriteRegistry().getCharacterAnimation(assetId);
    if (animation != null) {
      _animation.animation = animation;
    }

    // Update facing direction if needed (for sprite sheet row selection)
    // The sprite sheet row is determined by FacingDirection.spriteRow
  }

  /// The tile this character is on.
  ///
  /// Integral, deliberately. It used to return `position`, a `Vector3` of doubles,
  /// so a single frame moved 0.001 tiles and rounded to the same integer -- which
  /// is why every movement test needed sixty frames to see anything, and why an
  /// assertion of "x increased" would have passed for a hundredth of a tile of
  /// drift as readily as for a tile of movement.
  ///
  /// `position` keeps the fraction and is what the renderer draws with. A tile
  /// index and a fraction of a tile are two different values and the name was
  /// disagreeing with the one it returned. See D011.
  Vector3 get gridPosition {
    final exact = exactPosition;
    return Vector3(
      exact.x.roundToDouble(),
      exact.y.roundToDouble(),
      exact.z.roundToDouble(),
    );
  }

  /// Where this character actually is, to the pixel.
  ///
  /// For rendering and for animation. Anything that asks "which tile" wants
  /// [gridPosition]; anything that asks "how far along the tile" wants this.
  ///
  /// Named `exactPosition` because `position` is already Flame's own `Vector2`
  /// on this component, and shadowing it would break the transform.
  Vector3 get exactPosition {
    final provider = type == CharacterType.head ? headProvider : heelsProvider;
    return ref.read(provider).position;
  }

  /// Check if this character can perform an action.
  bool get canJump {
    final provider = type == CharacterType.head ? headProvider : heelsProvider;
    return ref.read(provider).canJump;
  }

  bool get canFire {
    final provider = type == CharacterType.head ? headProvider : heelsProvider;
    return ref.read(provider).canFire;
  }

  bool get canCarry {
    final provider = type == CharacterType.head ? headProvider : heelsProvider;
    return ref.read(provider).canCarry;
  }

  bool get canClimb {
    final provider = type == CharacterType.head ? headProvider : heelsProvider;
    return ref.read(provider).canClimb;
  }

  /// Get the current state for rendering
  CharacterState get currentState {
    final provider = type == CharacterType.head ? headProvider : heelsProvider;
    return ref.read(provider);
  }
}

/// The name the manifest gives a character's sprites: `head`, `heels` or `duo`.
String _spriteKeyFor(CharacterType type) => switch (type) {
  CharacterType.head => 'head',
  CharacterType.heels => 'heels',
  CharacterType.combined => 'duo',
};
