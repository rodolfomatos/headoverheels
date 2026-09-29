// Crown entity for Head over Heels.

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
  void onLoad() async {
    super.onLoad();
    await showManifestSprite('crown');
  }

  @override
  void onInteract(CharacterComponent character) {
    _collectCrown(character);
  }

  void _collectCrown(CharacterComponent character) {
    // Notify game to collect crown
    final game = this.game;
    game.collectCrown(planetId);
    removeFromParent();
  }

  @override
  void updatePuzzle(double dt) {}
}

/// Interface for games that can collect crowns.
abstract class CrownCollector {
  void collectCrown(String planetId);
}
