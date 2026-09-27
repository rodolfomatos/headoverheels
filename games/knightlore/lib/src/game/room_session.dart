import 'package:iso_core/iso_core.dart';
import 'package:vector_math/vector_math.dart' show Vector2, Vector3;

import '../curse.dart';
import '../inventory.dart';
import '../knight.dart';
import '../spells.dart';
import '../world/items.dart';
import '../world/knight_lore_world.dart';
import 'terrain.dart';

/// The eight isometric facings, ordered clockwise from north.
enum Facing {
  north(0, -1, 'north'),
  northEast(1, -1, 'north-east'),
  east(1, 0, 'east'),
  southEast(1, 1, 'south-east'),
  south(0, 1, 'south'),
  southWest(-1, 1, 'south-west'),
  west(-1, 0, 'west'),
  northWest(-1, -1, 'north-west');

  const Facing(this.dx, this.dy, this.label);

  final int dx;
  final int dy;
  final String label;

  /// The world data uses compass names, so a facing doubles as an exit name.
  String? get exitDirection {
    if (dy < 0) return 'north';
    if (dy > 0) return 'south';
    return dx > 0 ? 'east' : 'west';
  }
}

/// Exits are stored by edge, so leaving through the top edge of a room is
/// `north` and a stairway up is `up`: both cross the same edge.
Set<String> exitNamesFor(Facing facing) {
  final name = facing.exitDirection;
  if (name == 'north') return const {'north', 'up'};
  if (name == 'south') return const {'south', 'down'};
  return {name!};
}

Facing facingForExit(String exitDirection) {
  switch (exitDirection) {
    case 'north':
    case 'up':
      return Facing.north;
    case 'south':
    case 'down':
      return Facing.south;
    case 'east':
      return Facing.east;
    default:
      return Facing.west;
  }
}

enum MoveOutcome {
  /// The party advanced one tile.
  moved,

  /// A wall or a closed door stopped them.
  blocked,

  /// The party left through an exit; a new room is current.
  changedRoom,

  /// Filmation: the four knights filled the four exits and the view flipped.
  flipped,

  /// The exit exists but the way is barred: locked, night, or werewolf.
  refused,

  /// The room edge has no exit at all.
  noExit,
}

enum InteractOutcome {
  nothing,
  pickedUp,
  dropped,
  chestOpened,
  chestEmpty,
  ingredientAccepted,
  ingredientRefused,
  wizardSpoke,
  wizardRefused,
}

enum CastOutcome {
  nothing,
  cast,
  notAScroll,
  noSpell,
}

class Adventurer {
  Adventurer({
    required this.form,
    required this.position,
    this.facing = Facing.south,
  });

  KnightClass form;
  Vector3 position;
  Facing facing;

  @override
  String toString() => '${form.id}@${position.x},${position.y}';
}

/// The playable session: rooms, movement, interaction, day and night.
///
/// The party is one creature. While the curse is split the four knights share
/// one position and move together; when they stand on the four exits of a room
/// the view flips instead of leaving, which is the original filmation rule.
class RoomSession {
  RoomSession({
    required this.world,
    required Map<String, RoomTerrain> terrain,
    CurseState? curse,
    FilmRule filmRule = const FilmRule(),
    List<String> initialItems = const [],
  })  : _terrain = terrain,
        _filmRule = filmRule {
    // One inventory only: the curse state owns it, so an item the party picks
    // up is the same item the cauldron can be given.
    this.curse = curse ?? CurseState();
    inventory = this.curse.inventory;
    final start = world.getRoom(world.startRoom);
    if (start == null) {
      throw StateError('World has no start room: ${world.startRoom}');
    }
    _terrainOf(start.id);
    _party.add(
      Adventurer(form: KnightClass.sabreman, position: start.spawnPosition),
    );
    _roomId = start.id;
    for (final item in initialItems) {
      placeItem(item, start.spawnPosition);
    }
  }

  final WorldGraph world;
  late final CurseState curse;
  late final Inventory inventory;
  final Map<String, RoomTerrain> _terrain;
  final FilmRule _filmRule;
  final List<Adventurer> _party = [];
  final Map<String, Map<String, Vector3>> _items = {};

  String _roomId = '';

  String get roomId => _roomId;

  RoomInfo get room => world.getRoom(_roomId)!;

  RoomTerrain get terrain => _terrainOf(_roomId);

  /// The knight the player is steering.
  Adventurer get leader => _party.first;

  List<Adventurer> get party => List.unmodifiable(_party);

  bool get isSplit => curse.isSplit;

  /// Items lying in the current room.
  Map<String, Vector3> get itemsHere =>
      Map.unmodifiable(_items[_roomId] ?? const {});

