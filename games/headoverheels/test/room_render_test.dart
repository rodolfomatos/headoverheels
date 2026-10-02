import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;

import 'package:flame/components.dart';
import 'package:headoverheels/core/isometric.dart';
import 'package:headoverheels/features/gameplay/state/character_notifier.dart';

import 'support/hoh_frame.dart';

/// What the game actually puts on the screen, counted in pixels.
///
/// The party was not in the room and no test noticed. The six ways a drawn
/// object can vanish — not mounted, zero size, no sprite, under the floor,
/// outside the camera, drawn at a degenerate rectangle — look identical to a
/// test that asks whether a `GameWidget` exists. So this draws the frame, takes
/// one object away, draws it again, and counts what changed: a number that is
/// zero means that object drew nothing at all.
///
/// It is one test rather than four, and the reason is measured rather than
/// stylistic. The game loads through awaits that a widget test's fake clock only
/// resolves while the test itself is yielding, and the second time the same
/// awaits are entered in the same file they do not resolve at all: the first
/// test loads in about a second and the next three hang until they time out.
/// One game, loaded once, and four measurements on it.
/// The screen point a grid position maps to, through the game's own camera.
///
/// The same arithmetic the camera does: take the world position, subtract the
/// middle of the room, scale, and put it in the middle of the window. Written
/// out here rather than asked of the game so that the test says where a thing
/// should be instead of asking the thing under test where it is.
Offset onScreen(LoadedGame game, Vector3 grid) {
  final world = IsometricCoordinates.gridToScreen(grid);
  final bounds = game.room.worldBounds!;
  final centre = bounds.center;
  final zoom = game.game.camera.viewfinder.zoom;
  final half = game.game.size / 2;
  return Offset(
    (world.x - centre.dx) * zoom + half.x,
    (world.y - centre.dy) * zoom + half.y,
  );
}

