import 'dart:convert';
import 'dart:io';
import 'package:vector_math/vector_math.dart';

/// The game this script writes the rooms of, found from the script's own place.
///
/// Every path in here used to be relative to the working directory, and the
/// script is run from inside the game: `dart run ../../scripts/generate_rooms.dart`.
/// So the tileset lookup asked for
/// `games/headoverheels/assets/levels/tilesets/castle.tsx` from inside
/// `games/headoverheels`, a path that has never existed, and every room fell
/// back to the castle one without saying so. Paths that depend on where a
/// command was typed from are how that happened.
final Directory gameRoot = Directory(
  '${File.fromUri(Platform.script).parent.parent.path}/games/headoverheels',
);

void main() {
  final worldJson = File('${gameRoot.path}/assets/levels/world.json')
      .readAsStringSync();
  final world = json.decode(worldJson) as Map<String, dynamic>;
  final roomsJson = world['rooms'] as Map<String, dynamic>;

  for (final entry in roomsJson.entries) {
    final roomId = entry.key;
    final roomJson = entry.value as Map<String, dynamic>;
    final file = roomJson['file'] as String;
    final theme = roomJson['theme'] as String;
    final triggersJson = roomJson['triggers'] as List<dynamic>;

    final outputDir = '${gameRoot.path}/assets/levels/rooms/${theme}';
    Directory(outputDir).createSync(recursive: true);

    final tmx = generateTMX(roomId, theme, triggersJson);
    File('$outputDir/${roomId}.tmx').writeAsStringSync(tmx);
    print('Generated ${roomId}.tmx');
  }
}

