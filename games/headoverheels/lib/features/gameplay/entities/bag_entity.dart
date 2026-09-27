// Bag entity for Head over Heels.

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show Color, Paint;
import 'package:headoverheels/core/isometric.dart';
import 'package:headoverheels/features/gameplay/entities/character_component.dart';
import 'package:headoverheels/features/gameplay/entities/puzzle_entity.dart';

/// Bag entity - pickup once, grants carry ability to Heels.
class BagEntity extends PuzzleEntity {
  bool _isCollected;

  BagEntity({required super.id, required super.triggerZone})
    : _isCollected = false;

  @override
  void onLoad() {
    super.onLoad();
    // Visual indicator for bag
    add(
      RectangleComponent(
        size: size * 0.6,
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFF8B4513), // Brown
      ),
    );
  }

  @override
  void onInteract(CharacterComponent character) {
    if (!character.canCarry) return;
    if (_isCollected) return;

    _collectBag(character);
  }

  void _collectBag(CharacterComponent character) {
    _isCollected = true;
    // Notify character state to update bag possession
    // ignore: undefined_identifier
    final game = gameRef;
    if (game is BagCollector) {
      game.onBagCollected(character);
    }
    removeFromParent();
  }

  @override
  void updatePuzzle(double dt) {}
}

/// Interface for games that can collect bags.
abstract class BagCollector {
  void onBagCollected(CharacterComponent character);
}
