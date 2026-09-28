// Item and entity factory extensions for Head over Heels.

import 'package:headoverheels/entities/character_state.dart';
import 'package:headoverheels/features/gameplay/entities/bag_entity.dart';
import 'package:headoverheels/features/gameplay/entities/crown_entity.dart';
import 'package:headoverheels/features/gameplay/entities/dropped_item_entity.dart';
import 'package:headoverheels/features/gameplay/entities/guardian_entity.dart';
import 'package:headoverheels/features/gameplay/entities/hush_puppy_entity.dart';
import 'package:headoverheels/features/gameplay/entities/monster_entity.dart';
import 'package:headoverheels/features/gameplay/entities/puzzle_entity.dart';
import 'package:headoverheels/features/gameplay/room/room_graph.dart';
import 'package:vector_math/vector_math.dart';

/// Factory extensions for creating item and special entities from trigger zones.
class EntityFactoryItems {
  /// Create a puzzle entity from a trigger zone (item/special entities).
  static PuzzleEntity? create(TriggerZone trigger, RoomId roomId) {
    switch (trigger.type) {
      case TriggerType.bag:
        return _createBag(trigger, roomId);
      case TriggerType.key:
        return _createKey(trigger, roomId);
      case TriggerType.crown:
        return _createCrown(trigger, roomId);
      case TriggerType.springItem:
        return _createSpringItem(trigger, roomId);
      case TriggerType.hushPuppy:
        return _createHushPuppy(trigger, roomId);
      case TriggerType.monster:
        return _createMonster(trigger, roomId);
      case TriggerType.guardian:
        return _createGuardian(trigger, roomId);
      default:
        return null;
    }
  }

  static PuzzleEntity _createBag(TriggerZone trigger, RoomId roomId) {
    return BagEntity(id: trigger.id, triggerZone: trigger);
  }

  static PuzzleEntity _createKey(TriggerZone trigger, RoomId roomId) {
    return DroppedItemEntity(
      id: trigger.id,
      triggerZone: trigger,
      item: CarriedItem.key(trigger.id),
    );
  }

  static PuzzleEntity _createCrown(TriggerZone trigger, RoomId roomId) {
    // The key is `planetId`, the same one the crowns and the guardians carry.
    // This read `planet`, a key no trigger in the world has, and fell back to
    // `castle`: every crown in the game was credited to Blacktooth, so the four
    // that opened a throne room opened the castle one and nothing else could
    // ever open theirs.
    final planetId = trigger.properties?['planetId'] as String?;
    if (planetId == null || planetId.isEmpty) {
      throw StateError(
        'The crown ${trigger.id} in $roomId does not say which planet it is '
        'for: its trigger needs a planetId.',
      );
    }
    return CrownEntity(
      id: trigger.id,
      triggerZone: trigger,
      planetId: planetId,
    );
  }

  static PuzzleEntity _createSpringItem(TriggerZone trigger, RoomId roomId) {
    return DroppedItemEntity(
      id: trigger.id,
      triggerZone: trigger,
      item: CarriedItem.other('spring'),
    );
  }

  static PuzzleEntity _createHushPuppy(TriggerZone trigger, RoomId roomId) {
    return HushPuppyEntity(id: trigger.id, triggerZone: trigger);
  }

  static PuzzleEntity _createMonster(TriggerZone trigger, RoomId roomId) {
    // Parse patrol points from properties
    final patrolPoints = _parsePatrolPoints(trigger.properties);
    return MonsterEntity(
      id: trigger.id,
      triggerZone: trigger,
      patrolPoints: patrolPoints,
    );
  }

  static PuzzleEntity _createGuardian(TriggerZone trigger, RoomId roomId) {
    final patrolPoints = _parsePatrolPoints(trigger.properties);
    // A guardian without a planet would count every crown in the game, so the
    // data has to say which throne room it guards.
    final planetId = trigger.properties?['planetId'] as String?;
    if (planetId == null || planetId.isEmpty) {
      throw StateError(
        'The guardian ${trigger.id} in $roomId does not say which planet it '
        'guards: its trigger needs a planetId.',
      );
    }
    return GuardianEntity(
      id: trigger.id,
      triggerZone: trigger,
      patrolPoints: patrolPoints,
      planetId: planetId,
    );
  }

  static List<Vector3> _parsePatrolPoints(Map<String, dynamic>? properties) {
    if (properties == null) return [];
    final pointsStr = properties['patrolPoints'] as String?;
    if (pointsStr == null) return [];

    // Parse format: "(x1,y1,z1),(x2,y2,z2),..."
    final points = <Vector3>[];
    final regex = RegExp(r'\((-?\d+),(-?\d+),(-?\d+)\)');
    for (final match in regex.allMatches(pointsStr)) {
      points.add(
        Vector3(
          double.parse(match.group(1)!),
          double.parse(match.group(2)!),
          double.parse(match.group(3)!),
        ),
      );
    }
    return points;
  }
}
