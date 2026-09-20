// Base puzzle entity component for Head over Heels.

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:headoverheels/core/isometric.dart';
import 'package:headoverheels/features/gameplay/entities/character_component.dart';
import 'package:headoverheels/features/gameplay/room/room_graph.dart';

/// Base class for all puzzle entities.
abstract class PuzzleEntity extends PositionComponent
    with CollisionCallbacks, HasGameReference {
  final String id;
  final TriggerZone triggerZone;

  PuzzleEntity({required this.id, required this.triggerZone})
    : super(
        position: IsometricCoordinates.gridToScreen(triggerZone.position),
        size: Vector2(
          triggerZone.size.x * IsometricCoordinates.tileWidth,
          triggerZone.size.y * IsometricCoordinates.tileHeight,
        ),
        anchor: Anchor.center,
      );

  @override
  void onLoad() {
    add(RectangleHitbox()..collisionType = CollisionType.passive);
    super.onLoad();
  }

  /// Called when character interacts (presses action key while overlapping).
  void onInteract(CharacterComponent character);

  /// Called when character enters trigger zone.
  void onEnter(CharacterComponent character) {}

  /// Called when character exits trigger zone.
  void onExit(CharacterComponent character) {}

  /// Update logic (called every frame).
  void updatePuzzle(double dt) {}
}
