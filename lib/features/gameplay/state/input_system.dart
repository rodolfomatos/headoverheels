// Input system for Head over Heels - connects touch controls to character state.

import 'dart:ui' show Offset;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:headoverheels/core/isometric.dart';
import 'package:headoverheels/entities/character_state.dart';
import 'package:headoverheels/features/gameplay/state/character_notifier.dart';
import 'package:headoverheels/features/gameplay/state/dual_character_notifier.dart';

/// Service that processes input and updates character state.
class InputSystem {
  final Ref ref;

  InputSystem(this.ref);

  /// Convert normalized joystick offset (-1..1) to Direction8.
  Direction8? _offsetToDirection(Offset offset) {
    if (offset == Offset.zero) return null;

    // Convert to angle (0 = north, clockwise)
    final angle = offset.direction - 3.14159265359 / 2; // Rotate so up = north
    return Direction8.fromAngle(angle);
  }

  /// Get the currently controlled character notifier.
  CharacterStateNotifier? get _controlledNotifier {
    final dualState = ref.read(dualCharacterProvider);
    final controlled = dualState.controlled;

    if (controlled == ControlledEntity.head ||
        controlled == ControlledEntity.combined) {
      return ref.read(headProvider.notifier);
    } else if (controlled == ControlledEntity.heels) {
      return ref.read(heelsProvider.notifier);
    }
    return null;
  }

  /// Handle joystick direction change.
  void onJoystickDirection(Offset offset) {
    final notifier = _controlledNotifier;
    if (notifier == null) return;

    final direction = _offsetToDirection(offset);
    if (direction != null) {
      notifier.move(direction);
    } else {
      notifier.stop();
    }
  }

  /// Handle jump action.
  void onJump() {
    final notifier = _controlledNotifier;
    notifier?.jump();
  }

  /// Handle carry action.
  void onCarry() {
    final notifier = _controlledNotifier;
    notifier?.carry();
  }

  /// Handle fire action.
  void onFire() {
    final notifier = _controlledNotifier;
    notifier?.fire();
  }

  /// Handle swop action - switch control between Head and Heels.
  void onSwop() {
    ref.read(dualCharacterProvider.notifier).swop();
  }

  /// Update physics for both characters (called from game loop).
  void updatePhysics(double dt) {
    ref.read(headProvider.notifier).update(dt);
    ref.read(heelsProvider.notifier).update(dt);

    // Sync dual character state
    final headState = ref.read(headProvider);
    final heelsState = ref.read(heelsProvider);
    ref
        .read(dualCharacterProvider.notifier)
        .syncFromNotifiers(headState, heelsState);
  }
}

/// Provider for InputSystem.
final inputSystemProvider = Provider<InputSystem>((ref) {
  return InputSystem(ref);
});
