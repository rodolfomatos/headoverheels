// Entity factory for Head over Heels - creates puzzle entities from TMX triggers.

import 'package:headoverheels/core/isometric.dart';
import 'package:headoverheels/features/gameplay/entities/character_component.dart';
import 'package:headoverheels/features/gameplay/entities/puzzle_entity.dart';
import 'package:headoverheels/features/gameplay/entities/switch_entity.dart';
import 'package:headoverheels/features/gameplay/entities/entity_factory_items.dart';
import 'package:headoverheels/features/gameplay/room/room_graph.dart';
import 'package:vector_math/vector_math.dart';

/// Factory for creating puzzle entities from trigger zones.
class EntityFactory {
  /// Create a puzzle entity from a trigger zone.
  static PuzzleEntity? create(TriggerZone trigger, RoomId roomId) {
    switch (trigger.type) {
      case TriggerType.door:
        return _createDoor(trigger, roomId);
      case TriggerType.teleport:
        return _createTeleport(trigger, roomId);
      case TriggerType.ladderUp:
      case TriggerType.ladderDown:
        return _createLadder(trigger, roomId);
      case TriggerType.conveyor:
        return _createConveyor(trigger, roomId);
      case TriggerType.switchTrigger:
        return _createSwitch(trigger, roomId);
      // Delegate new entity types to EntityFactoryItems
      case TriggerType.bag:
      case TriggerType.key:
      case TriggerType.crown:
      case TriggerType.springItem:
      case TriggerType.hushPuppy:
      case TriggerType.monster:
      case TriggerType.guardian:
        return EntityFactoryItems.create(trigger, roomId);
    }
  }

  static PuzzleEntity _createSwitch(TriggerZone trigger, RoomId roomId) {
    final targetId = trigger.exit?.targetEntrance ?? 'default_target';
    return SwitchEntity(
      id: trigger.id,
      triggerZone: trigger,
      targetId: targetId,
      isOn: false,
    );
  }

  static PuzzleEntity _createDoor(TriggerZone trigger, RoomId roomId) {
    // Door entity - handled by room transition system
    return _DoorEntity(
      id: trigger.id,
      triggerZone: trigger,
      targetRoom: trigger.exit?.targetRoom ?? roomId,
      targetEntrance: trigger.exit?.targetEntrance ?? 'default',
      isLocked: trigger.exit?.isLocked ?? false,
      keyId: trigger.exit?.keyId,
    );
  }

  static PuzzleEntity _createTeleport(TriggerZone trigger, RoomId roomId) {
    return _TeleportEntity(
      id: trigger.id,
      triggerZone: trigger,
      targetRoom: trigger.exit?.targetRoom ?? roomId,
      targetEntrance: trigger.exit?.targetEntrance ?? 'default',
      oneWay: trigger.exit?.oneWay ?? false,
    );
  }

  static PuzzleEntity _createLadder(TriggerZone trigger, RoomId roomId) {
    return _LadderEntity(
      id: trigger.id,
      triggerZone: trigger,
      targetLevel: trigger.targetLevel ?? 1,
      isUp: trigger.type == TriggerType.ladderUp,
    );
  }

  static PuzzleEntity _createConveyor(TriggerZone trigger, RoomId roomId) {
    return ConveyorEntity(
      id: trigger.id,
      triggerZone: trigger,
      direction: _exitDirToDirection8(trigger.conveyorDirection ?? ExitDirection.east),
      speed: trigger.conveyorSpeed ?? 2.0, // tiles/sec
    );
  }

  static Direction8 _exitDirToDirection8(ExitDirection dir) {
    switch (dir) {
      case ExitDirection.north:
        return Direction8.north;
      case ExitDirection.south:
        return Direction8.south;
      case ExitDirection.east:
        return Direction8.east;
      case ExitDirection.west:
        return Direction8.west;
      case ExitDirection.up:
      case ExitDirection.down:
        return Direction8.north; // Default
    }
  }
}

