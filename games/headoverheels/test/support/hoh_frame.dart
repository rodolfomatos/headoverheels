/// Renders the real game off-screen and measures it in pixels.
///
/// The reason this file exists: the game drew a floor and no party, and every
/// test in the suite said the game was fine. To a widget test a game that
/// renders one colour and a game that renders a room with everything in it look
/// the same, so the only way to know is to draw the frame and look at the
/// pixels.
///
/// The frame comes from the real widget path — a real `GameWidget` over a real
/// `HeadOverHeelsGame` over the real world, with the real room map, the real
/// tileset and the real sprites — and only the sounds are sent somewhere else.
/// `just_audio` has no implementation off a device and throws out of an
/// initialiser the load waits on, which is the reason the board gives for a
/// frame that could never be drawn in a test.
///
/// The board also records that a widget test never finishes, and it did: when
/// the load waited for all sixty-five sprites and for an audio plugin, decoding
/// eighty-five images inside a widget test took forty-one seconds and did not
/// end. It ends in about a second now, because the load asks for four images a
/// character and the rest arrives without holding the first frame (T065) and
/// the sounds go to a silent sink (T059). The trick is that the load needs the
/// real event loop and the frames need `pump`, and the two cannot be inside each
/// other: so the loop alternates a real delay with a pump.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:headoverheels/features/audio/audio_system.dart';
import 'package:headoverheels/features/gameplay/entities/character_component.dart';
import 'package:headoverheels/features/gameplay/game.dart';
import 'package:headoverheels/features/gameplay/entities/puzzle_entity.dart';
import 'package:headoverheels/features/gameplay/room/room_component.dart';
import 'package:headoverheels/features/gameplay/room/world_loader.dart';

/// The size of the window the game is measured in.
const Size windowSize = Size(1280, 800);

/// The colour behind a frame. Anything else was drawn.
const int frameBackground = 0x101216;

/// A rendered frame: one 24-bit colour per pixel, row by row.
class Frame {
  const Frame(this.pixels, this.width, this.height);

  final Uint32List pixels;
  final int width;
  final int height;

  /// How many pixels are not the background.
  int get inkCount {
    var n = 0;
    for (var i = 0; i < pixels.length; i++) {
      if (pixels[i] != frameBackground) n++;
    }
    return n;
  }

  /// The box around everything that was drawn, or null for an empty frame.
  Rect? get inkBox => _boxWhere((i) => pixels[i] != frameBackground);

  /// How many pixels differ between this frame and [other].
  int pixelsDifferentFrom(Frame other) {
    var n = 0;
    for (var i = 0; i < pixels.length; i++) {
      if (pixels[i] != other.pixels[i]) n++;
    }
    return n;
  }

  /// The box around everything that differs from [other], or null.
  Rect? boxDifferentFrom(Frame other) =>
      _boxWhere((i) => pixels[i] != other.pixels[i]);

  Rect? _boxWhere(bool Function(int i) wanted) {
    var minX = width, minY = height, maxX = -1, maxY = -1;
    for (var i = 0; i < pixels.length; i++) {
      if (!wanted(i)) continue;
      final x = i % width;
      final y = i ~/ width;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
    if (maxX < 0) return null;
    return Rect.fromLTRB(
      minX.toDouble(),
      minY.toDouble(),
      (maxX + 1).toDouble(),
      (maxY + 1).toDouble(),
    );
  }

  /// Writes the frame to `build/preview/<name>.png` for a human to open.
  ///
  /// The encoding runs inside [tester]'s real async zone: outside it, a widget
  /// test's fake clock never runs the callback that finishes the image, and the
  /// test waits for ever.
  Future<void> writePng(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final image = await toImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/preview/$name.png');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(png!.buffer.asUint8List());
      image.dispose();
    });
  }

  /// The frame as an image, so a human can look at it.
  Future<ui.Image> toImage() {
    final rgba = Uint8List(pixels.length * 4);
    for (var i = 0; i < pixels.length; i++) {
      final c = pixels[i];
      rgba[i * 4] = (c >> 16) & 0xFF;
      rgba[i * 4 + 1] = (c >> 8) & 0xFF;
      rgba[i * 4 + 2] = c & 0xFF;
      rgba[i * 4 + 3] = 0xFF;
    }
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }
}

/// A loaded game and the pieces the measurements reach for.
class LoadedGame {
  LoadedGame(this.game, this.container, this.room);

  final HeadOverHeelsGame game;
  final ProviderContainer container;
  final RoomComponent room;

  /// The party, head first.
  List<CharacterComponent> get party {
    final all = <CharacterComponent>[];
    game.children.query<CharacterComponent>().forEach(all.add);
    game.world.children.query<CharacterComponent>().forEach(all.add);
    room.children.query<CharacterComponent>().forEach(all.add);
    all.sort((a, b) => a.type.index.compareTo(b.type.index));
    return all;
  }
}