/// How far [point] is from the nearest part of [box]; zero when it is inside.
///
/// A distance rather than an equality, because a sprite is smaller than the box
/// the character stands in and its painted pixels are smaller again. The number
/// that matters is the gap between "inside" and "half a sprite away", and the
/// fault this test was written for puts a character exactly half a sprite away.
double distanceTo(Rect? box, Offset point) {
  if (box == null) return double.infinity;
  double gap(double a, double b) {
    if (a < b) return 0;
    return a - b;
  }

  final dx = gap(box.left, point.dx) + gap(point.dx, box.right);
  final dy = gap(box.top, point.dy) + gap(point.dy, box.bottom);
  return math.sqrt(dx * dx + dy * dy);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'the room draws with the party and everything in it',
    (tester) async {
      final loaded = await loadRealGame(tester);
      expect(loaded, isNotNull, reason: 'the game never finished loading');
      final game = loaded!;

      // --- the party ---------------------------------------------------------
      final withParty = await renderFrame(tester, game);
      await withParty.writePng(tester, 'hoh_room');
      final party = game.party;
      expect(party, hasLength(2), reason: 'the party is two characters');
      for (final character in party) {
        character.removeFromParent();
      }
      await withLoop(tester, game.game, () async {});
      final withoutParty = await renderFrame(tester, game);
      final partyInk = withParty.pixelsDifferentFrom(withoutParty);
      // ignore: avoid_print
      print(
        'frame: ink=${withParty.inkCount} box=${withParty.inkBox}\n'
        'party: ink=$partyInk box=${withParty.boxDifferentFrom(withoutParty)}',
      );
      expect(
        partyInk,
        greaterThan(200),
        reason:
            'the party is in the room and none of it reaches the screen: '
            'taking both characters away changed $partyInk pixels',
      );

      // Where the party must be, from its own grid position and the game's own
      // camera. A count is not enough on its own: the party used to draw a few
      // hundred pixels in a window this size purely because the sprite landed
      // inside the canvas by accident, a whole sprite up and to the left of where
      // the character stands. Being on the screen and being in the right place are
      // two claims, and only the second one catches that.
      for (final character in party) {
        // One character at a time: the two are a tile apart, and a box around
        // both of them says nothing about where either of them is.
        await withLoop(tester, game.game, () async {
          character.removeFromParent();
        });
        final withoutThisOne = await renderFrame(tester, game);
        final drawnAt = withParty.boxDifferentFrom(withoutThisOne);
        await withLoop(tester, game.game, () async {
          await game.game.world.add(character);
        });
        final where = onScreen(game, character.gridPosition);
        final off = distanceTo(drawnAt, where);
        // ignore: avoid_print
        print(
          '${character.type.name} at grid ${character.gridPosition} '
          '-> screen $where, painted at $drawnAt, off by ${off.toStringAsFixed(1)}px',
        );
        expect(
          off,
          lessThan(20),
          reason:
              '${character.type.name} stands at grid ${character.gridPosition}, '
              'which is $where on the screen, and it is painted at $drawnAt: '
              '${off.toStringAsFixed(1)} pixels away. A character drawn half a '
              'sprite up and to the left of where it stands is not in the room.',
        );
      }
      // The rest of the room, with the party back in it.
      await withLoop(tester, game.game, () async {
        for (final character in party) {
          await game.game.world.add(character);
        }
      });

      // --- the party is where its state says it is ---------------------------
      final head = party.first;
      final from = head.gridPosition;
      final beforeMove = await renderFrame(tester, game);
      // Two tiles east, through the notifier the party listens to, so the sprite
      // moves the way it moves when a person plays.
      await withLoop(tester, game.game, () async {
        game.container
            .read(headProvider.notifier)
            .setPosition(Vector3(from.x + 2, from.y, from.z));
      });
      final afterMove = await renderFrame(tester, game);
      await afterMove.writePng(tester, 'hoh_room_moved');
      // ignore: avoid_print
      print(
        'move ${from.x},${from.y} -> ${from.x + 2},${from.y}: '
        'changed=${beforeMove.pixelsDifferentFrom(afterMove)} '
        'box=${afterMove.boxDifferentFrom(beforeMove)}',
      );
      expect(
        beforeMove.pixelsDifferentFrom(afterMove),
        greaterThan(0),
        reason: 'the party does not follow its state',
      );

      // --- every entity draws something --------------------------------------
      // Each entity's art is held on its first frame first. Without that, this
      // measures the animation as well as the sprite: an entity is invisible for
      // as long as its ticker sits on a frame the sheet never filled, so the
      // count depended on which entity had been mounted for how long. Measured
      // that way, `switch_1` came out at 800px with the strip bug and 0px
      // without it, which reads as "the fix erased a switch" and is really "the
      // fix stopped hiding the blank frames".
      await pinArtToFirstFrame(game.room.entities);
      final drawn = <String, int>{};
      final entities = game.room.entities;
      // The whole child list comes out and goes back in its original order, once
      // per entity.
      //
      // Two conventions met here and both were wrong. The loop used to collect
      // removals and restore them at the end, so by the third entity the first
      // two were gone and every number described a room that had been emptied
      // around the thing being measured. Restoring each entity on its own fixed
      // that and broke the draw order instead: `add` appends, `children` is a
      // ReadOnlyOrderedSet with no insert-at-index, so by the time `switch_1` was
      // measured the 1024-wide conveyor had been re-appended *after* it and the
      // switch read 0px while standing plainly visible.
      //
      // So the room under test is always rebuilt exactly as the game built it:
      // every child out, render, every child back in order. A measurement of a
      // room the test has rearranged is not a measurement of the room.
      final children = game.room.children.toList();
      for (final entity in entities) {
        final before = await renderFrame(tester, game);

        // The room without this entity: everything out, then everything back in
        // order except this one. Removing all of them and comparing would measure
        // the floor, and every entity would read the same number.
        await withLoop(tester, game.game, () async {
          for (final child in children) {
            child.removeFromParent();
          }
        });
        await withLoop(tester, game.game, () async {
          for (final child in children) {
            if (child != entity) await game.room.add(child);
          }
        });

        final after = await renderFrame(tester, game);
        drawn[entity.id] = before.pixelsDifferentFrom(after);

        // And back to exactly as the game built it.
        await withLoop(tester, game.game, () async {
          for (final child in children) {
            if (child.parent == null) await game.room.add(child);
          }
        });
      }
      for (final entry in drawn.entries) {
        // ignore: avoid_print
        print('entity ${entry.key}: ${entry.value}px');
      }
      // Asserted after the "alone" pass below, not here. Both passes measure the
      // same thing two ways, and only together do they say whether something is
      // absent or something is covered: asserting here stopped the run before the
      // second pass existed, which is how "hidden by the floor" and "not drawn"
      // stayed indistinguishable.
      final notDrawn = drawn.entries.where((e) => e.value < 10).toList();

      // --- every entity draws with nothing on top of it ----------------------
      // The frame above cannot tell an invisible entity from a hidden one: two
      // triggers on the same tile, the second drawn over the first, and the first
      // measures zero. That is a fault in the data, and `room_maps_test` is where
      // it is caught. This one asks the renderer alone.
      final alone = <String, int>{};
      for (final entity in entities) {
        final parent = entity.parent!;
        final siblings = parent.children.where((c) => c != entity).toList();
        await withLoop(tester, game.game, () async {
          for (final sibling in siblings) {
            sibling.removeFromParent();
          }
        });
        final withIt = await renderFrame(tester, game);
        await withLoop(tester, game.game, () async {
          entity.removeFromParent();
        });
        final withoutIt = await renderFrame(tester, game);
        alone[entity.id] = withIt.pixelsDifferentFrom(withoutIt);
        await withLoop(tester, game.game, () async {
          await parent.add(entity);
          for (final sibling in siblings) {
            await parent.add(sibling);
          }
        });
      }
      for (final entry in alone.entries) {
        // ignore: avoid_print
        print('alone ${entry.key}: ${entry.value}px');
      }
      // Every entity draws something. Measured with the room to itself, because
      // that is the only way this question has one answer: an entity drawn under
      // another one is not absent, and the strip bug used to spill enough ink
      // onto uncovered neighbours to make a covered switch look present.
      expect(
        alone.values.where((n) => n < 10).toList(),
        isEmpty,
        reason:
            'these entities draw nothing even with the room to themselves: '
            '${alone.entries.where((e) => e.value < 10).map((e) => e.key).toList()}. '
            'They are absent rather than covered.',
      );

      // An entity drawn under a later sibling is a z-order question, not a
      // rendering one. There are none: `switch_1` used to be one, covered by a
      // 1024-wide ConveyorEntity sharing its row, and the fix was a draw order
      // rather than a bigger sprite. The list stays pinned and empty so a second
      // covered entity fails here rather than being noticed by a player.
      //
      // See aes/tickets/T088.
      expect(
        notDrawn.map((e) => e.key).toList(),
        isEmpty,
        reason:
            'covered entities: ${notDrawn.map((e) => '${e.key}=${alone[e.key]}px').toList()}. '
            'Each draws ${notDrawn.map((e) => alone[e.key]).toList()} alone and '
            'nothing in the room, so it is drawn under a later sibling.',
      );
      expect(
        alone.values.where((n) => n < 10).toList(),
        isEmpty,
        reason:
            'these entities draw nothing even with the room to themselves: '
            '${alone.entries.where((e) => e.value < 10).map((e) => e.key).toList()}',
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