String generateTMX(String roomId, String theme, List<dynamic> triggers) {
  final sb = StringBuffer();
  sb.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  sb.writeln(
    '<map version="1.10" tiledversion="1.10.0" orientation="isometric" renderorder="right-down" width="16" height="16" tilewidth="64" tileheight="32" infinite="0" nextobjectid="100">',
  );
  // The path the runtime resolves. It has to start at the bundle root, and the
  // tileset has to exist: a map pointing at art nobody drew is a room that
  // cannot load.
  // Every planet has a tileset of its own now, published by
  // scripts/publish_planet_tilesets.py from the art in assets/sprites/tiles/.
  // This used to fall back to the castle one, so all five planets drew the same
  // stone and nothing said so.
  final tileset = File('${gameRoot.path}/assets/levels/tilesets/$theme.tsx');
  if (!tileset.existsSync()) {
    stderr.writeln(
      'The $theme of $roomId has no tileset. Run '
      'scripts/publish_planet_tilesets.py.',
    );
    exit(1);
  }
  sb.writeln(' <tileset firstgid="1" source="assets/levels/tilesets/$theme.tsx"/>');
  // The tileset, in ids rather than gids: 0-15 are floors and 16-31 are walls,
  // and a gid of 0 is no tile at all. The floors used to be all zeros, so every
  // room drew nothing but its border, and the border used gid 2, which is tile id
  // 1: a cracked *floor* tile, not a wall. See scripts/generate_castle_tileset.py
  // for what each id is.
  const plainFloor = 1;
  const wornFloor = 3;
  const mossyFloor = 4;
  const plainWall = 17;
  const topLeftWall = 18;
  const topRightWall = 19;

  sb.writeln(' <layer id="1" name="Floor" width="16" height="16">');
  sb.writeln('  <data encoding="csv">');
  for (int y = 0; y < 16; y++) {
    for (int x = 0; x < 16; x++) {
      // A worn path across the room and moss along its walls, so twenty rooms
      // are not twenty copies of one grid. The pattern is arithmetic, not random,
      // because the maps are committed and a rerun must not change them.
      final tile = (x + y) % 9 == 0
          ? wornFloor
          : (x < 2 || y < 2)
          ? mossyFloor
          : plainFloor;
      sb.write('$tile');
      if (x < 15 || y < 15) sb.write(',');
    }
    if (y < 15) sb.writeln();
  }
  sb.writeln();
  sb.writeln('  </data>');
  sb.writeln(' </layer>');
  sb.writeln(' <layer id="2" name="Walls" width="16" height="16">');
  sb.writeln('  <data encoding="csv">');
  for (int y = 0; y < 16; y++) {
    for (int x = 0; x < 16; x++) {
      final onBorder = x == 0 || y == 0 || x == 15 || y == 15;
      final tile = !onBorder
          ? 0
          : (y == 0 && x == 0)
          ? topLeftWall
          : (y == 0 && x == 15)
          ? topRightWall
          : plainWall;
      sb.write('$tile');
      if (x < 15 || y < 15) sb.write(',');
    }
    if (y < 15) sb.writeln();
  }
  sb.writeln();
  sb.writeln('  </data>');
  sb.writeln(' </layer>');

  sb.writeln(' <objectgroup id="3" name="Entities" width="16" height="16">');

  int objectId = 1;
  for (final trigger in triggers) {
    final type = trigger['type'] as String;
    final position = trigger['position'] as Map<String, dynamic>;
    final size = trigger['size'] as Map<String, dynamic>;
    final x = (position['x'] as num).toDouble() * 64;
    final y = (position['y'] as num).toDouble() * 32;
    final width = (size['width'] as num).toDouble() * 64;
    final height = (size['height'] as num).toDouble() * 32;

    sb.write(
      '  <object id="$objectId" name="${trigger['id']}" type="$type" x="$x" y="$y" width="$width" height="$height">',
    );
    sb.writeln();
    sb.writeln('   <properties>');
    for (final propEntry in trigger.entries) {
      if (propEntry.key != 'id' &&
          propEntry.key != 'type' &&
          propEntry.key != 'position' &&
          propEntry.key != 'size') {
        final value = propEntry.value;
        String typeStr = 'string';
        String valueStr = value.toString();
        if (value is bool) {
          typeStr = 'bool';
          valueStr = value.toString().toLowerCase();
        } else if (value is num) {
          typeStr = value is int ? 'int' : 'float';
        }
        sb.writeln(
          '    <property name="${propEntry.key}" type="$typeStr" value="$valueStr"/>',
        );
      }
    }
    if (trigger['exit'] != null) {
      final exit = trigger['exit'] as Map<String, dynamic>;
      for (final e in exit.entries) {
        String typeStr = 'string';
        String valueStr = e.value.toString();
        if (e.value is bool) {
          typeStr = 'bool';
          valueStr = e.value.toString().toLowerCase();
        } else if (e.value is num) {
          typeStr = e.value is int ? 'int' : 'float';
        }
        sb.writeln(
          '    <property name="exit.${e.key}" type="$typeStr" value="$valueStr"/>',
        );
      }
    }
    sb.writeln('   </properties>');
    sb.writeln('  </object>');
    objectId++;
  }

  sb.writeln(' </objectgroup>');
  sb.writeln(' <objectgroup id="4" name="Triggers" width="16" height="16">');

  // Add door triggers
  for (final trigger in triggers) {
    if (trigger['type'] == 'door' && trigger['exit'] != null) {
      final exit = trigger['exit'] as Map<String, dynamic>;
      final position = trigger['position'] as Map<String, dynamic>;
      final size = trigger['size'] as Map<String, dynamic>;
      final x = (position['x'] as num).toDouble() * 64;
      final y = (position['y'] as num).toDouble() * 32;
      final width = (size['width'] as num).toDouble() * 64;
      final height = (size['height'] as num).toDouble() * 32;

      sb.write(
        '  <object id="$objectId" name="${trigger['id']}_trigger" type="door" x="$x" y="$y" width="$width" height="$height">',
      );
      sb.writeln();
      sb.writeln('   <properties>');
      sb.writeln(
        '    <property name="targetRoom" type="string" value="${exit['room']}"/>',
      );
      sb.writeln(
        '    <property name="targetEntrance" type="string" value="${exit['entrance']}"/>',
      );
      sb.writeln('   </properties>');
      sb.writeln('  </object>');
      objectId++;
    }
  }

  sb.writeln(' </objectgroup>');
  sb.writeln('</map>');

  return sb.toString();
}
