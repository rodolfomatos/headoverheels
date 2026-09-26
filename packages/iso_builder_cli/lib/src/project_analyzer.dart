import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class ProjectReport {
  const ProjectReport({required this.errors, required this.warnings});

  final List<String> errors;
  final List<String> warnings;

  bool get isValid => errors.isEmpty;
}

class ProjectAnalyzer {
  const ProjectAnalyzer();

  ProjectReport analyze(String projectPath) {
    final root = Directory(projectPath);
    final errors = <String>[];
    final warnings = <String>[];

    if (!root.existsSync()) {
      return ProjectReport(
        errors: ['Project directory does not exist: $projectPath'],
        warnings: const [],
      );
    }

    final pubspec = File(p.join(projectPath, 'pubspec.yaml'));
    if (!pubspec.existsSync()) {
      errors.add('Missing pubspec.yaml');
    }

    final manifest = File(
      p.join(projectPath, 'assets', 'sprites', 'manifest.yaml'),
    );
    if (!manifest.existsSync()) {
      errors.add('Missing assets/sprites/manifest.yaml');
    } else {
      _analyzeManifest(manifest, projectPath, errors, warnings);
    }

    final world = File(p.join(projectPath, 'assets', 'levels', 'world.json'));
    if (!world.existsSync()) {
      warnings.add('Missing assets/levels/world.json');
    }

    final palette = File(p.join(projectPath, 'style', 'palette.json'));
    if (!palette.existsSync()) {
      warnings.add('Missing style/palette.json');
    }

    return ProjectReport(errors: errors, warnings: warnings);
  }

  void _analyzeManifest(
    File file,
    String projectPath,
    List<String> errors,
    List<String> warnings,
  ) {
    final Object? document;
    try {
      document = loadYaml(file.readAsStringSync());
    } catch (error) {
      errors.add('Invalid asset manifest: $error');
      return;
    }
    if (document is! YamlMap) {
      errors.add('Asset manifest must be a YAML map');
      return;
    }
    final rawAssets = document['assets'];
    if (rawAssets is! YamlList) {
      errors.add('Asset manifest must contain an assets list');
      return;
    }

    final ids = <String>{};
    for (final raw in rawAssets) {
      if (raw is! YamlMap) {
        errors.add('Every asset entry must be a map');
        continue;
      }
      final id = raw['id']?.toString() ?? '';
      final file = raw['file']?.toString() ?? '';
      if (id.isEmpty) {
        errors.add('Asset with empty id');
        continue;
      }
      if (!ids.add(id)) {
        errors.add('Duplicate asset id: $id');
      }
      if (file.isEmpty) {
        errors.add('$id: empty file path');
        continue;
      }
      final assetFile = File(p.join(projectPath, 'assets', 'sprites', file));
      if (!assetFile.existsSync()) {
        warnings.add('$id: file not found at assets/sprites/$file');
      }
    }
  }
}