  RoomTerrain _terrainOf(String roomId) {
    final terrain = _terrain[roomId];
    if (terrain == null) {
      throw StateError('No terrain registered for room $roomId');
    }
    return terrain;
  }

  /// The exits the party currently stands on.
  Set<String> get occupiedExits {
    final bounds = terrain;
    final exits = <String>{};
    for (final knight in _party) {
      if (knight.position.y < 1) {
        exits.add('north');
      } else if (knight.position.y > bounds.height - 2) {
        exits.add('south');
      } else if (knight.position.x < 1) {
        exits.add('west');
      } else if (knight.position.x > bounds.width - 2) {
        exits.add('east');
      }
    }
    return exits;
  }

  /// Filmation: the view may flip when the four knights fill four exits.
  bool get canFlipHere => _filmRule.canFlip(
      knights: _party.map((k) => k.form).toList(),
      occupiedExits: occupiedExits);

  /// Walks the party one tile in [direction].
  MoveOutcome step(Facing direction) {
    for (final knight in _party) {
      knight.facing = direction;
    }
    final target = Vector3(
      leader.position.x + direction.dx,
      leader.position.y + direction.dy,
      leader.position.z,
    );
    final bounds = terrain;
    final inside = target.x >= 0 &&
        target.y >= 0 &&
        target.x < bounds.width &&
        target.y < bounds.height;

    if (inside) {
      if (bounds.isBlocked(target.x.round(), target.y.round())) {
        return MoveOutcome.blocked;
      }
      for (final knight in _party) {
        knight.position = target.clone();
      }
      return MoveOutcome.moved;
    }
    return _leaveRoom(direction);
  }

  MoveOutcome _leaveRoom(Facing direction) {
    final names = exitNamesFor(direction);
    final matches =
        room.exits.where((exit) => names.contains(exit.direction)).toList();
    if (matches.isEmpty) return MoveOutcome.noExit;
    final exit = matches.first;

    final flipped = isSplit && canFlipHere;
    if (exit.isLocked && !_hasKey(exit.keyId)) {
      return MoveOutcome.refused;
    }
    if (!curse.canUseDoor(
      spellOpenDoor: curse.spells.isActive(SpellId.openDoor),
      spellTelekinesis: curse.spells.isActive(SpellId.telekinesis),
    )) {
      return MoveOutcome.refused;
    }

    enterRoom(exit.room, entrance: exit.entrance);
    return flipped ? MoveOutcome.flipped : MoveOutcome.changedRoom;
  }

  bool _hasKey(String? keyId) {
    if (keyId == null) return false;
    return inventory.items.contains(keyId);
  }

  /// Moves the party into [roomId], one tile in from the edge it came through.
  void enterRoom(String roomId, {String entrance = ''}) {
    final target = world.getRoom(roomId);
    if (target == null) {
      throw StateError('Unknown room: $roomId');
    }
    final spawn = target.spawnPosition.clone();
    if (entrance.isNotEmpty) {
      final back = target.exits
          .where((exit) => exit.entrance == entrance)
          .map((exit) => exit.direction)
          .toList();
      if (back.isNotEmpty) {
        final direction = facingForExit(back.first);
        spawn.add(Vector3(direction.dx * 0.5, direction.dy * 0.5, 0));
      }
    }
    _roomId = roomId;
    for (final knight in _party) {
      knight.position = spawn.clone();
    }
  }

  /// Puts an item on the floor of the current room.
  void placeItem(String item, [Vector3? position]) {
    _items.putIfAbsent(_roomId, () => <String, Vector3>{})[item] =
        (position ?? leader.position).clone();
  }

  List<String> get itemUnderfoot => [
        for (final entry in itemsHere.entries)
          if (entry.value.x == leader.position.x &&
              entry.value.y == leader.position.y)
            entry.key,
      ];

  /// Acts on what is underfoot, then on whatever the party faces.
  InteractOutcome interact() {
    final underfoot = itemUnderfoot;
    if (underfoot.isNotEmpty) {
      final item = underfoot.first;
      if (!inventory.pickUp(item)) return InteractOutcome.nothing;
      (_items[_roomId] ??= <String, Vector3>{}).remove(item);
      return InteractOutcome.pickedUp;
    }

    final target = _facingTrigger();
    if (target == null) return InteractOutcome.nothing;

    switch (target.type) {
      case 'cauldron':
        if (curse.demandedIngredient == null) {
          return InteractOutcome.ingredientRefused;
        }
        final wanted = curse.demandedIngredient!;
        if (!inventory.items.contains(wanted)) {
          return InteractOutcome.ingredientRefused;
        }
        final result = curse.offerIngredient(wanted);
        if (result == CurseEvent.ingredientAccepted ||
            result == CurseEvent.curseLifted) {
          return InteractOutcome.ingredientAccepted;
        }
        return InteractOutcome.ingredientRefused;
      case 'wizard':
        if (!curse.canEnterWizardRoom) return InteractOutcome.wizardRefused;
        curse.demandIngredient(_nextIngredient());
        return InteractOutcome.wizardSpoke;
      case 'chest':
        return _openChest(target);
      default:
        return InteractOutcome.nothing;
    }
  }

