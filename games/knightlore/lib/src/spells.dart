/// Magic spells of Knight Lore.
///
/// Spells are cast from a scroll in one of the four inventory slots and decay
/// over game time. The durations below are our own tuning: they reproduce the
/// behaviour of the original (short, comparable lifetimes) and are declared as
/// data so the balance can be changed without touching code.
enum SpellId {
  flip('flip'),
  magicArmour('magic_armour'),
  openDoor('open_door'),
  telekinesis('telekinesis'),
  shield('shield'),
  invisibility('invisibility');

  const SpellId(this.id);

  final String id;

  static SpellId? fromId(String id) {
    for (final value in SpellId.values) {
      if (value.id == id) return value;
    }
    return null;
  }
}

class Spell {
  const Spell({
    required this.id,
    required this.name,
    required this.duration,
    required this.decayPerDay,
  });

  final SpellId id;
  final String name;

  /// Lifetime in ticks while the knight is in the light.
  final int duration;

  /// How much of the lifetime is lost per game day.
  final int decayPerDay;

  bool get isInstant => duration == 0;

  static Spell? fromId(String id) => _byId[SpellId.fromId(id)];

  static final Map<SpellId, Spell> _byId = {
    for (final spell in const [
      Spell(
        id: SpellId.flip,
        name: 'Flip',
        duration: 0,
        decayPerDay: 0,
      ),
      Spell(
        id: SpellId.magicArmour,
        name: 'Magic Armour',
        duration: 3000,
        decayPerDay: 900,
      ),
      Spell(
        id: SpellId.openDoor,
        name: 'Open Door',
        duration: 1500,
        decayPerDay: 600,
      ),
      Spell(
        id: SpellId.telekinesis,
        name: 'Telekinesis',
        duration: 2000,
        decayPerDay: 700,
      ),
      Spell(
        id: SpellId.shield,
        name: 'Shield',
        duration: 2500,
        decayPerDay: 800,
      ),
      Spell(
        id: SpellId.invisibility,
        name: 'Invisibility',
        duration: 3500,
        decayPerDay: 1000,
      ),
    ])
      spell.id: spell,
  };

  static List<Spell> get all => List.unmodifiable(_byId.values);
}

class ActiveSpell {
  const ActiveSpell({required this.spell, required this.remaining});

  final Spell spell;
  final int remaining;

  bool get isActive => remaining > 0;
  double get fraction =>
      spell.duration == 0 ? 0 : (remaining / spell.duration).clamp(0.0, 1.0);
}

/// The spells currently in effect, with the daylight decay applied.
class SpellState {
  SpellState({Iterable<ActiveSpell> active = const []})
      : _active = {for (final spell in active) spell.spell.id: spell};

  final Map<SpellId, ActiveSpell> _active;

  Iterable<ActiveSpell> get active => _active.values;

  bool isActive(SpellId id) => _active[id]?.isActive ?? false;

  ActiveSpell? of(SpellId id) => _active[id];

  /// Casts a spell, replacing any previous cast of the same spell.
  ///
  /// An instant spell, such as Flip, is not kept: a filmation is a single step
  /// and nothing may read it afterwards. Leaving it in the map would need a
  /// second mechanism to sweep it out, and it would sit in the active list as a
  /// dead entry.
  void cast(SpellId id) {
    final spell = Spell.fromId(id.id);
    if (spell == null) return;
    if (spell.isInstant) {
      _active.remove(id);
      return;
    }
    _active[id] = ActiveSpell(spell: spell, remaining: spell.duration);
  }

  /// Applies one day of decay to every spell.
  ///
  /// Decay happens at dawn and nowhere else. A spell cast in the morning has to
  /// last the whole day, which is what makes the scrolls worth spending at the
  /// right moment rather than casting one whenever it is convenient.
  void advanceDay() {
    for (final entry in _active.entries.toList()) {
      _active[entry.key] = ActiveSpell(
        spell: entry.value.spell,
        remaining: entry.value.remaining - entry.value.spell.decayPerDay,
      );
    }
    _active.removeWhere((_, spell) => !spell.isActive);
  }
}
