// Hush Puppy entity for Head over Heels.

import 'package:flutter/painting.dart' show Color;
import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:headoverheels/core/isometric.dart';
import 'package:headoverheels/entities/character_state.dart';
import 'package:headoverheels/features/gameplay/entities/character_component.dart';
import 'package:headoverheels/features/gameplay/entities/puzzle_entity.dart';

/// Hush Puppy entity - sleeps, teleports away when Head approaches.
class HushPuppyEntity extends PuzzleEntity {
  static const double detectionRadius = 3.0; // tiles
  static const double returnDelay = 5.0; // seconds

  bool _isAwake;
  double _returnTimer;
  final Vector3 _originalPosition;

  HushPuppyEntity({required super.id, required super.triggerZone})
    : _isAwake = false,
      _returnTimer = 0.0,
      _originalPosition = triggerZone.position;

  @override
  void onLoad() async {
    super.onLoad();
    // The manifest calls it hush_puppy, with an underscore, where the world's
    // trigger is `hushPuppy`. The sprite is looked up by the manifest's name.
    await showManifestSprite('hush_puppy');
    spriteComponent?.size = size * 0.5;
  }

  @override
  void updatePuzzle(double dt) {
    if (!_isAwake) {
      _checkHeadProximity();
    } else {
      _returnTimer -= dt;
      if (_returnTimer <= 0) {
        _goToSleep();
      }
    }
  }

  void _checkHeadProximity() {
    final game = this.game;

    // Find Head character
    final head = game.world.children
        .whereType<CharacterComponent>()
        .firstWhereOrNull((c) => c.type == CharacterType.head);

    if (head != null) {
      final distance = (head.gridPosition - triggerZone.position).length;
      if (distance < detectionRadius) {
        _teleportAway();
      }
    }
  }

  void _teleportAway() {
    final safeTile = _findSafeTile();
    if (safeTile != null) {
      position = IsometricCoordinates.gridToScreen(safeTile);
      // Note: triggerZone is final in PuzzleEntity, so we update position only
      _isAwake = true;
      _returnTimer = returnDelay;

      // Visual: awake color
      // Awake: a tint, where a grey rectangle used to turn green.
      tint(const Color(0xFF44FF44));
    }
  }

  void _goToSleep() {
    _isAwake = false;
    _returnTimer = 0.0;

    // Return to original position
    position = IsometricCoordinates.gridToScreen(_originalPosition);

    // Back to sleeping: a tint, the way a rectangle went back to grey.
    tint(const Color(0xFF888888));
  }

  Vector3? _findSafeTile() {
    final room = game.currentRoom;
    if (room == null) return null;

    // Search in expanding radius for walkable tile
    for (int radius = 1; radius <= 5; radius++) {
      for (int dx = -radius; dx <= radius; dx++) {
        for (int dy = -radius; dy <= radius; dy++) {
          if (dx.abs() == radius || dy.abs() == radius) {
            final tile = Vector3(
              _originalPosition.x + dx,
              _originalPosition.y + dy,
              _originalPosition.z,
            );
            if (room.isWalkable(tile)) {
              return tile;
            }
          }
        }
      }
    }
    return _originalPosition; // Fallback
  }

  @override
  void onInteract(CharacterComponent character) {
    // Hush puppies cannot be interacted with directly
  }

  // updatePuzzle is implemented above
}