  /// Chests hold one item each and remember whether they were emptied.
  final Map<String, bool> _openedChests = {};

  bool chestIsOpen(String chestId) => _openedChests[chestId] ?? false;

  InteractOutcome _openChest(RoomTrigger chest) {
    final id = chest.id;
    if (_openedChests[id] ?? false) return InteractOutcome.chestEmpty;
    _openedChests[id] = true;
    final properties = chest.properties['properties'];
    final itemId = properties is Map ? properties['itemId'] : null;
    if (itemId is! String || itemId.isEmpty) return InteractOutcome.chestEmpty;
    placeItem(itemId);
    return InteractOutcome.chestOpened;
  }

  /// The chest the party is facing, if any.
  String? get chestInFront {
    final target = _facingTrigger();
    if (target == null || target.type != 'chest') return null;
    return target.id;
  }

  /// Everything the chest would have held, for the status scroll and the HUD.
  String? chestContents(String chestId) {
    for (final trigger in room.triggers) {
      if (trigger.type != 'chest' || trigger.id != chestId) continue;
      final properties = trigger.properties['properties'];
      if (properties is Map) return properties['itemId'] as String?;
    }
    return null;
  }

  /// Casts the scroll in [slot]. Scrolls are not consumed: the original keeps
  /// them usable, and consuming them risks a dead end.
  CastOutcome castAtSlot(int slot) {
    if (slot < 0 || slot >= inventory.length) return CastOutcome.nothing;
    final itemId = inventory.items[slot];
    if (itemId == null) return CastOutcome.nothing;
    final item = KlItems.byId(itemId);
    if (item == null || !item.isScroll) return CastOutcome.notAScroll;
    final spell = item.spell;
    if (spell == null) return CastOutcome.noSpell;
    curse.spells.cast(spell);
    return CastOutcome.cast;
  }

  /// The wizard names the next ingredient, and refuses to name one the party
  /// cannot possibly be carrying.
  String _nextIngredient() {
    final held = inventory.items.whereType<String>().toSet();
    for (final candidate in KlItems.ingredients) {
      if (!held.contains(candidate)) return candidate;
    }
    return KlItems.ingredients.last;
  }

  RoomTrigger? _facingTrigger() {
    final target = Vector2(
      leader.position.x + leader.facing.dx * 0.5,
      leader.position.y + leader.facing.dy * 0.5,
    );
    RoomTrigger? best;
    var bestDistance = double.infinity;
    for (final trigger in room.triggers) {
      final dx = trigger.position.x - target.x;
      final dy = trigger.position.y - target.y;
      final distance = dx * dx + dy * dy;
      if (distance < bestDistance && distance <= 1.0) {
        best = trigger;
        bestDistance = distance;
      }
    }
    return best;
  }

  /// Night falls: the sabreman turns werewolf and loses the use of doors.
  void nightFalls() {
    curse.nightFalls();
  }

  void dawnBreaks() {
    curse.dawnBreaks();
  }

  /// Turns the party into the four knights, in the current room.
  void splitParty() {
    curse.split();
    if (!curse.isSplit) return;
    final spawn = _party.isEmpty ? Vector3.zero() : leader.position.clone();
    _party
      ..clear()
      ..addAll([
        for (final knight in splitKnights)
          Adventurer(form: knight, position: spawn.clone()),
      ]);
  }

  void rejoinParty() {
    final position = _party.isEmpty ? Vector3.zero() : leader.position.clone();
    if (curse.isSplit) curse.rejoin();
    _party
      ..clear()
      ..add(Adventurer(form: KnightClass.sabreman, position: position));
  }

  /// Advances the sundial by one day.
  CurseEvent? advanceDay() => curse.advanceDay();
}

/// The rooms the world references, as empty walkable floors. Replaced by the
/// TMX loader once the room maps exist.
Map<String, RoomTerrain> openTerrainFor(WorldGraph world) => {
      for (final room in world.rooms.values) room.id: RoomTerrain.open(8, 8),
    };

/// The shipped world with open rooms, ready to be played.
RoomSession newKnightLoreSession() {
  final world = KnightLoreWorld.build();
  return RoomSession(world: world, terrain: openTerrainFor(world));
}
