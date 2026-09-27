/// Inventory: Knight Lore gives the party sixteen slots, and each of the four
/// knights carries the whole set between them, so a pickup by one knight is
/// visible to the others.
class Inventory {
  Inventory({this.slots = defaultSlotCount});

  /// The original gives the party sixteen positions.
  static const int defaultSlotCount = 16;

  final int slots;
  final List<String?> _items = [];

  int get length => _items.length;

  bool get isFull => _items.where((item) => item != null).length >= slots;

  int get usedSlots => _items.where((item) => item != null).length;

  List<String?> get items => List.unmodifiable(_items);

  int? indexOf(String item) {
    final index = _items.indexOf(item);
    return index < 0 ? null : index;
  }

  /// Picks an item up. Returns false when the inventory is full.
  bool pickUp(String item) {
    if (isFull) return false;
    _items.add(item);
    return true;
  }

  /// Drops the item in [slot], returning it.
  String? drop(int slot) {
    if (slot < 0 || slot >= _items.length) return null;
    return _items.removeAt(slot);
  }

  bool remove(String item) {
    final index = _items.indexOf(item);
    if (index < 0) return false;
    _items.removeAt(index);
    return true;
  }

  void clear() => _items.clear();
}
