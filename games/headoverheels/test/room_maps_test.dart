import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:headoverheels/features/gameplay/room/world_loader.dart';

/// A published tileset as raw pixels, decoded once and kept.
class Sheet {
  Sheet(this.rgba, this.width, this.height);

  final Uint8List rgba;
  final int width;
  final int height;

  /// How many of the 64x32 tile's pixels carry any paint at all.
  int paintedIn(int column, int row) {
    var painted = 0;
    for (var y = row * 32; y < row * 32 + 32; y++) {
      for (var x = column * 64; x < column * 64 + 64; x++) {
        if (rgba[(y * width + x) * 4 + 3] > 0) painted++;
      }
    }
    return painted;
  }
}

final Map<String, Sheet?> _sheets = {};

Future<Sheet?> _tilesetImage(String theme) async {
  if (_sheets.containsKey(theme)) return _sheets[theme];
  final file = File('assets/images/$theme.png');
  if (!file.existsSync()) {
    _sheets[theme] = null;
    return null;
  }
  final codec = await ui.instantiateImageCodec(file.readAsBytesSync());
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  return _sheets[theme] = Sheet(
    data.buffer.asUint8List(),
    image.width,
    image.height,
  );
}

/// Checks the room maps against the room maps the generator writes.
///
/// The maps had a floor of nothing at all: every tile was gid 0, which Tiled
/// reads as no tile, so twenty rooms drew nothing but their border. The border
/// used gid 2, which is tile id 1, and tile id 1 is a cracked *floor*: the rooms
/// were lined with floor. Nothing caught either, because nothing read the
/// numbers in the file.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Every layer of a map, with the gids it holds.
  Map<String, List<int>> layersOf(String tmx) {
    final layers = <String, List<int>>{};
    for (final layer in RegExp(
      r'<layer[^>]*name="([^"]+)"[^>]*>(.*?)</layer>',
      dotAll: true,
    ).allMatches(tmx)) {
      final body = layer.group(2)!;
      final data = RegExp(
        r'<data[^>]*>(.*?)</data>',
        dotAll: true,
      ).firstMatch(body)?.group(1);
      if (data == null) continue;
      layers[layer.group(1)!] = RegExp(
        r'\d+',
      ).allMatches(data).map((match) => int.parse(match.group(0)!)).toList();
    }
    return layers;
  }

  /// What the tileset can draw: a gid of 0 is no tile, and the rest count up
  /// from the tileset's first gid.
  ({int firstGid, int tileCount}) tilesetOf(String tmx) {
    // The map says which tileset it uses and from which gid; the tileset says
    // how many tiles it has. Neither file says both.
    final reference = RegExp(r'<tileset[^>]*>').firstMatch(tmx)!.group(0)!;
    final firstGid = int.parse(
      RegExp(r'firstgid="(\d+)"').firstMatch(reference)!.group(1)!,
    );
    final source = RegExp(r'source="([^"]+)"').firstMatch(reference)!.group(1)!;
    final tileCount = int.parse(
      RegExp(
        r'tilecount="(\d+)"',
      ).firstMatch(File(source).readAsStringSync())!.group(1)!,
    );
    return (firstGid: firstGid, tileCount: tileCount);
  }

  test('every tile a room uses is actually drawn in its planet', () async {
    // A tileset can exist, be the right size, be named by the map, and still
    // draw nothing: the castle was 0.1% opaque — 726 pixels out of 524,288 —
    // and the room it names is where a party starts. Every check so far asked
    // whether the file was there and whether the numbers were right, and never
    // whether there was any paint in it.
    //
    // So this asks the question per tile, with the room data: for every gid a
    // room puts on a layer, is there a pixel behind it?
    final world = await loadWorldGraph();
    final blank = <String>[];

    for (final room in world.rooms.values) {
      final tmx = File(room.tmxFile).readAsStringSync();
      final tileset = tilesetOf(tmx);
      final image = await _tilesetImage(room.theme);
      if (image == null) {
        blank.add('${room.id.value}: no published tileset for ${room.theme}');
        continue;
      }
      final used = <int>{};
      for (final gids in layersOf(tmx).values) {
        used.addAll(gids.where((gid) => gid > 0));
      }
      for (final gid in used) {
        final id = gid - tileset.firstGid + 1;
        final column = (id - 1) % 16;
        final row = (id - 1) ~/ 16;
        if (column < 0 || row < 0 || row * 32 + 32 > image.height) {
          blank.add('${room.id.value}: gid $gid is outside the sheet');
          continue;
        }
        final painted = image.paintedIn(column, row);
        if (painted == 0) {
          blank.add(
            '${room.id.value}: gid $gid (tile $id) is not drawn at all',
          );
        }
      }
    }

    expect(blank, isEmpty, reason: blank.join('\n'));
  });

  test('every room draws its own planet', () async {
    // Four of the five planets had no tileset, and the room generator fell back
    // to the castle one for every room without saying so, so all five planets
    // drew the same stone. The art was in assets/sprites/tiles/ the whole time.
    final world = await loadWorldGraph();
    for (final room in world.rooms.values) {
      final tmx = File(room.tmxFile).readAsStringSync();
      final source = RegExp(r'source="([^"]+)"').firstMatch(tmx)!.group(1)!;
      expect(
        source,
        endsWith('/${room.theme}.tsx'),
        reason: '${room.id} is a ${room.theme} room and draws something else',
      );
    }
  });

  test('every tileset a room names is one the game can load', () async {
    // A tileset that does not exist, or an image it does not name, is a room
    // that draws nothing: the floor tests above read the numbers, not the art.
    final world = await loadWorldGraph();
    final named = <String>{};
    for (final room in world.rooms.values) {
      named.add(
        RegExp(
          r'source="([^"]+)"',
        ).firstMatch(File(room.tmxFile).readAsStringSync())!.group(1)!,
      );
    }

    for (final path in named) {
      final tsx = File(path);
      expect(tsx.existsSync(), isTrue, reason: '$path is named and not there');
      final image = RegExp(
        r'<image[^>]*source="([^"]+)"',
      ).firstMatch(tsx.readAsStringSync())!.group(1)!;

      // How the image key is actually built, measured rather than guessed.
      //
      // Parsing a .tsx on its own leaves `Tileset.source` null, and flame_tiled
      // uses the declared source verbatim whenever that is the case. The key is
      // therefore the bare file name, and Flame's shared image cache puts its
      // own prefix in front of it — so the bundle path is
      // `assets/images/<source>`.
      //
      // An earlier version of this test worked out the key by joining the
      // tileset's directory to the source, which is what flame_tiled does when
      // the tileset *has* a source. That path has never existed, and the test
      // asserting it passed, because the test was describing the code as it was
      // read rather than as it runs.
      final key = 'assets/images/$image';
      expect(
        File(key).existsSync(),
        isTrue,
        reason:
            '${tsx.path} names $image, which the loader asks for as $key, '
            'and that file is not there: the room would draw no floor at all',
      );
    }
  });

  test('every room draws a floor', () async {
    final world = await loadWorldGraph();
    expect(world.rooms, isNotEmpty, reason: 'the world has no rooms');

    for (final room in world.rooms.values) {
      final file = File(room.tmxFile);
      expect(file.existsSync(), isTrue, reason: '${file.path} is missing');

      final layers = layersOf(file.readAsStringSync());
      final floor = layers['Floor'];
      expect(floor, isNotNull, reason: '${room.id} has no floor layer');
      expect(
        floor!.where((gid) => gid != 0).length,
        greaterThan(0),
        reason: '${room.id} has a floor of nothing: every tile is gid 0',
      );
    }
  });

  test('every room has a border and an open interior', () async {
    final world = await loadWorldGraph();
    for (final room in world.rooms.values) {
      final layers = layersOf(File(room.tmxFile).readAsStringSync());
      final walls = layers['Walls'] ?? const <int>[];
      final drawn = walls.where((gid) => gid != 0).length;

      expect(drawn, greaterThan(0), reason: '${room.id} has no wall at all');
      // 16 wide and 16 high, with the four corners counted once: 60.
      expect(drawn, lessThanOrEqualTo(60), reason: '${room.id} is walled in');
    }
  });

  test('every tile a room names is a tile the tileset has', () async {
    // A gid past the end of the tileset draws nothing, and says nothing either.
    final world = await loadWorldGraph();
    for (final room in world.rooms.values) {
      final tileset = tilesetOf(File(room.tmxFile).readAsStringSync());

      for (final layer in layersOf(
        File(room.tmxFile).readAsStringSync(),
      ).entries) {
        for (final gid in layer.value.where((gid) => gid != 0)) {
          final id = gid - tileset.firstGid;
          expect(
            id,
            inInclusiveRange(0, tileset.tileCount - 1),
            reason:
                '${room.id} ${layer.key} asks for tile $id, which the '
                'tileset does not have',
          );
        }
      }
    }
  });

  test('the walls are walls, and not floor tiles', () async {
    // The border used gid 2, and gid 2 is tile id 1: a cracked floor. The wall
    // ids start at 16.
    final world = await loadWorldGraph();
    for (final room in world.rooms.values) {
      final layers = layersOf(File(room.tmxFile).readAsStringSync());
      for (final gid in (layers['Walls'] ?? const <int>[]).where(
        (gid) => gid != 0,
      )) {
        expect(
          gid,
          greaterThanOrEqualTo(17),
          reason: '${room.id} lines its walls with a floor tile (gid $gid)',
        );
      }
    }
  });

  test('every trigger stands on the floor of its own room', () async {
    // Two of them did not. The castle's conveyor was at y of 160 in a
    // sixteen-by-sixteen room, ten rooms above its own floor, and the four
    // teleports sat at y of 15 with a height of 2, so their second row was
    // outside the room. Neither could ever be reached or seen, and the data
    // said nothing about it: the rooms themselves had no such test.
    //
    // The room's own size is read from its TMX, so a room that changes shape
    // changes what "inside" means.
    final world = await loadWorldGraph();
    for (final room in world.rooms.values) {
      final map = RegExp(
        r'<map\b[^>]*?\bwidth="(\d+)"[^>]*?\bheight="(\d+)"',
      ).firstMatch(File(room.tmxFile).readAsStringSync());
      expect(
        map,
        isNotNull,
        reason: '${room.id} has no <map> to read a size from',
      );
      final width = int.parse(map!.group(1)!);
      final height = int.parse(map.group(2)!);

      for (final trigger in room.triggers) {
        final label =
            '${room.id} ${trigger.id} (${trigger.type.name}) '
            'at ${trigger.position.x},${trigger.position.y} '
            'size ${trigger.size.x}x${trigger.size.y}';
        expect(trigger.position.x, greaterThanOrEqualTo(0), reason: label);
        expect(trigger.position.y, greaterThanOrEqualTo(0), reason: label);
        expect(
          trigger.position.x + trigger.size.x,
          lessThanOrEqualTo(width.toDouble()),
          reason: '$label, and the room is $width wide',
        );
        expect(
          trigger.position.y + trigger.size.y,
          lessThanOrEqualTo(height.toDouble()),
          reason: '$label, and the room is $height tall',
        );
      }
    }
  });

  test('two things that both draw never stand on the same tile', () async {
    // Three pairs did, and in each case the second one hid the first exactly:
    // a bag on the tile of a door, a key on the tile of a bag, a hush puppy in
    // the middle of a belt. The renderer is not at fault — it drew both, one
    // over the other — and a test that counts the room's pixels cannot tell
    // that from a bug, which is why the world is checked here instead.
    //
    // A belt spans the floor by design and is drawn under whatever stands on
    // it, and a ladder is part of the room rather than a thing with a sprite, so
    // neither counts. Everything else draws, and two of them on one tile means
    // one of them is invisible.
    const notDrawn = {'conveyor', 'ladderUp', 'ladderDown'};
    final world = await loadWorldGraph();
    for (final room in world.rooms.values) {
      final drawn = room.triggers
          .where((t) => !notDrawn.contains(t.type.name))
          .toList();
      for (final a in drawn) {
        for (final b in drawn) {
          if (identical(a, b)) continue;
          final overlaps =
              a.position.x < b.position.x + b.size.x &&
              b.position.x < a.position.x + a.size.x &&
              a.position.y < b.position.y + b.size.y &&
              b.position.y < a.position.y + a.size.y;
          expect(
            overlaps,
            isFalse,
            reason:
                '${room.id}: ${a.id} (${a.type.name}) and ${b.id} '
                '(${b.type.name}) are on the same tile, at '
                '${a.position.x},${a.position.y} and '
                '${b.position.x},${b.position.y}. One of them is invisible.',
          );
        }
      }
    }
  });
}
