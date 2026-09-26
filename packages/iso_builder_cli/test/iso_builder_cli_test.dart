import 'dart:io';

import 'package:iso_builder_cli/iso_builder_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory temp;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('iso_builder_test_');
  });

  tearDown(() {
    temp.deleteSync(recursive: true);
  });

  test('scaffolds and analyzes a project', () {
    const ProjectScaffolder().create(
      name: 'Demo Game',
      targetPath: p.join(temp.path, 'demo'),
    );

    final report = const ProjectAnalyzer().analyze(p.join(temp.path, 'demo'));
    expect(report.isValid, isTrue);
    expect(
      report.warnings.where((warning) => warning.contains('file not found')),
      isEmpty,
    );
  });

  test('reports duplicate asset ids', () {
    final project = Directory(p.join(temp.path, 'broken'))..createSync();
    File(
      p.join(project.path, 'pubspec.yaml'),
    ).writeAsStringSync('name: broken');
    final sprites = Directory(p.join(project.path, 'assets', 'sprites'))
      ..createSync(recursive: true);
    File(p.join(sprites.path, 'manifest.yaml')).writeAsStringSync('''
version: "1.0"
assets:
  - id: "entity.rock"
    file: "entities/rock.png"
    category: "entity"
  - id: "entity.rock"
    file: "entities/rock2.png"
    category: "entity"
''');

    final report = const ProjectAnalyzer().analyze(project.path);
    expect(report.isValid, isFalse);
    expect(report.errors, contains('Duplicate asset id: entity.rock'));
  });
}
