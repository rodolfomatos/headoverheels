// Crown entity for Head over Heels.

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show Color, Paint;
import 'package:headoverheels/core/isometric.dart';
import 'package:headoverheels/features/gameplay/entities/character_component.dart';
import 'package:headoverheels/features/gameplay/entities/puzzle_entity.dart';

/// Crown entity - collectible, win condition (5 total).
class CrownEntity extends PuzzleEntity {
  final String planetId; // egyptus, penitentiary, safari, bookworld, blacktooth

  CrownEntity({
    required super.id,
    required super.triggerZone,
    required this.planetId,
  });

  @override
  void onLoad() {
    super.onLoad();
    // Visual indicator for crown
    add(RectangleComponent(
      size: size * 0.6,
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFFFFD700), // Gold
    ));
  }

  @override
  void onInteract(CharacterComponent character) {
    _collectCrown(character);
  }

  void _collectCrown(CharacterComponent character) {
    // Notify game to collect crown
    // ignore: undefined_identifier
    final game = gameRef;
    if (game is CrownCollector) {
      game.collectCrown(planetId);
    }
    removeFromParent();
  }

  @override
  void updatePuzzle(double dt) {}
}

/// Interface for games that can collect crowns.
abstract class CrownCollector {
  void collectCrown(String planetId);
}