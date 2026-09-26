import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iso_core/iso_core.dart';
import 'package:iso_editor/iso_editor.dart';
import 'package:vector_math/vector_math.dart' show Vector3;

void main() {
  test('editor document round trips', () {
    final document = EditorDocument(
      projectName: 'demo',
      theme: 'castle',
      width: 8,
      height: 6,
      layers: [
        TileLayer(
          name: 'floor',
          cells: {const CellAddress(1, 2): 5, const CellAddress(3, 4): 7},
        ),
      ],
      objects: [
        ObjectPlacement(
          id: 'door_1',
          type: 'door',
          name: 'Main door',
          position: Vector3(4, 5, 0),
        ),
      ],
    );

    final decoded = EditorDocument.fromJson(document.toJson());
    expect(decoded.projectName, 'demo');
    expect(decoded.layers.single.cells[const CellAddress(3, 4)], 7);
    expect(decoded.objects.single.type, 'door');
  });

  test('editor controller applies edits and undoes them', () {
    final controller = EditorController(storage: MemoryEditorStorage());
    addTearDown(controller.dispose);

    controller.setTile(0, const CellAddress(2, 2), 12);
    expect(
      controller.document.layers.single.cells[const CellAddress(2, 2)],
      12,
    );
    expect(controller.dirty, isTrue);

    controller.undo();
    expect(
      controller.document.layers.single.cells.containsKey(
        const CellAddress(2, 2),
      ),
      isFalse,
    );

    controller.redo();
    expect(
      controller.document.layers.single.cells[const CellAddress(2, 2)],
      12,
    );
  });

  testWidgets('map editor view renders a dimetric grid', (tester) async {
    final document = EditorDocument(
      projectName: 'demo',
      theme: 'default',
      width: 4,
      height: 4,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MapEditorView(document: document, onCellSelected: (_) {}),
      ),
    );

    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('asset import stores png and upserts manifest', () async {
    final storage = MemoryEditorStorage();
    final service = AssetImportService(storage: storage);
    final bytes = await _pngBytes(4, 3);

    final info = await service.inspectPng(bytes);
    expect(info.width, 4);
    expect(info.height, 3);

    final entry = await service.commit(
      bytes: bytes,
      fileName: 'idle_s.png',
      request: const AssetImportRequest(
        category: 'character',
        subject: 'hero',
        animation: 'idle',
        direction: 's',
        anchorX: 2,
        anchorY: 2,
      ),
    );

    expect(entry.id, 'character.hero.idle.s');
    expect(entry.runtimeSize, {'width': 4, 'height': 3});
    expect(await storage.exists(service.storageKey(entry)), isTrue);

    final manifest = AssetManifest.fromYaml(
      await storage.readText('assets/sprites/manifest.yaml'),
    );
    expect(manifest.getAsset(entry.id)?.file, entry.file);
  });
}

Future<Uint8List> _pngBytes(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFFFF0000),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}
