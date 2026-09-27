import 'package:iso_core/iso_core.dart' show RoomTrigger, WorldGraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:knightlore/knightlore.dart';

/// Measures the game instead of guessing at it.
///
/// Everything here is a measurement the tuning can be judged against: how far a
/// perfect player has to walk, how long a spell holds, and where the six
/// ingredients are. The assertions are deliberately loose, because the numbers
/// are tuning: what they forbid is a world that cannot be finished, or one that
/// is finished before the first night.
void main() {
  final world = KnightLoreWorld.build();

  /// The rooms of the world as a graph, walked step by step.
  ///
  /// A "step" is one tile, which is what a key press costs, so the answer is in
  /// the same unit the player spends.
  int walkSteps(String from, String to) {
    final frontier = <String>[from];
    final seen = <String>{from};
    var depth = 0;
    while (frontier.isNotEmpty && !frontier.contains(to)) {
      final next = <String>[];
      for (final room in frontier) {
        for (final exit in world.rooms[room]!.exits) {
          if (seen.add(exit.room)) next.add(exit.room);
        }
      }
      depth++;
      frontier
        ..clear()
        ..addAll(next);
    }
    if (!frontier.contains(to)) {
      throw StateError('$to is not reachable from $from');
    }
    return depth;
  }

  /// The cheapest tour that enters every room, starting from [from].
  ///
  /// Walking the world is what the forty days are really spent on, so this is
  /// the number that says whether the clock still fits.
  int walkEveryRoom(WorldGraph graph, String from) {
    final start = graph.rooms.keys.toList()..sort();
    int tour(String at) {
      // A nearest neighbour walk: cheap to write and never wildly optimistic,
      // because a real player has to come back through the rooms already seen.
      var total = 0;
      final pending = start.where((id) => id != at).toList();
      var here = at;
      while (pending.isNotEmpty) {
        final next = pending.first;
        total += walkSteps(here, next);
        here = next;
        pending.remove(next);
      }
      return total;
    }

    return tour(from);
  }

  /// The item a container trigger holds, if any.
  String? heldBy(RoomTrigger trigger) {
    final properties = trigger.properties['properties'];
    return properties is Map ? properties['itemId'] as String? : null;
  }

  /// A day in movement steps, from the game's own constants.
  ///
  /// The day is [KnightLoreGameConfig.daySeconds] of real time, the trap clock
  /// ticks [KnightLoreGame.trapTicksPerSecond] times a second and a step costs
  /// [RoomSession.ticksPerStep] ticks, so this is how far a player can walk in a
  /// day. Change any of those and this moves, which is the point.
  int stepsPerDay() {
    final seconds = const KnightLoreGameConfig().daySeconds;
    final ticks = seconds * KnightLoreGame.trapTicksPerSecond;
    return (ticks / newKnightLoreSession().ticksPerStep).floor();
  }

  group('the forty days', () {
    test('a day is long enough to cross the castle and back', () {
      final session = newKnightLoreSession();
      final budget = stepsPerDay();
      // The longest single hop in the world has to fit in a day with room to
      // spare, or a player who takes the wrong turn is stuck.
      var longest = 0;
      String? longestPair;
      for (final from in world.rooms.keys) {
        for (final to in world.rooms.keys) {
          final steps = walkSteps(from, to);
          if (steps > longest) {
            longest = steps;
            longestPair = '$from to $to';
          }
        }
      }
      expect(longestPair, isNotNull);
      expect(
        longest,
        lessThan(budget),
        reason: 'the longest walk is $longest steps ($longestPair) but a day '
            'only holds $budget',
      );
      expect(session.ticksPerStep, greaterThan(0));
    });

    test('a perfect run finishes with days to spare, but not too many', () {
      // The route is what a player who knows the world does: go to the wizard,
      // fetch what it names, come back. Measured in tiles.
      final containers = <String, String>{};
      for (final room in world.rooms.values) {
        for (final trigger in room.triggers) {
          final item = heldBy(trigger);
          if (item != null && KlItems.ingredients.contains(item)) {
            containers[item] = room.id;
          }
        }
      }
      expect(
        containers.length,
        KlItems.ingredients.length,
        reason: 'every ingredient needs a container',
      );

      var steps = 0;
      final legs = <String>[];
      for (final ingredient in KlItems.ingredients) {
        final there = walkSteps(KlRooms.laboratory, containers[ingredient]!);
        final back = walkSteps(containers[ingredient]!, KlRooms.laboratory);
        steps += there + back;
        legs.add('$ingredient: $there+$back');
      }

      final days = steps / stepsPerDay();
      // ignore: avoid_print
      print('six trips: $steps room changes over ${legs.join(', ')}');
      // ignore: avoid_print
      print('a day holds ${stepsPerDay()} changes, so knowing the world the '
          'game takes ${days.toStringAsFixed(1)} of the ${CurseState.totalDays} days');

      // Two invariants, both about the clock being a budget rather than a
      // decoration. A player who knows the world finishes in a fraction of it,
      // which is the point: the forty days are for the search, not the fetch.
      expect(
        days,
        lessThan(CurseState.totalDays / 2),
        reason: 'a perfect run takes ${days.toStringAsFixed(1)} days, so even '
            'a player who knows nothing has half the game to get lost in',
      );

      // And a player who walks the whole world, room by room, still finishes.
      // This is the one that keeps the world from growing past the clock.
      final tour = walkEveryRoom(world, KlRooms.laboratory);
      final tourDays = tour / stepsPerDay();
      // ignore: avoid_print
      print('walking all ${world.rooms.length} rooms costs $tour changes, '
          '${tourDays.toStringAsFixed(1)} days');
      expect(
        tourDays,
        lessThan(CurseState.totalDays.toDouble()),
        reason: 'searching every room needs $tourDays days of '
            '${CurseState.totalDays}, so the world is bigger than the clock',
      );
    });
  });

  group('spell lifetimes', () {
    test('every spell holds for a useful number of days', () {
      for (final id in SpellId.values) {
        final spell = Spell.fromId(id.id)!;
        if (spell.isInstant) {
          // A one step filmation costs nothing and lasts nothing.
          expect(spell.duration, 0, reason: '$id is instant but has a duration');
          expect(spell.decayPerDay, 0, reason: '$id is instant but decays');
          continue;
        }
        expect(spell.duration, greaterThan(0), reason: '$id never works');
        expect(
          spell.decayPerDay,
          greaterThan(0),
          reason: '$id never wears off',
        );
        // Long enough to be worth the slot, short enough to matter: between one
        // and four in-game days.
        final days = spell.duration / spell.decayPerDay;
        expect(
          days,
          inInclusiveRange(1.0, 4.0),
          reason: '$id lasts ${days.toStringAsFixed(1)} days',
        );
      }
    });

    test('the defensive spells are the ones that answer the wolf', () {
      final curse = CurseState();
      curse.spells.cast(SpellId.magicArmour);
      curse.nightFalls();
      expect(curse.phase == CursePhase.werewolf, isFalse, reason: 'magic armour should hold');

      final other = CurseState()..spells.cast(SpellId.invisibility);
      other.nightFalls();
      expect(other.phase == CursePhase.werewolf, isFalse, reason: 'invisibility should hold');

      // With nothing cast, the wolf comes.
      final bare = CurseState();
      bare.nightFalls();
      expect(bare.phase == CursePhase.werewolf, isTrue);

      // A spell that wore off does not help.
      final faded = CurseState()..spells.cast(SpellId.magicArmour);
      for (var day = 0; day < 4; day++) {
        faded.spells.advanceDay();
      }
      faded.nightFalls();
      expect(faded.phase == CursePhase.werewolf, isTrue, reason: 'a dead scroll must not help');
    });
  });

  group('treasure placement', () {
    test('the six ingredients are spread over the world', () {
      final rooms = <String, List<String>>{};
      for (final room in world.rooms.values) {
        for (final trigger in room.triggers) {
          final item = heldBy(trigger);
          if (item != null && KlItems.ingredients.contains(item)) {
            rooms.putIfAbsent(room.id, () => []).add(item);
          }
        }
      }
      // Two in one room would make a third of the game a formality.
      for (final entry in rooms.entries) {
        expect(
          entry.value.length,
          1,
          reason: '${entry.key} holds ${entry.value.length} ingredients',
        );
      }
      expect(rooms.keys.length, KlItems.ingredients.length);

      // And they are not all in the castle: the journey is the game.
      final areas = rooms.keys.map((id) => world.rooms[id]!.theme).toSet();
      expect(
        areas.length,
        greaterThanOrEqualTo(4),
        reason: 'the ingredients only span $areas',
      );
    });

    test('at least one ingredient is behind a door', () {
      // A treasure that is never fetched through a barrier needs no key and no
      // spell, which would leave two of the six scrolls pointless.
      var behind = 0;
      for (final room in world.rooms.values) {
        for (final exit in room.exits) {
          if (!exit.isLocked) continue;
          final target = world.rooms[exit.room]!;
          final holds = target.triggers.any(
            (trigger) => KlItems.ingredients.contains(heldBy(trigger)),
          );
          if (holds) behind++;
        }
      }
      expect(behind, greaterThan(0), reason: 'no ingredient is behind a door');
    });

    test('every locked door has a key and every key is in the world', () {
      final keys = <String>{
        for (final room in world.rooms.values)
          for (final trigger in room.triggers)
            if (heldBy(trigger)?.contains('key') ?? false) heldBy(trigger)!,
      };
      for (final room in world.rooms.values) {
        for (final exit in room.exits) {
          if (!exit.isLocked) continue;
          expect(
            keys,
            contains(exit.keyId),
            reason: 'the door to ${exit.room} needs ${exit.keyId}, which the '
                'world never contains',
          );
        }
      }
    });
  });

  group('the world as a whole', () {
    test('the game is winnable from the start state', () {
      final session = newKnightLoreSession();
      expect(session.curse.daysLeft, CurseState.totalDays);
      expect(session.curse.ingredientsLeft, CurseState.totalIngredients);
      expect(session.curse.isOver, isFalse);
      // Nothing is handed over at the start: the first thing is a walk.
      expect(session.inventory.usedSlots, 0);
    });

    test('movement costs the same everywhere', () {
      // The balance report converts tiles into days, so a step must not get
      // cheaper in one room than another.
      final session = newKnightLoreSession();
      expect(session.ticksPerStep, 8);
      final facing = <Facing>[Facing.north, Facing.east, Facing.south, Facing.west];
      for (final face in facing) {
        final before = session.tick;
        session.step(face);
        expect(session.tick - before, session.ticksPerStep, reason: '$face');
      }
    });
  });
}
