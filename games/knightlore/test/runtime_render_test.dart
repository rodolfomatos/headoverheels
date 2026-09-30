import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart' show Vector2;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightlore/knightlore.dart';

import 'test_asset_bundle.dart';

/// Where the running game puts the room.
///
/// The room was drawn in the corner of the window at its own size, and every
/// test in the suite said the room is drawn perfectly, because every one of
/// them renders through `RoomView.renderInto` — which is the same helper the
/// code it tests uses, with the centring and the scale inside it. A test that
/// renders the way the game renders is the one that was missing.
///
/// So this asks the two halves of the question separately, because they broke
/// separately: does the game tell the view how big the canvas is, and does the
/// view's own `render` — the method the component tree calls, the one
/// `renderInto` used to be a wrapper around — fit the room into it?
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const window = Size(1280, 800);

  late KnightLoreGame game;
  setUpAll(() async {
    // Decoding forty-nine images is real async work. In a widget test it has to
    // happen inside `runAsync`: a future started in the fake clock never
    // completes, which is why a `GameWidget` cannot finish loading a game in a
    // test at all (measured: the widget's own load never returns, so
    // `game.mount()` is never reached and the loop never steps).
    game = await _loadGame();
  });
  tearDownAll(() => game.dispose());

  test('the game tells the room view how big the canvas is', () {
    // The size used to be set in the frame loop, and only while a room was
    // fading, which was enough for the fade and nothing else.
    game.onGameResize(Vector2(window.width, window.height));
    expect(game.roomView, isNotNull, reason: 'no room is attached to the game');
    expect(
      game.roomView!.canvasSize,
      window,
      reason:
          'the view was never told the canvas size, so the room fitted nothing '
          'and was drawn at its own size in the corner',
    );
  });

  test('the running game centres and scales the room', () async {
    game.onGameResize(Vector2(window.width, window.height));
    final view = game.roomView!;
    expect(view.map, isNotNull, reason: 'the room has no map');

    // The game's own draw: the component's `render`, on a canvas of the same
    // shape as the window, with no helper and no size argument. This is the
    // path a player gets and the one no test took.
    final frame = await _shoot(view, window);
    await _writePng(frame, 'knightlore_runtime');
    // ignore: avoid_print
    print(
      'room: ink=${frame.inkCount} colours=${frame.colours} box=${frame.box} '
      'scale=${view.previewScale.toStringAsFixed(3)} '
      'offset=${view.previewOffset}',
    );

    expect(
      frame.inkCount,
      greaterThan(20000),
      reason: 'the game draws an almost empty frame',
    );

    final box = frame.box!;
    final left = box[0].toDouble();
    final right = (frame.width - box[2]).toDouble();
    final top = box[1].toDouble();
    final bottom = (frame.height - box[3]).toDouble();
    // ignore: avoid_print
    print('margins: left=$left right=$right top=$top bottom=$bottom');

    // Centred: the left and right margins are the same, and the top and bottom
    // are, to within a tile's worth of slack for a room whose corners are not
    // square.
    expect(
      (left - right).abs(),
      lessThan(80),
      reason: 'the room is not centred horizontally: $left and $right to the '
          'edges of a ${frame.width}x${frame.height} frame',
    );
    expect(
      (top - bottom).abs(),
      lessThan(80),
      reason: 'the room is not centred vertically: $top and $bottom to the '
          'edges of a ${frame.width}x${frame.height} frame',
    );
    // Fitted: the room reaches near the edges, which it cannot do at one to one
    // in a window wider than the room is.
    expect(
      math.min(left, right),
      lessThan(frame.width * 0.1),
      reason: 'the room does not fill the width: $left and $right to the edges',
    );
    expect(
      math.min(top, bottom),
      lessThan(frame.height * 0.1),
      reason:
          'the room does not fill the height: $top and $bottom to the edges',
    );
  });
}

/// A frame of a rendered room: one 24-bit colour per pixel, row by row.
class _Frame {
  const _Frame(this.pixels, this.width, this.height);

  final Uint32List pixels;
  final int width;
  final int height;

  int get colours => pixels.toSet().length;

  int get inkCount {
    var n = 0;
    for (var i = 0; i < pixels.length; i++) {
      if (pixels[i] != _Frame.background) n++;
    }
    return n;
  }

  /// The box around everything that is not the background.
  List<int>? get box {
    var minX = width, minY = height, maxX = -1, maxY = -1;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (pixels[y * width + x] == _Frame.background) continue;
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
    return maxX < 0 ? null : [minX, minY, maxX + 1, maxY + 1];
  }

  /// The colour behind a room, the same one the game's scaffold uses.
  static const int background = 0x101216;
}

Future<_Frame> _shoot(RoomView view, Size size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));
  canvas.drawColor(const Color(0xFF101216), BlendMode.src);
  view.render(canvas);
  final image = await recorder
      .endRecording()
      .toImage(size.width.toInt(), size.height.toInt());
  final data = await image.toByteData();
  final bytes = data!.buffer.asUint8List();
  final pixels = Uint32List((size.width * size.height).toInt());
  for (var i = 0; i < pixels.length; i++) {
    final o = i * 4;
    pixels[i] = (bytes[o] << 16) | (bytes[o + 1] << 8) | bytes[o + 2];
  }
  image.dispose();
  return _Frame(pixels, size.width.toInt(), size.height.toInt());
}

Future<void> _writePng(_Frame frame, String name) async {
  final rgba = Uint8List(frame.pixels.length * 4);
  for (var i = 0; i < frame.pixels.length; i++) {
    final c = frame.pixels[i];
    rgba[i * 4] = (c >> 16) & 0xFF;
    rgba[i * 4 + 1] = (c >> 8) & 0xFF;
    rgba[i * 4 + 2] = c & 0xFF;
    rgba[i * 4 + 3] = 0xFF;
  }
  final completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    rgba,
    frame.width,
    frame.height,
    ui.PixelFormat.rgba8888,
    completer.complete,
  );
  final image = await completer.future;
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('build/preview/$name.png');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(png!.buffer.asUint8List());
  image.dispose();
  // ignore: avoid_print
  print('wrote ${file.path}');
}

/// Loads the real game off disk: the real world, the real rooms, the real art.
Future<KnightLoreGame> _loadGame() async {
  final game = KnightLoreGame(
    config: const KnightLoreGameConfig(daySeconds: 1000, autoCycle: false),
    bundle: TestAssetBundle(),
  );
  await game.onLoad();
  expect(game.assetsReady, isTrue, reason: game.error);
  return game;
}
