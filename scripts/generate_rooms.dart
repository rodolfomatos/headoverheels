import 'dart:convert';
import 'dart:io';
import 'package:vector_math/vector_math.dart';

void main() {
  final worldJson = File('assets/levels/world.json').readAsStringSync();
  final world = json.decode(worldJson) as Map<String, dynamic>;
  final roomsJson = world['rooms'] as Map<String, dynamic>;

  for (final entry in roomsJson.entries) {
    final roomId = entry.key;
    final roomJson = entry.value as Map<String, dynamic>;
    final file = roomJson['file'] as String;
    final theme = roomJson['theme'] as String;
    final triggersJson = roomJson['triggers'] as List<dynamic>;

    final outputDir = 'assets/levels/rooms/${theme}';
    Directory(outputDir).createSync(recursive: true);

    final tmx = generateTMX(roomId, theme, triggersJson);
    File('$outputDir/${roomId}.tmx').writeAsStringSync(tmx);
    print('Generated $outputDir/${roomId}.tmx');
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
  final tileset = File('games/headoverheels/assets/levels/tilesets/$theme.tsx');
  if (!tileset.existsSync()) {
    // The castle tileset stands in for every planet until the other four are
    // drawn. See T058.
    stderr.writeln(
      'No tileset for the $theme of $roomId; using the castle one. T058.',
    );
  }
  sb.writeln(
    ' <tileset firstgid="1" '
    'source="assets/levels/tilesets/${tileset.existsSync() ? theme : 'castle'}.tsx"/>',
  );
  sb.writeln(' <layer id="1" name="Floor" width="16" height="16">');
  sb.writeln('  <data encoding="csv">');
  // Empty floor
  for (int y = 0; y < 16; y++) {
    sb.write('0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0');
    if (y < 15) sb.writeln(',');
  }
  sb.writeln();
  sb.writeln('  </data>');
  sb.writeln(' </layer>');
  sb.writeln(' <layer id="2" name="Walls" width="16" height="16">');
  sb.writeln('  <data encoding="csv">');
  // Border walls
  for (int y = 0; y < 16; y++) {
    if (y == 0 || y == 15) {
      sb.write('0,2,2,2,2,2,2,2,2,2,2,2,2,2,2,0');
    } else {
      sb.write('0,2,0,0,0,0,0,0,0,0,0,0,0,0,2,0');
    }
    if (y < 15) sb.writeln(',');
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
