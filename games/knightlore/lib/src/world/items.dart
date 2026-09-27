import '../spells.dart';

/// What kind of thing an item is. The original calls the six ingredients
/// "spell ingredients"; they are the treasures the cauldron demands.
enum ItemKind { treasure, scroll, key }

class KlItem {
  const KlItem({
    required this.id,
    required this.name,
    required this.kind,
    this.spell,
  });

  final String id;
  final String name;
  final ItemKind kind;
  final SpellId? spell;

  bool get isScroll => kind == ItemKind.scroll;
}

/// The item catalogue. The six treasures are our selection from the original
/// furniture; the six scrolls carry the classic spells.
class KlItems {
  const KlItems._();

  /// The six things the cauldron asks for, in the order it asks for them.
  static const List<String> ingredients = [
    'diamond',
    'pot_of_gold',
    'casket',
    'chalice',
    'golden_key',
    'jewel',
  ];

  static const List<KlItem> _catalogue = [
    KlItem(id: 'diamond', name: 'Diamond', kind: ItemKind.treasure),
    KlItem(id: 'pot_of_gold', name: 'Pot of gold', kind: ItemKind.treasure),
    KlItem(id: 'casket', name: 'Casket', kind: ItemKind.treasure),
    KlItem(id: 'chalice', name: 'Chalice', kind: ItemKind.treasure),
    KlItem(id: 'golden_key', name: 'Golden key', kind: ItemKind.key),
    KlItem(id: 'jewel', name: 'Jewel', kind: ItemKind.treasure),
    KlItem(
      id: 'scroll_flip',
      name: 'Flip',
      kind: ItemKind.scroll,
      spell: SpellId.flip,
    ),
    KlItem(
      id: 'scroll_magic_armour',
      name: 'Magic Armour',
      kind: ItemKind.scroll,
      spell: SpellId.magicArmour,
    ),
    KlItem(
      id: 'scroll_open_door',
      name: 'Open Door',
      kind: ItemKind.scroll,
      spell: SpellId.openDoor,
    ),
    KlItem(
      id: 'scroll_telekinesis',
      name: 'Telekinesis',
      kind: ItemKind.scroll,
      spell: SpellId.telekinesis,
    ),
    KlItem(
      id: 'scroll_shield',
      name: 'Shield',
      kind: ItemKind.scroll,
      spell: SpellId.shield,
    ),
    KlItem(
      id: 'scroll_invisibility',
      name: 'Invisibility',
      kind: ItemKind.scroll,
      spell: SpellId.invisibility,
    ),
  ];

  static final Map<String, KlItem> _byId = {
    for (final item in _catalogue) item.id: item,
  };

  static List<KlItem> get all => List.unmodifiable(_catalogue);

  static KlItem? byId(String id) => _byId[id];

  /// The scroll that carries [spell], if the party can find one.
  static KlItem? scrollFor(SpellId spell) {
    for (final item in _catalogue) {
      if (item.spell == spell) return item;
    }
    return null;
  }

  static String nameOf(String id) => _byId[id]?.name ?? id;
}
