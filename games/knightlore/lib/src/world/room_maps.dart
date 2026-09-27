import 'dart:io';

import 'package:iso_core/iso_core.dart';
import 'package:knightlore/knightlore.dart';
import 'package:vector_math/vector_math.dart' show Vector3;
import 'package:xml/xml.dart';

/// The tiles a room map can use. Gid 1 is the floor, 2 the wall block and 3 the
/// wall top, so the wall ring reads as a solid surface from the dimetric view.
class KlTiles {
  static const int floor = 1;
  static const int wall = 2;
  static const int wallTop = 3;

  static const Map<int, String> surfaces = {
    floor: 'floor',
    wall: 'wall',
    wallTop: 'wall_top',
  };
}

class RoomMap {
  const RoomMap({
    required this.room,
    required this.width,
    required this.height,
    required this.tiles,
    required this.objects,
  });

  final RoomInfo room;
  final int width;
  final int height;

  /// Row-major tile ids; 0 means empty.
  final List<List<int>> tiles;

  /// Objects written to the Tiled object layer.
  final List<RoomMapObject> objects;

  int tileAt(int x, int y) =>
      (x < 0 || y < 0 || x >= width || y >= height) ? KlTiles.wall : tiles[y][x];

  bool isWalkable(int x, int y) =>
      x >= 0 && y >= 0 && x < width && y < height && tileAt(x, y) == KlTiles.floor;

  RoomTerrain get terrain => RoomTerrain(
        width,
        height,
        [for (final row in tiles) for (final tile in row) tile != KlTiles.floor],
      );

  Map<String, Vector3> get objectPositions => {
        for (final object in objects) object.name: object.position,
      };
}

class RoomMapObject {
  const RoomMapObject({
    required this.id,
    required this.type,
    required this.name,
    required this.position,
  });

  final int id;
  final String type;
  final String name;
  final Vector3 position;
}

/// Builds the Tiled maps for the world: one map per room, 8x8 tiles of 64x32,
/// with a wall ring, a doorway on every edge that has an exit, and the room's
/// triggers written as objects.
class RoomMapBuilder {
  const RoomMapBuilder({this.width = 8, this.height = 8});

  final int width;
  final int height;

  static const String roomsBasePath = 'assets/world/rooms';

  /// Deterministic interior blocks per room, so rooms are not all identical.
  static const Map<String, List<List<int>>> _blocks = {
    KlRooms.gatehouse: [
      [2, 2],
      [5, 5],
    ],
    KlRooms.greatHall: [
      [3, 2],
      [4, 5],
    ],
    KlRooms.corridor: [
      [2, 3],
      [5, 4],
    ],
    KlRooms.laboratory: [
      [2, 2],
      [5, 6],
    ],
    KlRooms.underground: [
      [3, 3],
    ],
    KlRooms.jungleEntrance: [
      [2, 5],
      [5, 2],
    ],
    KlRooms.jungleTrack: [
      [4, 3],
      [2, 2],
    ],
    KlRooms.jungleRuins: [
      [5, 5],
    ],
    KlRooms.cauldronEntrance: [
      [3, 2],
    ],
    KlRooms.cauldronCave: [
      [2, 2],
      [5, 5],
    ],
    KlRooms.mineEntrance: [
      [2, 3],
      [5, 4],
    ],
    KlRooms.mineShaft: [
      [3, 2],
      [4, 5],
    ],
    KlRooms.mineVault: [
      [2, 2],
    ],
    KlRooms.towerEntrance: [
      [3, 3],
    ],
    KlRooms.towerTop: [
      [2, 3],
      [5, 4],
    ],
  };

  RoomMap build(RoomInfo room) {
    final tiles = List.generate(
      height,
      (_) => List<int>.filled(width, KlTiles.floor),
      growable: false,
    );

    for (var x = 0; x < width; x++) {
      tiles[0][x] = KlTiles.wallTop;
      tiles[height - 1][x] = KlTiles.wall;
    }
    for (var y = 0; y < height; y++) {
      tiles[y][0] = KlTiles.wall;
      tiles[y][width - 1] = KlTiles.wall;
    }

    for (final block in _blocks[room.id] ?? const <List<int>>[]) {
      tiles[block[1]][block[0]] = KlTiles.wall;
    }

    for (final exit in room.exits) {
      _openDoor(tiles, exit.direction);
    }

    // A room must never trap the sabreman: the spawn tile is always floor.
    tiles[room.spawnPosition.y.round()][room.spawnPosition.x.round()] =
        KlTiles.floor;

    final objects = <RoomMapObject>[];
    var objectId = 1;
    for (final trigger in room.triggers) {
      objects.add(
        RoomMapObject(
          id: objectId++,
          type: trigger.type,
          name: trigger.id,
          position: trigger.position,
        ),
      );
    }

    return RoomMap(
      room: room,
      width: width,
      height: height,
      tiles: tiles,
      objects: objects,
    );
  }

