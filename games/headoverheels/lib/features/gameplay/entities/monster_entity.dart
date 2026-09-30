// Monster entity for Head over Heels.

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Color;
import 'package:headoverheels/core/isometric.dart';
import 'package:headoverheels/features/gameplay/entities/character_component.dart';
import 'package:headoverheels/features/gameplay/entities/puzzle_entity.dart';
import 'package:headoverheels/features/gameplay/room/room_graph.dart';

/// Monster entity - patrols, kills on touch, freezable by doughnuts.
class MonsterEntity extends PuzzleEntity {
  final List<Vector3> _patrolPoints;
  int _currentPointIndex;
  int _direction; // 1 = forward, -1 = backward
  int _freezeTimer;
  bool _isFrozen;

  MonsterEntity({
    required super.id,
    required TriggerZone triggerZone,
    required List<Vector3> patrolPoints,
  }) : _patrolPoints = patrolPoints,
       _currentPointIndex = 0,
       _direction = 1,
       _freezeTimer = 0,
       _isFrozen = false,
       super(
         triggerZone: triggerZone.copyWith(
           position: patrolPoints.isNotEmpty
               ? patrolPoints.first
               : triggerZone.position,
         ),
       );

  @override
  void onLoad() async {
    super.onLoad();
    // The art the manifest holds, rather than a red rectangle standing in for a
    // monster: the sprite was loaded all along and nothing asked for it.
    await showManifestSprite('monster');
  }

  @override
  void updatePuzzle(double dt) {
    if (_isFrozen) {
      _freezeTimer--;
      if (_freezeTimer <= 0) {
        _isFrozen = false;
        // Back to its own colours, the way a rectangle went back to red.
        // `null`, not a transparent colour: a modulate filter with an alpha of
        // zero multiplies the sprite's own alpha by zero, so a tint meant to
        // say "no tint" was the thing that made the monster disappear.
        tint(null);
      }
      return;
    }

    _patrol(dt);
  }

  void _patrol(double dt) {
    if (_patrolPoints.length < 2) return;

    final targetPoint = _patrolPoints[_currentPointIndex];
    final targetScreen = IsometricCoordinates.gridToScreen(targetPoint);
    final direction = (targetScreen - position).normalized();
    final distance = (targetScreen - position).length;

    const patrolSpeed = 2.0; // tiles/sec
    final moveAmount = patrolSpeed * IsometricCoordinates.tileWidth * dt;

    if (distance <= moveAmount) {
      // Reached waypoint
      position = targetScreen;
      _advancePatrol();
    } else {
      position += direction * moveAmount;
    }
  }

  void _advancePatrol() {
    if (_patrolPoints.length < 2) return;

    _currentPointIndex += _direction;
    if (_currentPointIndex >= _patrolPoints.length - 1) {
      _direction = -1;
      _currentPointIndex = _patrolPoints.length - 2;
    } else if (_currentPointIndex <= 0) {
      _direction = 1;
      _currentPointIndex = 1;
    }
  }

  @override
  void onEnter(CharacterComponent character) {
    if (!_isFrozen && !character.currentState.isInvulnerable) {
      // Kill character
      _killCharacter(character);
    }
  }

  void _killCharacter(CharacterComponent character) {
    // Kill handled by game system
  }

  /// Freeze monster for specified frames.
  void freeze(int frames) {
    _freezeTimer = frames;
    _isFrozen = true;
    // Visual feedback: frozen blue, the way a red rectangle used to turn.
    tint(const Color(0xFF0000FF));
  }

  bool get isFrozen => _isFrozen;

  @override
  void onInteract(CharacterComponent character) {}

  @override
  void onExit(CharacterComponent character) {}
}
