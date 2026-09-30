// Guardian entity for Head over Heels.

import 'package:flutter/material.dart' show Color;
import 'package:headoverheels/core/isometric.dart';
import 'package:headoverheels/features/gameplay/entities/character_component.dart';
import 'package:headoverheels/features/gameplay/entities/monster_entity.dart';

/// Guardian entity - blocks throne room, immune to doughnuts, defeated by 4
/// crowns of its own planet.
///
/// The crowns have to be the throne room's own. Counting every crown the party
/// had picked up let a player who never set foot on the planet beat its
/// guardian, and one who had four of that planet's could not.
class GuardianEntity extends MonsterEntity {
  /// What a throne room asks for.
  static const int requiredCrowns = 4;

  /// The planet whose throne room this guardian guards.
  final String planetId;

  GuardianEntity({
    required super.id,
    required super.triggerZone,
    required super.patrolPoints,
    required this.planetId,
  });

  @override
  void onLoad() async {
    super.onLoad();
    // The guardian has art of its own, and it is bigger than a monster: the
    // purple rectangle it used to be was a shade on a red one.
    final sprite = await showManifestSprite('guardian');
    sprite?.size = size * 1.2;
  }

  @override
  void freeze(int frames) {
    // Immune to doughnut freeze
    // Visual feedback: flash red, the one thing about a monster a player can
    // see past. Now a tint on the sprite rather than a change of colour.
    tint(const Color(0xFFFF0000));
    Future.delayed(const Duration(milliseconds: 200), () {
      // `null`, not a transparent colour: a modulate filter with an alpha of
      // zero erases the sprite rather than leaving it alone.
      if (!isFrozen) tint(null);
    });
  }

  @override
  void onInteract(CharacterComponent character) {
    // Check if player has required crowns
    final game = this.game;

    final crownCount = game.crownsFor(planetId);
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
