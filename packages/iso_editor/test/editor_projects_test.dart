import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iso_core/iso_core.dart';
import 'package:iso_editor/iso_editor.dart';

/// Reads the repository, so the test proves the paths point at the files the
/// games actually write rather than at strings that look right.
class RepositoryStorage implements EditorStorage {
  RepositoryStorage([this.root = '../..']);

  final String root;

  File _file(String key) => File('$root/$key');

  @override
  Future<void> delete(String key) async => _file(key).delete();

  @override
  Future<bool> exists(String key) async => _file(key).existsSync();

  @override
  Future<Uint8List> readBinary(String key) async =>
      Uint8List.fromList(_file(key).readAsBytesSync());

  @override
  Future<String> readText(String key) async => _file(key).readAsStringSync();

  @override
  Future<void> writeBinary(String key, Uint8List value) async =>
      _file(key).writeAsBytesSync(value);

  @override
  Future<void> writeText(String key, String value) async =>
      _file(key).writeAsStringSync(value);
}

void main() {
  test('both projects point at files that exist', () async {
    final storage = RepositoryStorage();
    for (final project in EditorProject.shipped) {
      expect(
        await storage.exists(project.worldKey),
        isTrue,
        reason: '${project.id}: no world at ${project.worldKey}',
      );
      expect(
        await storage.exists(project.manifestKey),
        isTrue,
        reason: '${project.id}: no manifest at ${project.manifestKey}',
      );
    }
  });

  test('both projects are distinct and both are shipped', () {
    expect(EditorProject.shipped.map((p) => p.id).toSet().length, 2);
    expect(EditorProject.byId('knightlore').label, 'Knight Lore');
    expect(EditorProject.byId('headoverheels').label, 'Head over Heels');
    // An unknown name must not crash the picker.
    expect(EditorProject.byId('nope').id, EditorProject.shipped.first.id);
    expect(EditorProject.byId(null).id, EditorProject.shipped.first.id);
  });

  test('the Knight Lore world opens in the shared format', () async {
    final storage = RepositoryStorage();
    final graph = WorldGraph.fromJson(
      json.decode(await storage.readText(EditorProject.knightLore.worldKey))
          as Map<String, dynamic>,
    );
    expect(graph.rooms.length, 15);
    expect(
      graph.rooms.values.map((room) => room.theme).toSet().length,
      5,
      reason: 'Knight Lore has five areas',
    );
    // The same validation the editor offers on the panel.
    final validation = validateWorld(graph);
    expect(validation.errors, isEmpty);
  });

  test('both projects name their files the same way', () {
    // The point of T046 is that the editor is told nothing about a game except
    // where its files are. The sprite side of the two projects is therefore
    // exactly parallel: same sub-paths, only the game directory changes.
    const prefix = 'games/';
    expect(
      EditorProject.knightLore.manifestKey,
      EditorProject.headoverheels.manifestKey.replaceFirst(
        '$prefix'
            'headoverheels/',
        '$prefix'
            'knightlore/',
      ),
    );
    expect(
      EditorProject.knightLore.assetsBasePath,
      EditorProject.headoverheels.assetsBasePath.replaceFirst(
        '$prefix'
            'headoverheels/',
        '$prefix'
            'knightlore/',
      ),
    );
    // Every key sits inside its own game directory, so one project can never
    // read the other game's files by accident.
    for (final project in EditorProject.shipped) {
      for (final key in [
        project.worldKey,
        project.manifestKey,
        project.assetsBasePath,
        project.roomsBasePath,
        project.tilesetImageBasePath,
      ]) {
        expect(
          key,
          startsWith('$prefix${project.id}/'),
          reason: '${project.id} points outside its own directory: $key',
        );
      }
    }
  });

  test('the Knight Lore sprite manifest is the shared format', () async {
    final storage = RepositoryStorage();
    final manifest = AssetManifest.fromYaml(
      await storage.readText(EditorProject.knightLore.manifestKey),
    );
    expect(manifest.assets, isNotEmpty);
    // The manifest stores paths relative to the project's sprite directory, so
    // a sheet exists only if the directory and the file line up.
    for (final asset in manifest.assets) {
      expect(
        asset.file,
        isNot(contains('..')),
        reason: '${asset.id} escapes the sprite directory',
      );
    }
    // And the sheets the manifest names must exist, or the editor shows sprites
    // it cannot open.
    for (final asset in manifest.assets.take(8)) {
      expect(
        await storage.exists(
          '${EditorProject.knightLore.assetsBasePath}/${asset.file}',
        ),
        isTrue,
        reason: '${asset.id} points at a missing sheet',
      );
    }
  });

  testWidgets('the picker switches game and the graph panel follows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final storage = RepositoryStorage();
    await tester.pumpWidget(
      IsoEditorApp(storage: storage, project: EditorProject.knightLore),
    );
    await tester.pumpAndSettle();

    // The picker shows the game that is open.
    expect(find.byKey(const Key('project-picker')), findsOneWidget);
    expect(find.text('Knight Lore'), findsWidgets);

    // Open the graph tab and count what the Knight Lore world really holds.
    // The tab bar scrolls, so a tab past the panel's edge is off it rather than
    // missing: it has to be scrolled to before it can be tapped.
    await tester.ensureVisible(find.text('Graph').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Graph').first);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('world-graph-project:knightlore')),
      findsOneWidget,
    );

    // Switching to the other game must load its world, not keep this one.
    await tester.tap(find.byKey(const Key('project-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Head over Heels').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('world-graph-project:headoverheels')),
      findsOneWidget,
    );
    expect(find.text('Head over Heels'), findsWidgets);
  });
}
