// Does the room and the stuff in it land in the same place?
//
// Two things were being drawn in two coordinate systems. The room is drawn by
// `flame_tiled`, which places a right-down isometric map at its own local
// origin, while the camera is framed on `worldBounds`, which is the isometric
// projection — so the room sat a whole room-width to the right of everything
// else. In a 1000x720 window the room occupied x 470 to the right edge and ran
// off it, and sixteen entities appeared as six-pixel squares between x 60 and
// x 660.
//
// Every other render test here asked "how much did it paint". That question is
// answerable while the thing is in the wrong place: the party was reported as
// painting 3,635 pixels while standing nowhere near the floor. The question
// that was missing is "is it in the room", and that is a box, not a count.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';

import 'support/hoh_frame.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('everything in the room lands inside the room', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final game = await loadRealGame(tester);
    expect(game, isNotNull, reason: 'the game never finished loading');
    final loaded = game!;
    addTearDown(loaded.game.dispose);
    freeze(loaded.game);

    final full = await renderFrame(tester, loaded);

    // The room alone: take the entities and the party away and what is left is
    // the floor and the walls. Its bounding box is where the room is.
    final room = loaded.game.currentRoom;
    expect(room, isNotNull, reason: 'no room is attached to the game');

    final removed = <Component>[];
    for (final entity in room!.entities) {
      entity.removeFromParent();
      removed.add(entity);
    }
    for (final character in room.characters) {
      character.removeFromParent();
      removed.add(character);
    }
    await withLoop(tester, loaded.game, () async {});
    final roomOnly = await renderFrame(tester, loaded);

    for (final child in removed) {
      // Put them back so the second render is the room plus its contents.
      room.add(child);
    }
    await withLoop(tester, loaded.game, () async {});
    final restored = await renderFrame(tester, loaded);

    final roomBox = roomOnly.inkBox;
    final contentsBox = full.boxDifferentFrom(roomOnly);
    // ignore: avoid_print
    print(
      'room ink=${roomOnly.inkCount} box=$roomBox\n'
      'contents ink=${full.pixelsDifferentFrom(roomOnly)} box=$contentsBox\n'
      'restored matches the first frame: '
      '${full.pixelsDifferentFrom(restored) == 0}',
    );

    expect(roomBox, isNotNull, reason: 'the room drew nothing at all');
    expect(
      contentsBox,
      isNotNull,
      reason: 'nothing in the room painted anything',
    );

    final box = roomBox!;
    final contents = contentsBox!;
    // The room is the floor with the walls extruded below it, so a thing standing
    // on the far edge can hang a little outside the floor's own box. Nothing
    // legitimate is more than half a tile outside it.
    const slack = 32.0;
    expect(
      contents.left >= box.left - slack && contents.right <= box.right + slack,
      true,
      reason:
          'what is in the room is not inside the room, horizontally: '
          'contents at x[${contents.left.toStringAsFixed(0)}, '
          '${contents.right.toStringAsFixed(0)}] against a room at '
          'x[${box.left.toStringAsFixed(0)}, ${box.right.toStringAsFixed(0)}]',
    );
    expect(
      contents.top >= box.top - slack && contents.bottom <= box.bottom + slack,
      true,
      reason:
          'what is in the room is not inside the room, vertically: '
          'contents at y[${contents.top.toStringAsFixed(0)}, '
          '${contents.bottom.toStringAsFixed(0)}] against a room at '
          'y[${box.top.toStringAsFixed(0)}, ${box.bottom.toStringAsFixed(0)}]',
    );
  });
}
