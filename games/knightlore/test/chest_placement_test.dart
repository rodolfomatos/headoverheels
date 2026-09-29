// A chest is a place in the world, not a list entry.
//
// A chest in a wall cannot be opened. A chest in a sealed corner cannot be
// reached. A scroll that is in the catalogue but in no chest is a spell the game
// offers and the world never gives: the party is told the wolf comes at night,
// and nothing in the world answers it. None of that is visible from a
// directory listing, so it is asserted here rather than trusted.

import 'package:flutter_test/flutter_test.dart';
import 'package:iso_core/iso_core.dart' show WorldGraph;
import 'package:knightlore/knightlore.dart';
import 'package:vector_math/vector_math.dart' show Vector3;

import 'test_asset_bundle.dart';

/// Whether a party standing on [from] can walk to a tile next to (x, y), where
/// the chest itself is a thing to stand beside and not to stand on.
bool _canStandBeside(RoomTerrain terrain, Vector3 from, int x, int y) {
  final startX = from.x.toInt();
  final startY = from.y.toInt();
  if (terrain.isBlocked(startX, startY)) return false;

  final wanted = <String>{
    '$x,${y - 1}',
    '${x + 1},$y',
    '$x,${y + 1}',
    '${x - 1},$y'
  };
  final seen = <String>{};
  final queue = <List<int>>[
    [startX, startY],
  ];

  while (queue.isNotEmpty) {
    final here = queue.removeAt(0);
    final key = '${here[0]},${here[1]}';
    if (!seen.add(key)) continue;
    if (wanted.contains(key)) return true;
    for (final step in const [
      [0, -1],
      [1, 0],
      [0, 1],
      [-1, 0],
    ]) {
      final nextX = here[0] + step[0];
      final nextY = here[1] + step[1];
      // The chest's own tile is passable for the flood fill: the chest is not a
      // wall, and treating it as one would make every chest unreachable from
      // the tile it stands on.
      if (terrain.isBlocked(nextX, nextY)) continue;
      queue.add([nextX, nextY]);
    }
  }
  return false;
}

void main() {
  late KnightLoreGame game;
  late RoomSession session;

  setUp(() async {
    game = KnightLoreGame(
      config: const KnightLoreGameConfig(daySeconds: 1000, autoCycle: false),
      bundle: TestAssetBundle(),
    );
    await game.onLoad();
    session = game.session!;
  });

  tearDown(() => game.dispose());

  test('every chest is somewhere the party can open it', () {
    final problems = <String>[];
    var chests = 0;

    for (final roomId in session.world.rooms.keys) {
      session.enterRoom(roomId);
      final terrain = session.terrain;
      final room = session.room;
      for (final trigger in room.triggers) {
        if (trigger.type != 'chest') continue;
        chests++;
        final x = trigger.position.x.toInt();
        final y = trigger.position.y.toInt();
        if (terrain.isBlocked(x, y)) {
          problems.add('$roomId: the chest at $x,$y is inside a wall');
          continue;
        }
        if (!_canStandBeside(terrain, room.spawnPosition, x, y)) {
          problems.add('$roomId: nothing can stand next to the chest at $x,$y');
        }
      }
    }

    expect(chests, greaterThan(0));
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('every chest names an item the game knows', () {
    final problems = <String>[];
    for (final roomId in session.world.rooms.keys) {
      session.enterRoom(roomId);
      for (final trigger in session.room.triggers) {
        if (trigger.type != 'chest') continue;
        final properties = trigger.properties['properties'];
        final itemId = properties is Map ? properties['itemId'] : null;
        if (itemId is! String) {
          problems.add('$roomId/${trigger.id}: no itemId');
          continue;
        }
        if (KlItems.byId(itemId) == null) {
          problems
              .add('$roomId/${trigger.id}: "$itemId" is not in the catalogue');
        }
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('every scroll in the catalogue is in a chest somewhere in the world',
      () {
    // The night is only survivable with Magic Armour or Invisibility. A scroll
    // that is in the catalogue but in no chest is a spell the game offers and
    // never gives, and the party meets the wolf every night with no answer.
    final hidden = <String>[];
    for (final scroll in KlItems.all.where((item) => item.isScroll)) {
      var found = false;
      for (final roomId in session.world.rooms.keys) {
        session.enterRoom(roomId);
        for (final trigger in session.room.triggers) {
          if (trigger.type != 'chest') continue;
          final properties = trigger.properties['properties'];
          if (properties is Map && properties['itemId'] == scroll.id) {
            found = true;
          }
        }
      }
      if (!found) hidden.add('${scroll.name} (${scroll.id})');
    }

    expect(hidden, isEmpty,
        reason: 'these scrolls are in the catalogue and in no chest: '
            '${hidden.join(', ')}');
  });

  test('both defensive scrolls are findable early, and not by the cauldron',
      () {
    // The night is only survivable with Magic Armour or Invisibility, so those
    // two cannot be the deepest treasure in the world. Three rooms from the
    // gatehouse is the rule, measured on the room graph, and neither of them
    // sits in a room that holds a cauldron: the answer to the wolf is not
    // something the party has to stand next to the remedy to find.
    const reachable = 3;
    final far = <String>[];
    final byTheCauldron = <String>[];

    for (final spell in const [SpellId.magicArmour, SpellId.invisibility]) {
      final scroll = KlItems.scrollFor(spell);
      if (scroll == null) {
        far.add('${spell.name} has no scroll in the catalogue');
        continue;
      }
      var home = '';
      for (final roomId in session.world.rooms.keys) {
        session.enterRoom(roomId);
        for (final trigger in session.room.triggers) {
          final properties = trigger.properties['properties'];
          if (trigger.type == 'chest' &&
              properties is Map &&
              properties['itemId'] == scroll.id) {
            home = roomId;
          }
          if (trigger.type == 'cauldron' && home == roomId) {
            byTheCauldron.add('${scroll.name} shares ${trigger.id}');
          }
        }
      }
      if (home.isEmpty) {
        far.add('${scroll.name} is in no room');
        continue;
      }
      final hops = _roomsFrom(session.world, session.world.startRoom, home);
      if (hops == null || hops > reachable) {
        far.add('${scroll.name} is $hops rooms from the start');
      }
    }

    expect(far, isEmpty, reason: far.join('\n'));
    expect(byTheCauldron, isEmpty, reason: byTheCauldron.join('\n'));
  });
}

/// How many rooms it is from [from] to [to] through the world's exits, or null
/// when there is no way through.
int? _roomsFrom(WorldGraph world, String from, String to) {
  if (from == to) return 0;
  final seen = <String>{from};
  var frontier = <String>[from];
  for (var hops = 1; hops <= 12; hops++) {
    final next = <String>[];
    for (final roomId in frontier) {
      final room = world.rooms[roomId];
      if (room == null) continue;
      for (final exit in room.exits) {
        if (exit.oneWay) continue;
        if (!seen.add(exit.room)) continue;
        if (exit.room == to) return hops;
        next.add(exit.room);
      }
    }
    if (next.isEmpty) return null;
    frontier = next;
  }
  return null;
}
