// Switch entity for Head over Heels.

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' show Color;
import 'package:headoverheels/entities/character_state.dart';
import 'package:headoverheels/features/gameplay/entities/character_component.dart';
import 'package:headoverheels/features/gameplay/entities/puzzle_entity.dart';

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
  void onLoad() async {
    super.onLoad();
    await showManifestSprite('switch');
    _showState();
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
    _showState();
  }

  /// A thrown switch is a tint, the way a coloured rectangle used to be one.
  /// `null` and not a transparent colour, because a modulate filter with an
  /// alpha of zero erases the sprite: a switch that had not been thrown was
  /// tinted to nothing, which is why an unthrown switch was not on the screen.
  void _showState() => tint(isOn ? _thrownTint : null);

  /// Green for a thrown switch. The rectangle had it the other way round, which
  /// is not a thing anyone can read.
  static const Color _thrownTint = Color(0xFF44FF44);

  void _notifyTarget() {
    // Find target entity in the same room
    final room = game.currentRoom;
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

  @override
  void onSwitchToggled(bool isOn, String switchId) {
    setActive(isOn);
  }
}
