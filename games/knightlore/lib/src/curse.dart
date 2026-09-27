import 'inventory.dart';
import 'knight.dart';
import 'spells.dart';

enum CursePhase {
  /// Daylight: the sabreman is himself and can enter Melkhior's chamber.
  daylight,

  /// Night: the sabreman is a werewolf and cannot use doors.
  werewolf,

  /// The curse is lifted after six ingredients reached the cauldron.
  lifted,
}

enum CurseEvent {
  nightFalls,
  dawnBreaks,
  split,
  rejoin,
  ingredientAccepted,
  curseLifted,
  outOfTime,
  wizardRefused,
}

/// The curse rules of Knight Lore, expressed as data and pure state so they can
/// be tested without a running game loop.
class CurseState {
  CurseState({
    this.daysLeft = totalDays,
    this.ingredientsLeft = totalIngredients,
    Inventory? inventory,
    SpellState? spells,
  })  : inventory = inventory ?? Inventory(),
        spells = spells ?? SpellState();

  /// "you only have forty days and nights to complete the spell".
  static const int totalDays = 40;

  /// The cauldron demands six objects before the remedy is complete.
  static const int totalIngredients = 6;

  int daysLeft;
  int ingredientsLeft;

  /// What the cauldron has already taken, so the wizard never asks twice.
  final List<String> delivered = [];
  final Inventory inventory;
  final SpellState spells;
  KnightClass form = KnightClass.sabreman;
  CursePhase phase = CursePhase.daylight;
  String? demandedIngredient;

  bool get isSplit => form.isSplitKnight;

  bool get isOver => phase == CursePhase.lifted || daysLeft <= 0;

  /// Only the sabreman may stand in Melkhior's room, and only by day.
  bool get canEnterWizardRoom => !isSplit && phase == CursePhase.daylight;

  /// Doors need Open Door, Telekinesis or the sabreman by day.
  bool canUseDoor(
      {required bool spellOpenDoor, required bool spellTelekinesis}) {
    if (phase == CursePhase.werewolf) return false;
    if (spellOpenDoor || spellTelekinesis) return true;
    return !isSplit;
  }

  /// Night falls: the sabreman becomes a werewolf unless a spell protects him.
  ///
  /// The two defensive scrolls are the only answer to a full moon, and they are
  /// also the only reason a careful player can afford to be out at night, so
  /// this is where their value lives. Which night it is does not matter: a
  /// spell that is still active when the sun sets holds until it decays.
  void nightFalls() {
    if (phase == CursePhase.lifted) return;
    if (isProtectedFromTheWolf) return;
    phase = CursePhase.werewolf;
  }

  /// Whether a scroll is holding the wolf off tonight.
  bool get isProtectedFromTheWolf =>
      spells.isActive(SpellId.magicArmour) ||
      spells.isActive(SpellId.invisibility);

  void dawnBreaks() {
    if (phase == CursePhase.lifted) return;
    phase = CursePhase.daylight;
  }

  /// The curse splits the party into four knights.
  void split() {
    if (phase != CursePhase.werewolf) return;
    form = KnightClass.jinx;
    phase = CursePhase.daylight;
  }

  void rejoin() {
    if (!isSplit) return;
    form = KnightClass.sabreman;
  }

  /// The cauldron asks for the next ingredient. Only one is outstanding.
  void demandIngredient(String ingredient) {
    demandedIngredient = ingredient;
  }

  /// Drops an item into the cauldron. Returns the event, or null if refused.
  CurseEvent? offerIngredient(String item) {
    if (phase == CursePhase.lifted) return null;
    if (demandedIngredient == null) return CurseEvent.wizardRefused;
    if (item != demandedIngredient) return CurseEvent.wizardRefused;
    if (!inventory.remove(item)) return CurseEvent.wizardRefused;
    demandedIngredient = null;
    delivered.add(item);
    ingredientsLeft -= 1;
    if (ingredientsLeft <= 0) {
      phase = CursePhase.lifted;
      return CurseEvent.curseLifted;
    }
    return CurseEvent.ingredientAccepted;
  }

  /// Advances the sundial by one day.
  CurseEvent? advanceDay() {
    if (phase == CursePhase.lifted) return null;
    daysLeft -= 1;
    spells.advanceDay();
    if (daysLeft <= 0) return CurseEvent.outOfTime;
    return null;
  }
}

/// Filmation: rooms are fixed views and the four knights are one creature. When
/// the party stands in all four exits of a room, moving forward flips the view
/// to the next room instead of leaving it.
class FilmRule {
  const FilmRule({this.requiredKnights = 4});

  final int requiredKnights;

  bool canFlip({
    required List<KnightClass> knights,
    required Set<String> occupiedExits,
  }) {
    if (knights.length < requiredKnights) return false;
    return occupiedExits.length >= requiredKnights;
  }
}
