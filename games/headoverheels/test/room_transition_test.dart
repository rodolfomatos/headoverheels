// The party must be in a tree at every moment of a room change.
//
// Walking through a door removed each character from the very list it was
// iterating, which throws `ConcurrentModificationError`, and `removeCharacter`
// detaches. With the room as the character's only parent, both characters ended
// up in no tree at all, and a `FlameGame` draws no tree but its own: the party
// did not move rooms, it disappeared.
//
// Awaiting the whole transition is not possible here -- D006 has the measurements,
// and the short version is that `runAsync`, `pump` and `resumeEngine` are mutually
// exclusive in a widget test. So this does not await the transition. It starts it,
// lets it get as far as it gets, and asserts the invariant at every step: the party
// is findable. That is the claim that was false, and it is the one a player would
// have felt.
//
// What this does not prove: that the destination room finishes loading. That needs
// `integration_test`, and it is T087.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:headoverheels/features/gameplay/entities/character_component.dart';

import 'support/hoh_frame.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the party is in a tree throughout a room change', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final loaded = await loadRealGame(tester);
    expect(loaded, isNotNull, reason: 'the game never finished loading');
    final game = loaded!;
    freeze(game.game);

    /// Everyone the game is currently drawing, wherever they hang.
    ///
    /// The game's own tree, the world's tree, and the room's. A party member in
    /// none of them is a party member the player cannot see, and that is the
    /// whole failure: they are not in a bad place, they are not drawn.
    int findable() {
      final all = <CharacterComponent>[];
      // Over the whole subtree: the party is a child of a room, which is a
      // child of the world, so a search of direct children reports "gone" for a
      // party standing in the room in front of the camera.
      // Once, over the game's whole subtree: the world is itself a descendant
      // of the game, so searching both counted every character twice.
      game.game.descendants().whereType<CharacterComponent>().forEach(all.add);
      return all.length;
    }

    expect(findable(), 2, reason: 'the party should be findable to begin with');

    final exits = game.game.currentRoom!.definition.exits;
    expect(exits, isNotEmpty, reason: 'the starting room has no way out');
    final door = exits.first;

    // Not awaited, on purpose. See the header.
    final transition = game.game.transitionTo(
      door.targetRoom,
      door.targetEntrance,
    );
    var threw = false;
    unawaited(
      transition.catchError((Object _) {
        threw = true;
      }),
    );

    // Step the engine a while and watch the party the whole time -- and the room,
    // because "the party is in a tree" and "the room is drawn" are different
    // claims and a transition can satisfy one while failing the other.
    var blank = 0;
    for (var step = 0; step < 40; step++) {
      await withLoop(tester, game.game, () async {});
      final frame = await renderFrame(tester, game);
      if (frame.inkCount == 0) blank++;
      final found = findable();
      expect(
        found,
        2,
        reason:
            'after $step steps of a room change the party is '
            '${found == 1 ? "split" : "gone"}: $found of 2 are in a tree the '
            'game draws. A character detached from every parent is not drawn at '
            'all, which is what this test exists to catch.',
      );
      if (game.game.currentRoomId == door.targetRoom) break;
    }

    // The old bug threw on the first step, before anything moved. If it threw,
    // the room never changed and the party stayed in the room that was unloaded
    // around it.
    expect(
      threw,
      isFalse,
      reason:
          'the room change threw. It used to throw '
          'ConcurrentModificationError for removing each character from the '
          'list it was iterating, which left the room unloaded and the party '
          'detached.',
    );

    expect(
      game.game.currentRoomId,
      door.targetRoom,
      reason: 'the party walked through a door and the room did not change',
    );
    expect(
      game.game.currentRoom!.characters,
      hasLength(2),
      reason:
          'the party is in no room after a door, and no tree but the '
          "game's own is drawn, so it is invisible",
    );
    // T085's mechanism, and the claim the sight of an empty room was made of.
    //
    // `_loadRoom` adds the new room and sets `_currentRoom`, and `world.add`
    // resolves before the tileset has decoded, so for a few frames after every
    // door the room is mounted, interactive, and paints nothing. It was never
    // visible before because transitions were broken in a louder way -- the party
    // vanished -- and fixing that removed the bigger symptom and left this one.
    //
    // Sampled from the first frame of the transition, in the same boot: a second
    // `testWidgets` in this file cannot load the world at all, because the
    // registry is a singleton and the teardown has to take the widget down
    // before it disposes.
    // ignore: avoid_print
    print('blank frames across the transition: $blank of 40');
    expect(
      blank,
      lessThanOrEqualTo(2),
      reason:
          'the room was blank for $blank frames of a door transition. The '
          'game is interactive from the first frame and the tileset is not '
          'decoded yet, so a player walks out of a door into an empty room. Two '
          'frames is the ceiling; more than that is a blank room, not a slow one.',
    );
  });
}