  void _openDoor(List<List<int>> tiles, String direction) {
    switch (direction) {
      case 'north':
        tiles[0][width ~/ 2] = KlTiles.floor;
        tiles[1][width ~/ 2] = KlTiles.floor;
      case 'south':
        tiles[height - 1][width ~/ 2] = KlTiles.floor;
      case 'west':
        tiles[height ~/ 2][0] = KlTiles.floor;
        tiles[height ~/ 2][1] = KlTiles.floor;
      case 'east':
        tiles[height ~/ 2][width - 1] = KlTiles.floor;
    }
  }

  String toTmx(RoomMap map) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(
      'map',
      attributes: {
        'version': '1.10',
        'tiledversion': '1.10.2',
        'orientation': 'isometric',
        'renderorder': 'right-down',
        'width': '${map.width}',
        'height': '${map.height}',
        'tilewidth': '64',
        'tileheight': '32',
        'infinite': '0',
      },
      nest: () {
        builder.element('tileset', attributes: {
          'firstgid': '1',
          'name': map.room.theme,
          'tilewidth': '64',
          'tileheight': '32',
          'tilecount': '${KlTiles.surfaces.length}',
          'columns': '${KlTiles.surfaces.length}',
        }, nest: () {
          builder.element('image', attributes: {
            'source': '../../tiles/${map.room.theme}.png',
            'width': '${KlTiles.surfaces.length * 64}',
            'height': '32',
          });
          for (final entry in KlTiles.surfaces.entries) {
            builder.element('tile', attributes: {'id': '${entry.key - 1}'},
                nest: () {
              builder.element('properties', nest: () {
                builder.element('property', attributes: {
                  'name': 'surface',
                  'value': entry.value,
                });
              });
            });
          }
        });
        builder.element('layer', attributes: {
          'id': '1',
          'name': 'Floor',
          'width': '${map.width}',
          'height': '${map.height}',
        }, nest: () {
          builder.element('data', attributes: {'encoding': 'csv'}, nest: () {
            builder.text([
              for (var y = 0; y < map.height; y++)
                for (var x = 0; x < map.width; x++) '${map.tileAt(x, y)},',
            ].join('\n'));
          });
        });
        builder.element('objectgroup', attributes: {
          'id': '2',
          'name': 'Objects',
        }, nest: () {
          for (final object in map.objects) {
            builder.element('object', attributes: {
              'id': '${object.id}',
              'name': object.name,
              'type': object.type,
              'x': '${object.position.x * 64}',
              'y': '${(object.position.y + 1) * 32}',
              'width': '32',
              'height': '32',
            });
          }
        });
      },
    );
    return '${builder.buildDocument().toXmlString(pretty: true)}\n';
  }

  /// Writes every room map under [RoomMapBuilder.roomsBasePath].
  List<String> writeAll(WorldGraph world, {String? basePath}) {
    final written = <String>[];
    for (final room in world.rooms.values) {
      final file = File('${basePath ?? roomsBasePath}/${room.theme}/'
          '${room.id}.tmx');
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(toTmx(build(room)));
      written.add(file.path);
    }
    return written;
  }
}

/// Reads a Tiled map written by [RoomMapBuilder] back into a [RoomMap], so the
/// runtime and the tests can trust the committed files.
RoomMap parseRoomMap(String source, String roomId, RoomInfo room) {
  final document = XmlDocument.parse(source);
  final map = document.rootElement;
  final width = int.parse(map.getAttribute('width') ?? '0');
  final height = int.parse(map.getAttribute('height') ?? '0');

  var firstGid = 1;
  final tileset = map.findElements('tileset').firstOrNull;
  if (tileset != null) {
    firstGid = int.parse(tileset.getAttribute('firstgid') ?? '1');
  }

  final data = map.findElements('layer').first;
  final values = (data.getElement('data')?.innerText ?? '')
      .split(',')
      .map((value) => int.tryParse(value.trim()) ?? 0)
      .where((gid) => gid != 0)
      .toList();
  if (values.length != width * height) {
    throw FormatException(
      'room $roomId has ${values.length} tiles, expected ${width * height}',
    );
  }

  final tiles = <List<int>>[
    for (var y = 0; y < height; y++)
      [
        for (var x = 0; x < width; x++)
          values[y * width + x] - firstGid + 1,
      ],
  ];

  final objects = <RoomMapObject>[];
  final group = map.findElements('objectgroup').firstOrNull;
  if (group != null) {
    var objectId = 0;
    for (final object in group.findElements('object')) {
      objectId++;
      objects.add(
        RoomMapObject(
          id: int.tryParse(object.getAttribute('id') ?? '') ?? objectId,
          type: object.getAttribute('type') ?? '',
          name: object.getAttribute('name') ?? '',
          position: Vector3(
            double.parse(object.getAttribute('x') ?? '0') / 64,
            double.parse(object.getAttribute('y') ?? '0') / 32 - 1,
            0,
          ),
        ),
      );
    }
  }

  return RoomMap(
    room: room,
    width: width,
    height: height,
    tiles: tiles,
    objects: objects,
  );
}
