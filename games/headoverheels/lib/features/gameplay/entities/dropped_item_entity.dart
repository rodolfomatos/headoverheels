// Dropped item entity for Head over Heels.

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
  void onLoad() async {
    super.onLoad();
    // The sprite the manifest has for this item, which is what a key, a doughnut
    // and a spring look like. The manifest has no `none`, and nothing in the
    // world drops one.
    final sprite = await showManifestSprite(_manifestNameFor(item));
    sprite?.size = size * 0.5;
  }

  /// The name the manifest gives this item.
  String _manifestNameFor(CarriedItem item) => item.when(
    none: () => 'spring',
    key: (keyId) => 'key',
    crown: () => 'crown',
    other: (itemId) => itemId,
  );

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

  @override
  void updatePuzzle(double dt) {}
}

/// Interface for games that can pick up items.
abstract class ItemPicker {
  void onItemPickedUp(CharacterComponent character, CarriedItem item);
}
