// Switch entity for Head over Heels.

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/painting.dart' show Color, Paint;
import 'package:headoverheels/core/isometric.dart';
import 'package:headoverheels/entities/character_state.dart';
import 'package:headoverheels/features/gameplay/entities/character_component.dart';
import 'package:headoverheels/features/gameplay/entities/puzzle_entity.dart';
import 'package:headoverheels/features/gameplay/room/room_component.dart';

/// Switch entity - toggles target on/off when activated.
class SwitchEntity extends PuzzleEntity {
  final String targetId;
  bool isOn;
  final double activationCooldown;
  double _cooldownTimer;

  SwitchEntity({
    required super.id,
    required super.triggerZone,
    required this.targetId,
    this.isOn = false,
    this.activationCooldown = 0.5, // seconds
  }) : _cooldownTimer = 0;

  @override
  void onLoad() {
    super.onLoad();
    // Visual indicator for switch state
    add(
      RectangleComponent(
        size: size * 0.6,
        anchor: Anchor.center,
        paint: Paint()
          ..color = isOn ? const Color(0xFF00FF00) : const Color(0xFFFF0000),
      ),
    );
  }

  @override
  void updatePuzzle(double dt) {
    if (_cooldownTimer > 0) {
      _cooldownTimer -= dt;
    }
  }

  @override
  void onInteract(CharacterComponent character) {
    if (_cooldownTimer > 0) return;

    // Only Heels or Combined can activate switches (push action)
    if (!character.canCarry && character.type != CharacterType.combined) {
      return; // Head alone cannot push switches
    }

    _toggle();
    _cooldownTimer = activationCooldown;

    // Notify target entity
    _notifyTarget();
  }

  void _toggle() {
    isOn = !isOn;
    // Update visual
    final rect = children.whereType<RectangleComponent>().firstOrNull;
    rect?.paint.color = isOn
        ? const Color(0xFF00FF00)
        : const Color(0xFFFF0000);
  }

  void _notifyTarget() {
    // Find target entity in the same room
    // ignore: undefined_identifier
    final room = gameRef.world.children.whereType<RoomComponent>().firstOrNull;
    if (room == null) return;

    final target = room.entities.whereType<PuzzleEntity>().firstWhereOrNull(
      (e) => e.id == targetId,
    );

    if (target != null) {
      target.onSwitchToggled(isOn, id);
    }
  }

  @override
  void onEnter(CharacterComponent character) {
    // Highlight switch when character is on it
  }

  @override
  void onExit(CharacterComponent character) {
    // Remove highlight
  }
}

/// Mixin for entities that can be toggled by switches.
mixin Togglable on PuzzleEntity {
  bool get isActive;
  void setActive(bool active);

  void onSwitchToggled(bool isOn, String switchId) {
    setActive(isOn);
  }
}
