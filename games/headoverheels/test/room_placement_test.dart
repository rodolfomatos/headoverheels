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
//
// The aggregate guard that used to be here is gone, and that is the point.
//
// The union of everything in a room is nearly as large as the room, so an
// aggregate check passes with any individual entity anywhere: sixteen entities
// placed correctly and one in the corner give the same union as seventeen
// correct ones. That is why every placement defect in this project's history
// passed the guard that was written to catch them. It was measuring the room and
// calling it the contents. The aggregate check is kept below as the cheap smoke
// test it always was, and it is no longer the thing that holds the line.
//
// Both measurements rebuild the room exactly as the game built it: every child
// out, render, every child back in original order except the one under test,
// render, every child back. Restoring a single entity with `add` is not enough,
// because `add` appends and `children` is a ReadOnlyOrderedSet with no
// insert-at-index — the restore moves the entity to the top of the draw order,
// which manufactured a covered switch once already. See D007.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart' show TiledComponent;

import 'support/hoh_frame.dart';

/// Half a tile. The room is the floor with the walls extruded below it, so a
/// thing standing on the far edge can hang a little outside the floor's own box.
const slack = 32.0;

Future<LoadedGame> boot(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // `loadRealGame` already registers the teardown: it takes the widget down
  // before disposing the game. Disposing again here leaves the widget's ticker
  // live, and the next test's `pump` waits for a frame that never comes -- which
  // reads as "the game never finished loading" in a test that has nothing to do
  // with the game.
  final loaded = await loadRealGame(tester);
  expect(loaded, isNotNull, reason: 'the game never finished loading');
  freeze(loaded!.game);
  await pinArtToFirstFrame(loaded.room.entities);
  return loaded;
}

/// The frame of the room with [drop] removed and everything else in place.
///
/// Order is preserved by re-adding in the original order. `add` appends, and the
/// child set is a `ReadOnlyOrderedSet` with no insert-at-index, so any restore
/// that does not rebuild the whole list changes the draw order as a side effect
/// -- which manufactured a covered switch once, in the room's own test.
///
/// The floor is a child like any other, and dropping it leaves 60x72 pixels of
/// wall rather than a room. "The room alone" therefore means the tilemap and
/// nothing else, which is why this takes the set to drop rather than the one to
/// keep.
Future<Frame> without(
  WidgetTester tester,
  LoadedGame game,
  List<Component> children,
  Set<Component> drop,
) async {
  await withLoop(tester, game.game, () async {
    for (final child in children) {
      if (drop.contains(child)) child.removeFromParent();
    }
  });
  await withLoop(tester, game.game, () async {});
  return renderFrame(tester, game);
}

/// Puts every child back, in the original order.
Future<void> restore(
  WidgetTester tester,
  LoadedGame game,
  List<Component> children,
) async {
  await withLoop(tester, game.game, () async {
    for (final child in children) {
      if (child.parent == null) await game.room.add(child);
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('every entity is drawn inside the room it belongs to', (
    tester,
  ) async {
    final game = await boot(tester);
    final room = game.room;
    final children = room.children.toList();

    // The room's own box: floor and walls, nothing else.
    final floor = children.whereType<TiledComponent>().toList();
    expect(
      floor,
      hasLength(1),
      reason:
          'the room has no tilemap, so there is no floor to measure '
          'against: $children',
    );

    final roomOnly = await without(
      tester,
      game,
      children,
      children.where((c) => !floor.contains(c)).toSet(),
    );
    await restore(tester, game, children);
    final rebuilt = await renderFrame(tester, game);

    final box = roomOnly.inkBox!;
    // ignore: avoid_print
    print('room ink=${roomOnly.inkCount} box=$box');

    // The rebuild has to reproduce the room, or every measurement below is of a
    // room the test built. This is the check that makes the convention safe, and
    // it is the check the previous version of this file did not make.
    expect(
      rebuilt.pixelsDifferentFrom(roomOnly) > 0,
      isTrue,
      reason:
          'putting the contents back changed nothing, so the room-only '
          'frame is not the room without its contents',
    );

    final misplaced = <String>[];
    final invisible = <String>[];

    for (final entity in room.entities) {
      final withoutIt = await without(tester, game, children, {entity});
      await restore(tester, game, children);

      // Where the entity drew: the room with it, against the room without it.
      final where = roomOnly.boxDifferentFrom(withoutIt);
      if (where == null) {
        invisible.add(entity.id);
        continue;
      }
      // A device that the map itself declares as spanning the room is allowed
      // to span it. `conveyor_1` is `x=0 width=1024` in castle_start.tmx: the
      // full room width, and the belt is the floor treatment. The room's *ink*
      // box is narrower than its declared extent because the floor does not paint
      // to the very edge, so the belt is wider than the floor by construction.
      //
      // This is an enumerated exception rather than a larger slack. A slack that
      // big would let a genuinely misplaced entity through, which is the fault
      // this guard was written to remove.
      const fullWidth = {'conveyor_1'};
      final tooWide = fullWidth.contains(entity.id)
          ? (where.top < box.top - slack || where.bottom > box.bottom + slack)
          : (where.left < box.left - slack ||
                where.right > box.right + slack ||
                where.top < box.top - slack ||
                where.bottom > box.bottom + slack);
      if (tooWide) {
        misplaced.add(
          '${entity.id} drew at '
          'x[${where.left.toStringAsFixed(0)},'
          '${where.right.toStringAsFixed(0)}] '
          'y[${where.top.toStringAsFixed(0)},'
          '${where.bottom.toStringAsFixed(0)}]; the room is at '
          'x[${box.left.toStringAsFixed(0)},${box.right.toStringAsFixed(0)}] '
          'y[${box.top.toStringAsFixed(0)},${box.bottom.toStringAsFixed(0)}]',
        );
      }
    }

    expect(
      invisible,
      isEmpty,
      reason:
          'these entities have no box to check at all: $invisible. '
          'room_render_test owns "does it draw"; this one asks "is it here".',
    );
    expect(
      misplaced,
      isEmpty,
      reason: 'these entities are not drawn inside the room: $misplaced',
    );
  });
}
