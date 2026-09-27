// Visual State Resolver for Head over Heels
// Maps game state to visual asset IDs.

import 'package:headoverheels/entities/character_state.dart';

/// Resolves game state to visual asset IDs.
class VisualStateResolver {
  /// Resolve the visual asset ID for a character.
  static String resolveCharacterAssetId({
    required CharacterType characterType,
    required AnimationState animation,
    required FacingDirection facing,
    bool isCombined = false,
  }) {
    final character = _characterTypeToString(characterType);
    final animationStr = _animationStateToString(animation);
    final direction = _facingDirectionToString(facing);

    if (isCombined) {
      return 'character.duo.$animationStr';
    }

    return 'character.$character.$animationStr.$direction';
  }

  /// Resolve entity asset ID.
  static String resolveEntityAssetId({
    required String entityType,
    required String animation,
    String direction = '',
  }) {
    if (direction.isEmpty) {
      return 'entity.$entityType.$animation';
    }
    return 'entity.$entityType.$animation.$direction';
  }

  /// Resolve tile asset ID.
  static String resolveTileAssetId({
    required String theme,
    required String tileType,
    String variant = '',
  }) {
    if (variant.isEmpty) {
      return 'tile.$theme.$tileType';
    }
    return 'tile.$theme.$tileType.$variant';
  }

  /// Resolve UI asset ID.
  static String resolveUIAssetId(String element) {
    return 'ui.$element';
  }

  /// Resolve effect asset ID.
  static String resolveEffectAssetId(String effect, int frame) {
    return 'fx.$effect.$frame';
  }

  static String _characterTypeToString(CharacterType type) {
    switch (type) {
      case CharacterType.head:
        return 'head';
      case CharacterType.heels:
        return 'heels';
      case CharacterType.combined:
        return 'duo';
    }
  }

  static String _animationStateToString(AnimationState animation) {
    switch (animation) {
      case AnimationState.idle:
        return 'idle';
      case AnimationState.walk:
        return 'walk';
      case AnimationState.jumpRise:
        return 'jumpRise';
      case AnimationState.jumpPeak:
        return 'jumpPeak';
      case AnimationState.jumpFall:
        return 'jumpFall';
      case AnimationState.land:
        return 'land';
      case AnimationState.climb:
        return 'climb';
      case AnimationState.carry:
        return 'carry';
      case AnimationState.fire:
        return 'fire';
      case AnimationState.swop:
        return 'swop';
      case AnimationState.hurt:
        return 'hurt';
      case AnimationState.death:
        return 'death';
    }
  }

  static String _facingDirectionToString(FacingDirection facing) {
    switch (facing) {
      case FacingDirection.north:
        return 'n';
      case FacingDirection.northEast:
        return 'ne';
      case FacingDirection.east:
        return 'e';
      case FacingDirection.southEast:
        return 'se';
      case FacingDirection.south:
        return 's';
      case FacingDirection.southWest:
        return 'sw';
      case FacingDirection.west:
        return 'w';
      case FacingDirection.northWest:
        return 'nw';
    }
  }
}
