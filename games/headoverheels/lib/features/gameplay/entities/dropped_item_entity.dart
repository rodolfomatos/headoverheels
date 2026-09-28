// Dropped item entity for Head over Heels.

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Color, Icons, IconData;
import 'package:flutter/painting.dart' show Color, Paint;
import 'package:headoverheels/features/gameplay/entities/character_component.dart';
import 'package:headoverheels/features/gameplay/entities/puzzle_entity.dart';
import 'package:headoverheels/features/gameplay/state/character_notifier.dart';
import 'package:headoverheels/entities/character_state.dart';

/// Dropped item entity - can be picked up by Heels.
class DroppedItemEntity extends PuzzleEntity {
  final CarriedItem item;

  DroppedItemEntity({
    required super.id,
    required super.triggerZone,
    required this.item,
  });

  @override
  void onLoad() {
    super.onLoad();
    // Visual indicator based on item type
    final (icon, color) = _getItemVisual(item);
    add(
      RectangleComponent(
        size: size * 0.5,
        anchor: Anchor.center,
        paint: Paint()..color = color,
      ),
    );
  }

  @override
  void onInteract(CharacterComponent character) {
    if (!character.canCarry) return;

    final notifier = _notifierFor(character);
    if (notifier == null) return;

    // A full hand sends the item to the bag, which is what the bag is for. With
    // the hand free it goes in the hand, as before.
    if (character.currentState.carriedItem == CarriedItem.none()) {
      notifier.pickUp(item);
    } else if (!notifier.stow(item)) {
      // No room in the bag either, so the item stays where it is.
      return;
    }

    final game = this.game;
    game.onItemPickedUp(character, item);
    removeFromParent();
  }

  /// The character state of [character], which is what the hand and the bag live
  /// in. The game owns the mapping from a component to its notifier.
  CharacterStateNotifier? _notifierFor(CharacterComponent character) =>
      game.notifierFor(character);

  (IconData, Color) _getItemVisual(CarriedItem item) {
    return item.when(
      none: () => (Icons.backpack_outlined, const Color(0xFF888888)),
      key: (_) => (Icons.key_rounded, const Color(0xFFFFD700)),
      crown: () => (Icons.emoji_events_rounded, const Color(0xFFFFD700)),
      other: (_) => (Icons.backpack_rounded, const Color(0xFFF97316)),
    );
  }

  @override
  void updatePuzzle(double dt) {}
}

/// Interface for games that can pick up items.
abstract class ItemPicker {
  void onItemPickedUp(CharacterComponent character, CarriedItem item);
}