/// Door entity - triggers room transition.
class _DoorEntity extends PuzzleEntity {
  final RoomId targetRoom;
  final String targetEntrance;
  final bool isLocked;
  final String? keyId;

  _DoorEntity({
    required super.id,
    required super.triggerZone,
    required this.targetRoom,
    required this.targetEntrance,
    required this.isLocked,
    this.keyId,
  });

  @override
  void onInteract(CharacterComponent character) {
    if (isLocked) {
      // Check if character has key
      final hasKey = character.currentState.carriedItem.map<bool>(
        none: (_) => false,
        key: (key) => key.keyId == keyId,
        crown: (_) => false,
        other: (_) => false,
      );
      if (!hasKey) return;
    }
    
    // Trigger room transition
    _triggerTransition(character);
  }

  void _triggerTransition(CharacterComponent character) {
    // Room transition handled by game system
    // This would emit an event to the game manager
  }

  @override
  void updatePuzzle(double dt) {}
}

/// Teleport entity - instant room transition.
class _TeleportEntity extends PuzzleEntity {
  final RoomId targetRoom;
  final String targetEntrance;
  final bool oneWay;

  _TeleportEntity({
    required super.id,
    required super.triggerZone,
    required this.targetRoom,
    required this.targetEntrance,
    required this.oneWay,
  });

  @override
  void onEnter(CharacterComponent character) {
    // Warn with siren sound (visual indicator for now)
    // Actual teleport on jump press
  }

  @override
  void onInteract(CharacterComponent character) {
    if (!character.canJump) return;
    _teleport(character);
  }

  void _teleport(CharacterComponent character) {
    // Teleport handled by game system
  }

  @override
  void updatePuzzle(double dt) {}
}

/// Ladder entity - vertical movement between levels.
class _LadderEntity extends PuzzleEntity {
  final int targetLevel;
  final bool isUp;

  _LadderEntity({
    required super.id,
    required super.triggerZone,
    required this.targetLevel,
    required this.isUp,
  });

  @override
  void onInteract(CharacterComponent character) {
    if (!character.canClimb) return;
    // Start climbing animation
    _startClimb(character);
  }

  void _startClimb(CharacterComponent character) {
    // Handled by character physics system
  }

  @override
  void updatePuzzle(double dt) {}
}

/// Conveyor belt entity - pushes characters in a direction.
class ConveyorEntity extends PuzzleEntity {
  final Direction8 direction;
  final double speed; // tiles/sec

  ConveyorEntity({
    required super.id,
    required super.triggerZone,
    required this.direction,
    required this.speed,
  });

  @override
  void onEnter(CharacterComponent character) {
    // Apply conveyor velocity to character
    _applyVelocity(character);
  }

  @override
  void onExit(CharacterComponent character) {
    // Remove conveyor velocity
    _removeVelocity(character);
  }

  @override
  void updatePuzzle(double dt) {
    // Continuously apply velocity while character is on conveyor
    // In a real implementation, this would use the collision system
    // For now, we rely on onEnter/onExit for velocity application
  }

  void _applyVelocity(CharacterComponent character) {
    final velocity = _directionToVector(direction) * (speed / 60.0); // Convert to per-frame
    character.position += velocity;
  }

  void _removeVelocity(CharacterComponent character) {
    // Velocity removed when character exits
  }

  Vector2 _directionToVector(Direction8 dir) {
    switch (dir) {
      case Direction8.north:
        return Vector2(0, -1);
      case Direction8.northEast:
        return Vector2(1, -1).normalized();
      case Direction8.east:
        return Vector2(1, 0);
      case Direction8.southEast:
        return Vector2(1, 1).normalized();
      case Direction8.south:
        return Vector2(0, 1);
      case Direction8.southWest:
        return Vector2(-1, 1).normalized();
      case Direction8.west:
        return Vector2(-1, 0);
      case Direction8.northWest:
        return Vector2(-1, -1).normalized();
    }
  }

  @override
  void onInteract(CharacterComponent character) {}
}