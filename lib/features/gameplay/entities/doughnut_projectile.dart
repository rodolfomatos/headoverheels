// Doughnut projectile for Head over Heels.

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/painting.dart' show Color, Paint;
import 'package:headoverheels/core/isometric.dart';
import 'package:headoverheels/features/gameplay/entities/character_component.dart';
import 'package:headoverheels/features/gameplay/entities/monster_entity.dart';
import 'package:headoverheels/features/gameplay/entities/puzzle_entity.dart';
import 'package:headoverheels/features/gameplay/room/room_component.dart';

/// Doughnut projectile fired by Head - homing, freezes monsters.
class DoughnutProjectile extends PositionComponent
    with CollisionCallbacks, HasGameReference {
  static const double speed = 8.0; // tiles/sec
  static const int lifetimeFrames = 180; // 3 seconds @ 60Hz
  static const double homingRange = 8.0; // tiles

  int _frameCount;
  MonsterEntity? _target;

  DoughnutProjectile({required Vector3 startPosition})
    : _frameCount = 0,
      super(
        position: IsometricCoordinates.gridToScreen(startPosition),
        size: Vector2(
          IsometricCoordinates.tileWidth * 0.4,
          IsometricCoordinates.tileHeight * 0.4,
        ),
        anchor: Anchor.center,
      );

  @override
  void onLoad() {
    add(RectangleHitbox()..collisionType = CollisionType.passive);
    add(
      RectangleComponent(
        size: size,
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFFFF8800),
      ),
    );
    super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    _frameCount++;
    if (_frameCount >= lifetimeFrames) {
      removeFromParent();
      return;
    }

    _findTarget();
    _moveTowardsTarget(dt);
  }

  void _findTarget() {
    // ignore: undefined_identifier
    final room = gameRef.world.children.whereType<RoomComponent>().firstOrNull;
    if (room == null) return;

    if (_target != null && !_target!.isFrozen) return;

    MonsterEntity? nearest;
    double nearestDist = homingRange * IsometricCoordinates.tileWidth;

    for (final monster in room.entities.whereType<MonsterEntity>()) {
      if (monster.isFrozen) continue;

      final dist = (monster.position - position).length;
      if (dist < nearestDist) {
        nearestDist = dist;
        nearest = monster;
      }
    }

    _target = nearest;
  }

  void _moveTowardsTarget(double dt) {
    if (_target == null) return;

    final direction = (_target!.position - position).normalized();
    final moveAmount = speed * IsometricCoordinates.tileWidth * dt;
    position += direction * moveAmount;

    // Check collision with target
    if ((_target!.position - position).length <
        IsometricCoordinates.tileWidth * 0.5) {
      _onHitTarget();
    }
  }

  void _onHitTarget() {
    if (_target != null) {
      _target!.freeze(180); // 3 seconds
    }
    removeFromParent();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is MonsterEntity && !other.isFrozen) {
      _onHitTarget();
    }
  }
}
