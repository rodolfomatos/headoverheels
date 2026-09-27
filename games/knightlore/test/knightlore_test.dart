import 'package:flutter_test/flutter_test.dart';
import 'package:iso_core/iso_core.dart';
import 'package:knightlore/knightlore.dart';

void main() {
  group('world', () {
    test('covers the five areas and validates without errors', () {
      final graph = KnightLoreWorld.build();
      final validation = validateWorld(graph);

      expect(validation.errors, isEmpty, reason: '${validation.issues}');
      expect(graph.rooms, hasLength(15));
      expect(
        graph.rooms.values.map((room) => room.theme).toSet(),
        KlAreas.all.toSet(),
      );
      expect(graph.startRoom, KlRooms.gatehouse);
    });

    test('every room is reachable and exits are symmetric', () {
      final validation = validateWorld(KnightLoreWorld.build());
      expect(
        validation.issues.where(
          (issue) =>
              issue.kind == WorldIssueKind.unreachable ||
              issue.kind == WorldIssueKind.asymmetricExit,
        ),
        isEmpty,
        reason: '${validation.issues}',
      );
    });

    test('the wizard room is only reachable as the sabreman', () {
      final graph = KnightLoreWorld.build();
      final laboratory = graph.getRoom(KlRooms.laboratory)!;
      final entry = laboratory.exits.single;
      expect(entry.room, KlRooms.corridor);

      final wizard = laboratory.triggers.firstWhere(
        (trigger) => trigger.type == 'wizard',
      );
      final properties = wizard.properties['properties'] as Map;
      expect(properties['requiresForm'], 'sabreman');
      expect(properties['name'], 'Melkhior');
    });

    test('cauldrons declare the number of ingredients', () {
      final graph = KnightLoreWorld.build();
      final cauldrons = graph.rooms.values
          .expand((room) => room.triggers)
          .where((trigger) => trigger.type == 'cauldron');
      expect(cauldrons, isNotEmpty);
      for (final cauldron in cauldrons) {
        final properties = cauldron.properties['properties'] as Map;
        expect(
          properties['ingredientsRequired'],
          CurseState.totalIngredients,
        );
      }
    });

    test('the mine door is locked behind a key', () {
      final graph = KnightLoreWorld.build();
      final corridor = graph.getRoom(KlRooms.corridor)!;
      final locked = corridor.exits.firstWhere((exit) => exit.isLocked);
      expect(locked.room, KlRooms.mineEntrance);
      expect(locked.keyId, 'jewel_key');
    });
  });

  group('knights', () {
    test('names the sabreman and the four coloured knights', () {
      expect(KnightClass.values, hasLength(5));
      expect(KnightClass.sabreman.isSplitKnight, isFalse);
      expect(splitKnights, hasLength(4));
      expect(
        splitKnights.map((knight) => knight.colour).toSet(),
        hasLength(4),
        reason: 'each knight has its own colour',
      );
      expect(KnightClass.fromId('joronie'), KnightClass.joronie);
      expect(KnightClass.fromId('nobody'), isNull);
    });
  });

  group('spells', () {
    test('declares the six classic spells with decaying lifetimes', () {
      expect(Spell.all, hasLength(6));
      for (final spell in Spell.all) {
        expect(spell.decayPerDay, greaterThanOrEqualTo(0));
        if (!spell.isInstant) {
          expect(spell.decayPerDay, greaterThan(0));
          expect(spell.duration, greaterThan(spell.decayPerDay));
        }
      }
      expect(Spell.fromId('flip')!.isInstant, isTrue);
      expect(Spell.fromId('nope'), isNull);
    });

    test('cast spells expire and instant spells do not persist', () {
      final state = SpellState();
      state.cast(SpellId.shield);
      expect(state.isActive(SpellId.shield), isTrue);

      state.advance(Spell.fromId('shield')!.duration);
      expect(state.isActive(SpellId.shield), isFalse);

      state.cast(SpellId.flip);
      state.advance(1);
      expect(state.isActive(SpellId.flip), isFalse);
    });

    test('a day of decay shortens every spell', () {
      final state = SpellState();
      state.cast(SpellId.telekinesis);
      final before = state.of(SpellId.telekinesis)!.remaining;
      state.advanceDay();
      expect(
        state.of(SpellId.telekinesis)!.remaining,
        before - Spell.fromId('telekinesis')!.decayPerDay,
      );
    });
  });

  group('inventory', () {
    test('has sixteen slots and refuses overflow', () {
      final inventory = Inventory();
      expect(inventory.slots, 16);
      for (var i = 0; i < 16; i++) {
        expect(inventory.pickUp('item_$i'), isTrue);
      }
      expect(inventory.isFull, isTrue);
      expect(inventory.pickUp('overflow'), isFalse);
      expect(inventory.usedSlots, 16);
    });

    test('drops and removes items', () {
      final inventory = Inventory()..pickUp('chalice');
      expect(inventory.indexOf('chalice'), 0);
      expect(inventory.drop(0), 'chalice');
      expect(inventory.indexOf('chalice'), isNull);
      inventory.pickUp('diamond');
      expect(inventory.remove('diamond'), isTrue);
      expect(inventory.remove('diamond'), isFalse);
      expect(inventory.drop(9), isNull);
    });
  });

  group('curse', () {
    test('starts in daylight with forty days and six ingredients', () {
      final state = CurseState();
      expect(state.daysLeft, 40);
      expect(state.ingredientsLeft, 6);
      expect(state.phase, CursePhase.daylight);
      expect(state.form, KnightClass.sabreman);
      expect(state.isOver, isFalse);
      expect(state.canEnterWizardRoom, isTrue);
    });

    test('night turns the sabreman into a werewolf', () {
      final state = CurseState();
      state.nightFalls();
      expect(state.phase, CursePhase.werewolf);
      expect(state.canEnterWizardRoom, isFalse);
      expect(
        state.canUseDoor(spellOpenDoor: false, spellTelekinesis: false),
        isFalse,
      );

      state.dawnBreaks();
      expect(state.phase, CursePhase.daylight);
      expect(
        state.canUseDoor(spellOpenDoor: false, spellTelekinesis: false),
        isTrue,
      );
    });

    test('spells open doors in the dark', () {
      final state = CurseState();
      state.spells.cast(SpellId.openDoor);
      expect(
        state.canUseDoor(spellOpenDoor: true, spellTelekinesis: false),
        isTrue,
      );
      state.spells.cast(SpellId.telekinesis);
      expect(
        state.canUseDoor(spellOpenDoor: false, spellTelekinesis: true),
        isTrue,
      );
    });

    test('split knights cannot enter the wizard room', () {
      final state = CurseState();
      state.nightFalls();
      state.split();
      expect(state.form, KnightClass.jinx);
      expect(state.isSplit, isTrue);
      expect(state.canEnterWizardRoom, isFalse);

      state.rejoin();
      expect(state.form, KnightClass.sabreman);
      expect(state.isSplit, isFalse);
    });

    test('only the demanded ingredient is accepted', () {
      final state = CurseState();
      expect(state.offerIngredient('diamond'), CurseEvent.wizardRefused);

      state.inventory.pickUp('diamond');
      state.inventory.pickUp('chalice');
      state.demandIngredient('diamond');
      expect(state.offerIngredient('chalice'), CurseEvent.wizardRefused);
      expect(state.ingredientsLeft, 6);

      expect(
        state.offerIngredient('diamond'),
        CurseEvent.ingredientAccepted,
      );
      expect(state.ingredientsLeft, 5);
      expect(state.demandedIngredient, isNull);
    });

    test('six ingredients lift the curse', () {
      final state = CurseState();
      for (var i = 0; i < 6; i++) {
        final item = 'ingredient_$i';
        state.inventory.pickUp(item);
        state.demandIngredient(item);
        final event = state.offerIngredient(item);
        expect(
          event,
          i == 5 ? CurseEvent.curseLifted : CurseEvent.ingredientAccepted,
        );
      }
      expect(state.phase, CursePhase.lifted);
      expect(state.isOver, isTrue);
      expect(state.offerIngredient('extra'), isNull);
    });

    test('running out of days ends the game without curing the curse', () {
      final state = CurseState(daysLeft: 1);
      expect(state.advanceDay(), CurseEvent.outOfTime);
      expect(state.isOver, isTrue);
      expect(state.phase, isNot(CursePhase.lifted));
      expect(state.daysLeft, 0);
    });

    test('a day of decay can expire the last spell', () {
      final state = CurseState();
      state.spells.cast(SpellId.invisibility);
      state.spells.advanceDay();
      state.spells.advanceDay();
      state.spells.advanceDay();
      state.spells.advanceDay();
      expect(state.spells.isActive(SpellId.invisibility), isFalse);
    });
  });

  group('filmation', () {
    const rule = FilmRule();
    final party = [...splitKnights];

    test('flips only when the four knights fill four exits', () {
      expect(
        rule.canFlip(knights: party, occupiedExits: {'north', 'south'}),
        isFalse,
      );
      expect(
        rule.canFlip(
          knights: party,
          occupiedExits: {'north', 'south', 'east', 'west'},
        ),
        isTrue,
      );
    });

    test('a single knight never flips', () {
      expect(
        rule.canFlip(
          knights: [KnightClass.sabreman],
          occupiedExits: {'north', 'south', 'east', 'west'},
        ),
        isFalse,
      );
    });
  });

  group('engine reuse', () {
    test('the world runs on the generic isometric runtime', () {
      final graph = KnightLoreWorld.build();
      final room = graph.getRoom(KlRooms.gatehouse)!;
      final position = gridToScreen(room.spawnPosition);
      final back = screenToGrid(position);
      expect(back.x, closeTo(room.spawnPosition.x, 0.001));
      expect(back.y, closeTo(room.spawnPosition.y, 0.001));
      expect(room.exits, isNotEmpty);
    });
  });
}
