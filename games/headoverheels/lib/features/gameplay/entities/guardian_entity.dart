// Guardian entity for Head over Heels.

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:headoverheels/core/isometric.dart';
import 'package:headoverheels/features/gameplay/entities/character_component.dart';
import 'package:headoverheels/features/gameplay/entities/monster_entity.dart';

/// Guardian entity - blocks throne room, immune to doughnuts, defeated by 4 crowns.
class GuardianEntity extends MonsterEntity {
  static const int requiredCrowns = 4;

  GuardianEntity({
    required super.id,
    required super.triggerZone,
    required super.patrolPoints,
  });

  @override
  void onLoad() {
    super.onLoad();
    // Visual: larger, distinct appearance (purple)
    final rect = children.whereType<RectangleComponent>().firstOrNull;
    rect?.size = size * 1.2;
    rect?.paint.color = const Color(0xFF8800FF); // Purple
  }

  @override
  void freeze(int frames) {
    // Immune to doughnut freeze
    // Visual feedback: flash red
    final rect = children.whereType<RectangleComponent>().firstOrNull;
    rect?.paint.color = const Color(0xFFFF0000);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!isFrozen) {
        rect?.paint.color = const Color(0xFF8800FF);
      }
    });
  }

  @override
  void onInteract(CharacterComponent character) {
    // Check if player has required crowns
    final game = this.game;

    final crownCount = game.crownsCollected;
    if (crownCount >= requiredCrowns) {
      _defeatGuardian();
    } else {
      // Block passage - push character back
      _blockPassage(character);
    }
  }

  void _defeatGuardian() {
    // Guardian defeated - remove from room
    removeFromParent();
    // Notify game
    final game = this.game;
    game.onGuardianDefeated();
  }

  void _blockPassage(CharacterComponent character) {
    // Push character back slightly
    final direction = (character.position - position).normalized();
    character.position += direction * (IsometricCoordinates.tileWidth * 0.5);
  }

  @override
  void onEnter(CharacterComponent character) {
    // Guardian blocks - treat as solid wall
    if (!isFrozen) {
      // Push back
      final direction = (character.position - position).normalized();
      character.position += direction * (IsometricCoordinates.tileWidth * 0.3);
    }
  }
}

/// Interface for games that can notify guardian defeat.
abstract class GuardianDefeatedNotifier {
  void onGuardianDefeated();
}
