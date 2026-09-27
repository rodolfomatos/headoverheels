// Dual character notifier for Head over Heels - manages Head/Heels swapping.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:headoverheels/entities/character_state.dart';
import 'package:headoverheels/features/gameplay/state/character_notifier.dart';

/// Notifier for the dual-character system (Head + Heels).
class DualCharacterNotifier extends StateNotifier<DualCharacterState> {
  DualCharacterNotifier({
    required CharacterState initialHead,
    required CharacterState initialHeels,
  }) : super(
         DualCharacterState.initial(
           headStart: initialHead.position,
           heelsStart: initialHeels.position,
         ),
       ) {
    // Initialize with provided states
    state = state.copyWith(head: initialHead, heels: initialHeels);
  }

  /// Swap control between Head and Heels (or combine/separate).
  void swop() {
    if (state.areCombined) {
      // Separate - default to controlling Head
      state = state.separate(controlWhich: ControlledEntity.head);
    } else {
      // Toggle between Head and Heels
      final next = state.controlled == ControlledEntity.head
          ? ControlledEntity.heels
          : ControlledEntity.head;
      state = state.copyWith(controlled: next);
    }
  }

  /// Combine characters (Head on Heels).
  void combine() {
    state = state.combine();
  }

  /// Separate characters.
  void separate({required ControlledEntity controlWhich}) {
    state = state.separate(controlWhich: controlWhich);
  }

  /// Update both character states from their notifiers.
  void syncFromNotifiers(CharacterState headState, CharacterState heelsState) {
    state = state.copyWith(head: headState, heels: heelsState);
  }
}

/// Provider for dual character state management.
final dualCharacterProvider =
    StateNotifierProvider<DualCharacterNotifier, DualCharacterState>((ref) {
      final headState = ref.watch(headProvider);
      final heelsState = ref.watch(heelsProvider);

      return DualCharacterNotifier(
        initialHead: headState,
        initialHeels: heelsState,
      );
    });
