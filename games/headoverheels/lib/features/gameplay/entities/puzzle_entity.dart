// Base puzzle entity component for Head over Heels.

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:headoverheels/core/isometric.dart';
import 'package:headoverheels/features/gameplay/entities/character_component.dart';
import 'package:headoverheels/features/gameplay/room/room_graph.dart';
import 'package:headoverheels/features/gameplay/game.dart';

/// Base class for all puzzle entities.
/// A puzzle entity, with the game that owns it.
///
/// The mixin is typed so an entity can reach the game's own API, `currentRoom`
/// and the pickup notifiers, instead of the untyped `game` it gets by default.
abstract class PuzzleEntity extends PositionComponent
    with CollisionCallbacks, HasGameReference<HeadOverHeelsGame> {
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

  /// Called when a switch this entity is wired to is thrown.
  ///
  /// A hook rather than an interface: most puzzle entities do not care, and the
  /// ones that do override it.
  void onSwitchToggled(bool isOn, String switchId) {}
}
