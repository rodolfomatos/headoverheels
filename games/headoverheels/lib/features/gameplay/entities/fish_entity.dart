// Reincarnation fish entity for Head over Heels.

import 'package:collection/collection.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show Color, Paint;
import 'package:headoverheels/features/gameplay/entities/character_component.dart';
import 'package:headoverheels/features/gameplay/entities/puzzle_entity.dart';
import 'package:headoverheels/features/gameplay/room/room_component.dart';

/// Reincarnation fish entity - checkpoint when alive, poison when dead.
class FishEntity extends PuzzleEntity {
  bool _isAlive;
  final Vector3 _checkpointPosition;

  FishEntity({
    required super.id,
    required super.triggerZone,
    bool isAlive = true,
  }) : _isAlive = isAlive,
       _checkpointPosition = triggerZone.position;

  @override
  void onLoad() {
    super.onLoad();
    // Visual indicator for fish
    add(
      RectangleComponent(
        size: size * 0.6,
        anchor: Anchor.center,
        paint: Paint()
          ..color = _isAlive
              ? const Color(0xFF00FFFF)
              : const Color(0xFF888888),
      ),
    );
  }

  @override
  void onInteract(CharacterComponent character) {
    if (_isAlive) {
      _eatFish(character);
    } else {
      _poisonCharacter(character);
    }
  }

  void _eatFish(CharacterComponent character) {
    // Save checkpoint position in room state
    final room = _findRoom();
    if (room != null) {
      room.updateState(
        room.state.copyWith(eatenFish: {...room.state.eatenFish, id}),
      );
    }

    // Save checkpoint in game state (handled by game system)
    _isAlive = false;

    // Update visual
    final rect = children.whereType<RectangleComponent>().firstOrNull;
    rect?.paint.color = const Color(0xFF888888);
  }

  void _poisonCharacter(CharacterComponent character) {
    // Damage character unless invulnerable
    if (!character.currentState.isInvulnerable) {
      // Kill character - handled by game system
    }
  }

  RoomComponent? _findRoom() {
    return game.currentRoom;
  }

  @override
  void updatePuzzle(double dt) {}

  bool get isAlive => _isAlive;
  Vector3 get checkpointPosition => _checkpointPosition;
}
