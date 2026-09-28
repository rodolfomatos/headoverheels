import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:headoverheels/features/gameplay/room/world_loader.dart';

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
}
