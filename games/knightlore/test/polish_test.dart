import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:knightlore/knightlore.dart';

import 'test_asset_bundle.dart';
import 'visual_preview_test.dart' show canvasSize, readFrame, renderFrame;

/// Renders [view] off screen and returns the raw pixels.
Future<ByteData> renderRoom(RoomView view, {required bool shadows}) async {
  view.drawShadows = shadows;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1024, 640));
  canvas.drawColor(const Color(0xFF101216), BlendMode.src);
  view.renderInto(canvas, canvasSize);
  final image = await recorder.endRecording().toImage(1024, 640);
  return (await image.toByteData())!;
}

/// Which pixels of [after] differ from [before], and in which direction.
({Rect changed, int darker, int lighter}) compareFrames(ByteData before, ByteData after) {
  var minX = 1024, minY = 640, maxX = -1, maxY = -1;
  var darker = 0, lighter = 0;
  for (var y = 0; y < 640; y++) {
    for (var x = 0; x < 1024; x++) {
      final offset = (y * 1024 + x) * 4;
      final a = before.getUint8(offset);
      final b = after.getUint8(offset);
      if (a == b) continue;
      if (b < a) {
        darker++;
      } else {
        lighter++;
      }
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
  }
  return (
    changed: maxX < 0
        ? Rect.zero
        : Rect.fromLTRB(minX.toDouble(), minY.toDouble(), maxX.toDouble(), maxY.toDouble()),
    darker: darker,
    lighter: lighter,
  );
}

Future<KnightLoreGame> loaded({String? room}) async {
  final game = KnightLoreGame(
    config: const KnightLoreGameConfig(daySeconds: 1000, autoCycle: false),
    bundle: TestAssetBundle(),
  );
  await game.onLoad();
  if (room != null) game.session!.enterRoom(room);
  return game;
}

void main() {
  group('ambience', () {
    test('every area in the world has an ambience', () {
      final world = KnightLoreWorld.build();
      final themes = world.rooms.values.map((room) => room.theme).toSet();
      for (final theme in themes) {
        expect(
          Ambience.byArea.containsKey(theme),
          isTrue,
          reason: 'no ambience for $theme',
        );
      }
    });

    test('each area has its own light', () {
      final backgrounds = <String, Color>{};
      for (final area in KlAreas.all) {
        backgrounds[area] = Ambience.of(area).background;
      }
      expect(
        backgrounds.values.toSet().length,
        KlAreas.all.length,
        reason: 'two areas are lit the same: $backgrounds',
      );
    });

    test('the wash never hides the room', () {
      for (final area in KlAreas.all) {
        expect(Ambience.of(area).strength, inInclusiveRange(0.05, 0.6));
        // The background has to stay dark enough to read as a room, not a
        // coloured rectangle.
        expect(Ambience.of(area).background.computeLuminance(), lessThan(0.4));
      }
    });

    test('night is darker than day in every area', () {
      for (final area in KlAreas.all) {
        final day = Ambience.of(area).backgroundFor(area, isNight: false);
        final night = Ambience.of(area).backgroundFor(area, isNight: true);
        expect(
          night.computeLuminance(),
          lessThan(day.computeLuminance()),
          reason: '$area is not darker at night',
        );
      }
    });
  });

  group('shadows', () {
    test('a shadow is a flattened ellipse below the figure', () {
      const shape = ShadowShape(centre: Offset(100, 100), radius: 10);
      expect(shape.bounds.width, 20);
      expect(shape.bounds.height, 10, reason: 'the floor squashes it');
      expect(shape.bounds.center.dx, closeTo(100, 0.01));
      expect(shape.bounds.center.dy, greaterThan(100));
    });

    test('a shadow is really drawn under the figures', () async {
      // The same room twice, with and without shadows. Rather than guessing
      // where a shadow should land, this asks the pixels: which ones changed,
      // and is a figure standing in the region that changed.
      final game = await loaded();
      addTearDown(game.dispose);
      final view = game.createView()!;
      final plain = await renderRoom(view, shadows: false);
      final shadowed = await renderRoom(view, shadows: true);
      final diff = compareFrames(plain, shadowed);

      expect(
        diff.changed,
        isNot(Rect.zero),
        reason: 'turning shadows on changed nothing at all',
      );
      // A shadow darkens the floor, it never lightens it.
      expect(diff.darker, greaterThan(200));
      expect(diff.lighter, 0);

      // A figure has to be standing in the region that changed.
      final figures = <Offset>[
        view.canvasOf(view.screenOf(game.session!.leader.position)),
        for (final object in view.map!.objects)
          if (view.sprites[object.type] != null)
            view.canvasOf(view.screenOf(object.position)),
      ];
      expect(figures, isNotEmpty);
      expect(
        figures.where((point) => diff.changed.inflate(4).contains(point)),
        isNotEmpty,
        reason: 'the shadow is not under any figure: ${diff.changed}',
      );
      // The room still has to be a room, not a black square.
      expect((await readFrame(await renderFrame(game))).colours, greaterThan(20));
    });
  });

  group('room transitions', () {
    test('a room change starts a fade and it runs out', () async {
      final game = await loaded();
      addTearDown(game.dispose);
      // Off screen the game is never mounted, so the view is attached here.
      game.roomView = game.createView()!;
      expect(game.transition, 0);
      expect(game.isTransitioning, isFalse);

      game.beginTransition();
      expect(game.transition, 1);
      expect(game.roomView?.fade, 1);
      expect(game.roomView?.ambienceStrength, 0);

      for (var frame = 0; frame < 30; frame++) {
        game.update(1 / 60);
      }
      expect(game.transition, 0);
      expect(game.roomView?.fade, 0);
      expect(game.roomView?.ambienceStrength, 1);
    });

    test('the fade lasts about the declared time', () async {
      final game = await loaded();
      addTearDown(game.dispose);
      game.roomView = game.createView()!;
      game.beginTransition();
      game.update(KnightLoreGame.transitionSeconds / 2);
      expect(game.transition, closeTo(0.5, 0.05));
      game.update(KnightLoreGame.transitionSeconds / 2);
      expect(game.transition, 0);
    });

    test('a fade never leaves the range zero to one', () async {
      final game = await loaded();
      addTearDown(game.dispose);
      game.roomView = game.createView()!;
      game.beginTransition();
      for (var frame = 0; frame < 200; frame++) {
        game.update(1 / 30);
        expect(game.transition, inInclusiveRange(0, 1));
        expect(game.roomView!.fade, inInclusiveRange(0, 1));
      }
    });

    test('a big frame does not overshoot the fade', () async {
      final game = await loaded();
      addTearDown(game.dispose);
      game.beginTransition();
      // A stall of a whole second must not push the value negative.
      game.update(1);
      expect(game.transition, 0);
    });
  });

  group('the sundial', () {
    test('the marker turns as the days pass', () {
      final first = SundialGeometry(days: 1, totalDays: 40);
      final last = SundialGeometry(days: 40, totalDays: 40);
      expect(first.markerAngle, closeTo(-1.5708, 0.001));
      expect(last.progress, closeTo(39 / 40, 0.0001));
      // The dial makes a full turn over the game, so the last day is exactly
      // one tick short of where the first day started. Angles wrap, so the
      // distance is measured forwards from the last day to the first.
      const turn = 2 * 3.14159265;
      var travelled = (first.markerAngle - last.markerAngle) % turn;
      if (travelled < 0) travelled += turn;
      expect(travelled, closeTo(turn / 40, 0.0001));
      // And the marker never sits still between two days.
      final middle = SundialGeometry(days: 2, totalDays: 40);
      expect(middle.markerAngle, isNot(closeTo(first.markerAngle, 0.01)));
    });

    test('the dial has one tick per day', () {
      final geometry = SundialGeometry(days: 12, totalDays: 40);
      expect(geometry.ticks.length, 40);
      for (final tick in geometry.ticks) {
        expect(tick.distance, closeTo(1, 0.0001));
      }
    });

    test('the marker sits on the tick of its own day', () {
      for (var day = 1; day <= 40; day++) {
        final geometry = SundialGeometry(days: day, totalDays: 40);
        final marker = geometry.markerAt(1);
        expect(
          (marker - geometry.ticks[day - 1]).distance,
          lessThan(0.0001),
          reason: 'day $day points at the wrong tick',
        );
      }
    });

    test('days left and days on the dial agree', () {
      const total = 40;
      for (var left = total; left >= 0; left--) {
        final daysOn = total - left + 1;
        expect(
          SundialGeometry(days: daysOn, totalDays: total).progress,
          closeTo((daysOn - 1) / total, 0.0001),
        );
      }
    });

    test('the painter repaints only when the day or the light changes', () {
      const day = SundialGeometry(days: 1, totalDays: 40);
      const next = SundialGeometry(days: 2, totalDays: 40);
      final painter = SundialPainter(geometry: day, isNight: false);
      expect(painter.shouldRepaint(painter), isFalse);
      expect(
        painter.shouldRepaint(
          const SundialPainter(geometry: next, isNight: false),
        ),
        isTrue,
      );
      expect(
        painter.shouldRepaint(
          const SundialPainter(geometry: day, isNight: true),
        ),
        isTrue,
      );
    });

    testWidgets('the sundial is on the hud and draws', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Sundial(daysLeft: 20, totalDays: 40, isNight: false),
          ),
        ),
      );
      expect(find.byType(Sundial), findsOneWidget);
      final painter = tester
          .widget<CustomPaint>(
            find.descendant(
              of: find.byType(Sundial),
              matching: find.byType(CustomPaint),
            ),
          )
          .painter! as SundialPainter;
      expect(painter.geometry.ticks.length, 40);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the hud shows the sundial once the game starts', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      late KnightLoreGame game;
      await tester.runAsync(() async {
        game = KnightLoreGame(
          config: const KnightLoreGameConfig(daySeconds: 1000, autoCycle: false),
          bundle: TestAssetBundle(),
        );
        await game.onLoad();
      });
      addTearDown(game.dispose);

      await tester.pumpWidget(KnightLoreApp(game: game));
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(Sundial), findsOneWidget);
      final painter = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(Sundial),
          matching: find.byType(CustomPaint),
        ),
      ).painter! as SundialPainter;
      expect(painter.geometry.totalDays, 40);
    });
  });
}
