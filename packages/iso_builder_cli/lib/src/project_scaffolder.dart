import 'dart:io';

import 'package:path/path.dart' as p;

class ProjectScaffolder {
  const ProjectScaffolder();

  void create({
    required String name,
    required String targetPath,
    bool force = false,
  }) {
    final root = Directory(targetPath);
    if (root.existsSync() && root.listSync().isNotEmpty && !force) {
      throw StateError('Target directory is not empty: $targetPath');
    }

    final files = <String, String>{
      'pubspec.yaml': _pubspec(name),
      'analysis_options.yaml': 'include: package:flutter_lints/flutter.yaml\n',
      'README.md': '# $name\n\nIsometric game project powered by `iso_core`.\n',
      'lib/main.dart': _main(name),
      'assets/sprites/manifest.yaml': _manifest,
      'assets/levels/world.json': _world,
      'style/palette.json': _palette,
      'style/geometry.json': _geometry,
    };

    for (final entry in files.entries) {
      final file = File(p.join(targetPath, entry.key));
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(entry.value);
    }
  }

  String _pubspec(String name) {
    return '''
name: ${_packageName(name)}
description: Isometric game project.
publish_to: none
version: 0.1.0

environment:
  sdk: ^3.11.4

dependencies:
  flutter:
    sdk: flutter
  iso_core:
    path: ../../packages/iso_core

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/sprites/
    - assets/levels/
    - style/palette.json
    - style/geometry.json
''';
  }

  String _main(String name) {
    return '''
import 'package:flutter/material.dart';

void main() => runApp(const ${_className(name)}App());

class ${_className(name)}App extends StatelessWidget {
  const ${_className(name)}App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$name',
      home: Scaffold(
        body: Center(child: Text('$name')),
      ),
    );
  }
}
''';
  }

  String _packageName(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9_]+'), '_')
        .replaceAll(RegExp('^_+|_+\$'), '');
    return normalized.isEmpty ? 'iso_game' : normalized;
  }

  String _className(String value) {
    final parts = value
        .trim()
        .split(RegExp('[^A-Za-z0-9]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join();
    return parts.isEmpty ? 'IsoGame' : parts;
  }

  static const _manifest = '''
version: "1.0"
assets: []
''';

  static const _world = '''
{
  "startRoom": "start",
  "rooms": {
    "start": {
      "file": "start.tmx",
      "theme": "default",
      "spawnPoint": {"x": 1, "y": 1, "z": 0},
      "exits": [],
      "triggers": []
    }
  },
  "planets": []
}
''';

  static const _palette = '''
{
  "base": {
    "black": "#000000",
    "white": "#FFFFFF"
  },
  "themes": {
    "default": {
      "floor": "#4A4A4A"
    }
  }
}
''';

  static const _geometry = '''
{
  "projection": {"type": "dimetric_2_1"},
  "tile_geometry": {"logical_width": 64, "logical_height": 32}
}
''';
}
