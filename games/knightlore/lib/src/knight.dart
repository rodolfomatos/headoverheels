/// The knight classes of Knight Lore.
///
/// The sabreman is the cursed protagonist. Under the moonlight he splits into
/// four knights, each with its own colour and its own inventory, and the party
/// is controlled as one creature until they rejoin.
enum KnightClass {
  /// The cursed sabreman: the only form that can enter Melkhior's room.
  sabreman(0xFF9AA3B2, 'sabreman'),

  /// Blue knight. Slowest, weakest, first to be created.
  jinx(0xFF4C8BF5, 'jinx'),

  /// Yellow knight.
  joronie(0xFFF2C94C, 'joronie'),

  /// Red knight.
  achinda(0xFFEB5757, 'achinda'),

  /// Green knight. Fastest, strongest, created last.
  celist(0xFF4CAF50, 'celist');

  const KnightClass(this.colour, this.id);

  final int colour;
  final String id;

  bool get isSplitKnight => this != KnightClass.sabreman;

  static KnightClass? fromId(String id) {
    for (final value in KnightClass.values) {
      if (value.id == id) return value;
    }
    return null;
  }
}

/// The four knights, in the order the curse creates them.
const List<KnightClass> splitKnights = [
  KnightClass.jinx,
  KnightClass.joronie,
  KnightClass.achinda,
  KnightClass.celist,
];
