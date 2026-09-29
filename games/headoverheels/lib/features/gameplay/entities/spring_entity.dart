// Spring entity for Head over Heels.

import 'package:headoverheels/features/gameplay/entities/character_component.dart';
import 'package:headoverheels/features/gameplay/entities/puzzle_entity.dart';

/// Spring entity - boosts jump height when jumped from.
class SpringEntity extends PuzzleEntity {
  static const double boostMultiplier = 1.5;
  bool _isCompressed;

  SpringEntity({required super.id, required super.triggerZone})
    : _isCompressed = false;

  @override
  void onLoad() async {
    super.onLoad();
    await showManifestSprite('spring');
    spriteComponent?.size = size * 0.8;
  }

  @override
  void onEnter(CharacterComponent character) {
    // Character is on spring - ready to boost
    _isCompressed = true;
    // Visual feedback: the spring squashes under the party, as it did when it
    // was a rectangle.
    spriteComponent?.size = size * 0.5;
  }

  @override
  void onExit(CharacterComponent character) {
    _isCompressed = false;
    spriteComponent?.size = size * 0.8;
  }

  @override
  void onInteract(CharacterComponent character) {
    // Spring activates on jump - handled by character physics
    // This is called when character presses jump while on spring
    if (character.canJump && _isCompressed) {
      _applyBoost(character);
    }
  }

  void _applyBoost(CharacterComponent character) {
    // Boost is applied in character physics system
    // This entity just marks that boost is available
  }

  @override
  void updatePuzzle(double dt) {}

  /// Check if spring is currently compressed (character standing on it).
  bool get isCompressed => _isCompressed;
}
