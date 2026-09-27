import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knightlore/knightlore.dart';

import 'test_asset_bundle.dart';

/// Renders real frames of the game to PNG files, so the look of the game can be
/// checked without a display. The files land in `build/preview/`.
const Size canvasSize = Size(1024, 640);

/// The colour `RoomView` paints behind a room.
const int backgroundColour = 0x101216;

/// One room of each area, to prove the five areas look different.
const Map<String, String> roomsPerArea = {
  KlAreas.castle: KlRooms.gatehouse,
  KlAreas.jungle: KlRooms.jungleTrack,
  KlAreas.cauldron: KlRooms.cauldronCave,
  KlAreas.mine: KlRooms.mineVault,
  KlAreas.tower: KlRooms.towerTop,
};

Future<ui.Image> renderFrame(KnightLoreGame game) async {
  final view = game.createView();
  if (view == null) throw StateError('the game has no room view');
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1024, 640));
  canvas.drawColor(const Color(0xFF101216), BlendMode.src);
  view.renderInto(canvas, canvasSize);
  final picture = recorder.endRecording();
  return picture.toImage(1024, 640);
}

/// Writes [image] to `build/preview/<name>.png` for a human to open.
///
/// The bytes are read here, so nothing else may call `toByteData` on the image.
Future<void> writeFrame(ui.Image image, String name) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('build/preview/$name.png');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(data!.buffer.asUint8List());
  image.dispose();
}

/// What a test needs to know about one rendered frame.
class Frame {
  const Frame({
    required this.colours,
    required this.hash,
    required this.ink,
  });

  /// How many distinct colours were drawn. A blank frame has none.
  final int colours;

  /// A checksum of everything drawn, so two frames can be told apart.
  final int hash;

  /// The bounding box of everything drawn, background excluded.
  final Rect ink;
}

/// Reads one frame.
///
/// The bytes come out of an image exactly once, so everything is measured in a
/// single pass.
Future<Frame> readFrame(ui.Image image) async {
  final data = await image.toByteData();
  final bytes = data!.buffer.asUint8List();
  var minX = image.width;
  var minY = image.height;
  var maxX = -1;
  var maxY = -1;
  final seen = <int>{};
  var hash = 0x811c9dc5;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final offset = (y * image.width + x) * 4;
      final colour =
          (bytes[offset] << 16) | (bytes[offset + 1] << 8) | bytes[offset + 2];
      if (colour == backgroundColour) continue;
      seen.add(colour);
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
      // FNV-1a over the pixel colour: order sensitive, so a shifted room
      // hashes differently even when the palette is the same.
      hash = ((hash ^ colour) * 0x01000193) & 0xFFFFFFFF;
    }
  }
  return Frame(
    colours: seen.length,
    hash: hash,
    ink: maxX < 0
        ? Rect.zero
        : Rect.fromLTRB(
            minX.toDouble(),
            minY.toDouble(),
            maxX.toDouble(),
            maxY.toDouble(),
          ),
  );
}

Future<KnightLoreGame> loadedGame({String? room}) async {
  final game = KnightLoreGame(
    config: const KnightLoreGameConfig(daySeconds: 1000, autoCycle: false),
    bundle: TestAssetBundle(),
  );
  await game.onLoad();
  if (room != null) game.session!.enterRoom(room);
  return game;
}

/// The party only becomes the four knights at night, as in the game loop.
void turnIntoKnights(KnightLoreGame game) {
  game.session!
    ..nightFalls()
    ..splitParty();
}

void main() {
  test('a room is drawn whole, with tiles and the party', () async {
    final game = await loadedGame();
    addTearDown(game.dispose);
    final image = await renderFrame(game);
    final frame = await readFrame(image);
    await writeFrame(image, 'area_castle');

    expect(frame.colours, greaterThan(15), reason: 'the frame is nearly blank');

    // The room is a diamond, so its corners stay empty, but it must not be
    // cropped: the drawing has to reach close to every edge of the canvas.
    expect(
      frame.ink.width,
      greaterThan(canvasSize.width * 0.95),
      reason: 'the room is cropped left or right',
    );
    expect(
      frame.ink.height,
      greaterThan(canvasSize.height * 0.7),
      reason: 'the room is cropped top or bottom',
    );
    expect(frame.ink.left, lessThan(canvasSize.width * 0.05));
    expect(frame.ink.right, greaterThan(canvasSize.width * 0.95));
  });

  test('every area draws a different room', () async {
    final hashes = <String, int>{};
    for (final entry in roomsPerArea.entries) {
      final game = await loadedGame(room: entry.value);
      addTearDown(game.dispose);
      final image = await renderFrame(game);
      final frame = await readFrame(image);
      await writeFrame(image, 'area_${entry.key}');
      expect(
        frame.colours,
        greaterThan(15),
        reason: 'the ${entry.key} room is nearly blank',
      );
      hashes[entry.key] = frame.hash;
    }
    expect(hashes.keys.toSet(), roomsPerArea.keys.toSet());
    expect(
      hashes.values.toSet().length,
      KlAreas.all.length,
      reason: 'two areas drew the same frame: $hashes',
    );
  });

  test('the split party draws four knights in the room', () async {
    final game = await loadedGame();
    addTearDown(game.dispose);
    turnIntoKnights(game);
    expect(game.session!.party.length, 4);
    final image = await renderFrame(game);
    final frame = await readFrame(image);
    await writeFrame(image, 'party_split');
    expect(frame.colours, greaterThan(15));
  });
}
