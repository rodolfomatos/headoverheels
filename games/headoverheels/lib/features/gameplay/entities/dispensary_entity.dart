// The place the magic bag is emptied.

import 'package:flame/components.dart' show Component;
import 'package:vector_math/vector_math.dart' show Vector2, Vector3;
import 'package:headoverheels/features/gameplay/entities/character_component.dart';
import 'package:headoverheels/features/gameplay/entities/dropped_item_entity.dart';
import 'package:headoverheels/features/gameplay/entities/puzzle_entity.dart';
import 'package:headoverheels/features/gameplay/room/room_component.dart';
import 'package:headoverheels/features/gameplay/room/room_graph.dart';

/// The dispensary: the bag goes in and the items come out here.
///
/// The magic bag carries four and nothing in the world could empty it: there was
/// no dispensary and no swop, and no trigger type for either, so a bag that
/// filled stayed full for ever. This is that place. It is one per planet, in
/// the room the party arrives in, which is a design decision a person can move
/// if they would rather it were somewhere else.
class DispensaryEntity extends PuzzleEntity {
  DispensaryEntity({required super.id, required super.triggerZone});

  /// How many items came out, so a test and a player can both see it happen.
  int get emptiedCount => _emptiedCount;
  int _emptiedCount = 0;

  @override
  void onLoad() async {
    super.onLoad();
    // The manifest has no dispensary of its own, so this shows a prop rather
    // than nothing: a chest stands in for a place that empties a bag.
    final sprite = await showManifestSprite('prop');
    sprite?.size = size;
  }

  @override
  void onInteract(CharacterComponent character) {
    final notifier = game.notifierFor(character);
    if (notifier == null) return;
    if (!notifier.wearsBag) return;

    // The room it stands in, not the game's current one: an entity that drops
    // things puts them where it is, and asking the game meant a dispensary in
    // any room but the current one would drop nothing.
    final room = _theRoomThisIsIn;
    if (room == null) return;

    final bag = notifier.bagContents;
    if (bag.isEmpty) return;

    notifier.emptyBag();
    _emptiedCount += bag.length;

    // The items land on the floor of this room, where the party can pick them
    // up again: in the hand when it is free, in the bag when it is not.
    for (final item in bag) {
      final dropped = DroppedItemEntity(
        id: 'dispensed_$id\$_emptiedCount',
        triggerZone: _tileBeside(),
        item: item,
      );
      room.entities.add(dropped);
      room.add(dropped);
    }
  }

  /// The room this dispensary is in, found by walking up the tree.
  RoomComponent? get _theRoomThisIsIn {
    Component? node = parent;
    while (node != null) {
      if (node is RoomComponent) return node;
      node = node.parent;
    }
    return null;
  }

  /// Where the items land: one tile in front of the dispensary.
  TriggerZone _tileBeside() => triggerZone.copyWith(
    id: 'dispensed_$id',
    type: TriggerType.key,
    position: Vector3(triggerZone.position.x + 1, triggerZone.position.y, 0),
    size: Vector2(1, 1),
  );
}
