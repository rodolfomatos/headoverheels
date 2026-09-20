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

  CharacterComponent({
    required this.type,
    required this.ref,
  }) : super(
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

    // Initialize sprite animation component with real sprites from registry
    _animation = SpriteAnimationComponent(size: size, anchor: Anchor.center);
    add(_animation);

    // Initialize sprite registry and load animations
    await SpriteRegistry().initialize();

    // Listen to state changes via Riverpod's ref.listen
    final provider = type == CharacterType.head ? headProvider : heelsProvider;
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

  /// Get the grid position of this character.
  Vector3 get gridPosition {
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