/// Builds the real game over the real world, through the real widget, and
/// lays it out in [windowSize].
///
/// Returns null when the load does not finish, rather than hanging: a guard
/// that hangs tells a person nothing about which half of it broke.
Future<LoadedGame?> loadRealGame(WidgetTester tester) async {
  // One device pixel per logical pixel. At the default of three, the game
  // renders into a 3840x2400 surface on every pump, and a test that pumps a few
  // hundred times takes minutes instead of seconds for a picture no bigger.
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = windowSize;
  addTearDown(tester.view.reset);

  // Read through the real event loop. A platform message that a widget test's
  // fake clock never advances hangs the second time it is asked for, which is
  // why the first test in a file works and the second does not.
  final world = await tester.runAsync(loadWorldGraph);
  if (world == null) {
    throw StateError('the world did not load');
  }
  final container = ProviderContainer(
    overrides: [
      audioSystemProvider.overrideWithValue(
        AudioSystem(sink: const SilentAudioSink()),
      ),
    ],
  );
  final game = HeadOverHeelsGame(container.read(gameRefProvider), world);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: GameWidget<HeadOverHeelsGame>(game: game),
      ),
    ),
  );

  // The load needs the real event loop; the frames need `pump`. They cannot be
  // inside each other, so the loop alternates the two until the game is loaded.
  for (var i = 0; i < 600 && !game.isLoaded; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump();
  }
  freeze(game);

  // The teardown takes the widget down before the game. The order matters and
  // finding it out cost a five-minute timeout per test: a `GameWidget` owns a
  // ticker, and disposing the game out from under a mounted widget leaves that
  // ticker live, so the next test's `pump` waits for a frame that never comes.
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    game.dispose();
    container.dispose();
  });
  return game.isLoaded ? LoadedGame(game, container, game.currentRoom!) : null;
}

/// Draws the game and reads the frame back.
Future<Frame> renderFrame(WidgetTester tester, LoadedGame loaded) async {
  late Frame frame;
  await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, windowSize.width, windowSize.height),
    );
    canvas.drawColor(const Color(0xFF101216), BlendMode.src);
    loaded.game.renderTree(canvas);
    final image = await recorder.endRecording().toImage(
      windowSize.width.toInt(),
      windowSize.height.toInt(),
    );
    final data = await image.toByteData();
    final bytes = data!.buffer.asUint8List();
    final pixels = Uint32List((windowSize.width * windowSize.height).toInt());
    for (var i = 0; i < pixels.length; i++) {
      final o = i * 4;
      pixels[i] = (bytes[o] << 16) | (bytes[o + 1] << 8) | bytes[o + 2];
    }
    image.dispose();
    frame = Frame(pixels, image.width, image.height);
  });
  return frame;
}

/// Lets the game settle, so a frame is not taken mid-load.
Future<void> settle(WidgetTester tester, {int frames = 2}) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 16)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// Runs [change], lets the game act on it, and stops the loop again.
///
/// A component that is added or removed is acted on by the next frame, so a
/// frozen game has to be woken for the change to happen at all. The frame is
/// taken afterwards, frozen, and the two frames then differ by the change and
/// nothing else.
Future<void> withLoop(
  WidgetTester tester,
  HeadOverHeelsGame game,
  Future<void> Function() change,
) async {
  game.resumeEngine();
  await change();
  await settle(tester, frames: 1);
  freeze(game);
}

/// Stops the game loop, so two frames of the same room differ only by what a
/// test changed.
///
/// This is what makes the measurements exact rather than approximate. With the
/// loop running, a `pump` between two frames advances a patrolling monster, an
/// eight-frame belt and a hundred other pixels, so "take this entity away and
/// see what changed" measures the room as well. Paused, the room stands still
/// and the difference is the entity. The state a character listens to still
/// moves it: that is a provider, not a frame.
void freeze(HeadOverHeelsGame game) => game.pauseEngine();

/// Holds every entity's art on its first frame.
///
/// An entity's sprite is a strip, and the manifest may claim more frames than the
/// sheet has cells filled. A playing animation therefore alternates between
/// drawing and drawing nothing, and any pixel count or bounding box taken from it
/// is a measurement of the clock rather than of the art. Frame zero is the frame
/// the art is drawn from and the frame a player sees standing still.
///
/// This lives in the harness rather than in one test because two tests needed it
/// and a second copy would drift from the first.
Future<void> pinArtToFirstFrame(Iterable<PuzzleEntity> entities) async {
  for (final entity in entities) {
    for (final child in entity.children) {
      if (child is SpriteAnimationComponent) {
        child.playing = false;
        child.animationTicker?.reset();
      }
    }
  }
}
