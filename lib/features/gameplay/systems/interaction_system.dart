// Interaction system for Head over Heels.

import 'dart:ui' show Rect;
import 'package:flame/components.dart';
import 'package:headoverheels/features/gameplay/entities/character_component.dart';
import 'package:headoverheels/features/gameplay/entities/puzzle_entity.dart';

/// Central system for handling character-entity interactions.
class InteractionSystem {
  final List<CharacterComponent> _characters = [];
  final List<PuzzleEntity> _entities = [];

  /// Register a character for interaction tracking.
  void registerCharacter(CharacterComponent character) {
    if (!_characters.contains(character)) {
      _characters.add(character);
    }
  }

  /// Unregister a character.
  void unregisterCharacter(CharacterComponent character) {
    _characters.remove(character);
  }

  /// Register an entity for interaction tracking.
  void registerEntity(PuzzleEntity entity) {
    if (!_entities.contains(entity)) {
      _entities.add(entity);
    }
  }

  /// Unregister an entity.
  void unregisterEntity(PuzzleEntity entity) {
    _entities.remove(entity);
  }

  /// Update all interactions (call every frame).
  void update(double dt) {
    for (final character in _characters) {
      for (final entity in _entities) {
        _checkInteraction(character, entity);
      }
    }
  }

  void _checkInteraction(CharacterComponent character, PuzzleEntity entity) {
    // Simple AABB collision check using position and size
    // This avoids relying on Flame's internal hitbox API
    final characterRect = _getBounds(character);
    final entityRect = _getBounds(entity);

    final colliding = characterRect.overlaps(entityRect);

    if (colliding) {
      if (!_CollisionTracker.wasColliding(entity, character)) {
        _CollisionTracker.setColliding(entity, character, true);
        entity.onEnter(character);
      }
    } else {
      if (_CollisionTracker.wasColliding(entity, character)) {
        _CollisionTracker.setColliding(entity, character, false);
        entity.onExit(character);
      }
    }
  }

  Rect _getBounds(PositionComponent component) {
    return Rect.fromLTWH(
      component.position.x - component.size.x / 2,
      component.position.y - component.size.y / 2,
      component.size.x,
      component.size.y,
    );
  }
}

/// Helper class to track collision state per entity.
class _CollisionTracker {
  static final Map<PuzzleEntity, Map<int, bool>> _collisions = {};

  static bool wasColliding(PuzzleEntity entity, CharacterComponent character) {
    return _collisions[entity]?[character.hashCode] ?? false;
  }

  static void setColliding(
    PuzzleEntity entity,
    CharacterComponent character,
    bool colliding,
  ) {
    _collisions.putIfAbsent(entity, () => {});
    if (colliding) {
      _collisions[entity]![character.hashCode] = true;
    } else {
      _collisions[entity]!.remove(character.hashCode);
    }
  }
}
