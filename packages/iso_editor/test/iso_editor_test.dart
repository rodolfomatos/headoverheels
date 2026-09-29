import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iso_core/iso_core.dart';
import 'package:iso_editor/iso_editor.dart';
import 'package:vector_math/vector_math.dart' show Vector3;

void main() {
  late Uint8List spritePng;
  late Uint8List png4x4;
  late Uint8List png8x8;
  late String seededManifest;
  late String seededFile;

  setUpAll(() async {
    spritePng = await _pngBytes(4, 4);
    png4x4 = spritePng;
    png8x8 = await _pngBytes(8, 8);
    final storage = MemoryEditorStorage();
    final service = AssetImportService(storage: storage);
    final entry = await service.commit(
      bytes: png4x4,
      fileName: 'idle_0.png',
      request: const AssetImportRequest(
        category: 'entity',
        subject: 'guard',
        animation: 'idle',
        direction: 'down',
      ),
    );
    seededManifest = await storage.readText('assets/sprites/manifest.yaml');
    seededFile = service.storageKey(entry);
  });

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

  test('TMX codec round trips layers, objects and properties', () {
    final document = EditorDocument(
      projectName: 'demo',
      theme: 'castle',
      width: 4,
      height: 4,
      layers: [
        TileLayer(
          name: 'Floor',
          cells: {const CellAddress(0, 0): 2, const CellAddress(3, 2): 5},
        ),
      ],
      objects: [
        ObjectPlacement(
          id: 'door_1',
          name: 'Door',
          type: 'door',
          position: Vector3(1, 2, 0),
          properties: const {'locked': true, 'target': 'room_2'},
        ),
      ],
      metadata: {
        'tmx.coordinate_mode': 'grid',
        'tmx.tilesets': [
          {
            'first_gid': 1,
            'source': '../tilesets/castle.tsx',
            'tile_count': 256,
            'name': 'castle',
          },
        ],
      },
    );

    final source = const TmxCodec().export(document);
    final decoded = const TmxCodec().import(
      source,
      coordinateMode: TmxCoordinateMode.grid,
    );

    expect(decoded.width, 4);
    expect(decoded.layers.single.cells[const CellAddress(3, 2)], 5);
    expect(decoded.objects.single.type, 'door');
    expect(decoded.objects.single.position, Vector3(1, 2, 0));
    expect(decoded.objects.single.properties['locked'], isTrue);
    expect(decoded.objects.single.properties['target'], 'room_2');
  });

  test('TMX codec rejects unsupported layer encodings', () {
    const source = '''
<map orientation="isometric" width="2" height="2" tilewidth="64" tileheight="32">
 <layer name="Floor"><data encoding="base64">AAAA</data></layer>
</map>
''';
    expect(
      () => const TmxCodec().import(source),
      throwsA(isA<FormatException>()),
    );
  });

  test('controller saves and loads an editor document', () async {
    final storage = MemoryEditorStorage();
    final controller = EditorController(
      storage: storage,
      document: EditorDocument(
        projectName: 'Saved Project',
        theme: 'default',
        width: 2,
        height: 2,
      ),
    );
    addTearDown(controller.dispose);
    await controller.save();

    final loaded = EditorController(storage: storage);
    addTearDown(loaded.dispose);
    await loaded.load(key: controller.documentKey);

    expect(loaded.document.projectName, 'Saved Project');
    expect(loaded.dirty, isFalse);
  });

  testWidgets('editor shell exposes tools and saves', (tester) async {
    final storage = MemoryEditorStorage();
    final controller = EditorController(storage: storage);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: EditorShell(controller: controller)),
    );

    await tester.tap(find.byKey(const Key('tool-tile')));
    await tester.pump();
    expect(controller.tool, EditorTool.tile);
    expect(find.byKey(const Key('save-button')), findsOneWidget);
  });

  testWidgets('the inspector panel takes a width and gives some back', (
    tester,
  ) async {
    // The panel was a fixed 320 pixels, which is why its controls were out of
    // reach and why a fifth tab could not fit: the width was not the window's to
    // give. The board records two attempts at T052 that were reverted for a
    // RenderFlex overflow of 98822 pixels, and this is the test that says the
    // panel can be dragged without the shell breaking.
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final storage = MemoryEditorStorage();
    final controller = EditorController(storage: storage);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: EditorShell(controller: controller)),
    );
    await tester.pumpAndSettle();

    final panel = find.byKey(const Key('inspector-panel'));
    expect(panel, findsOneWidget);

    final before = tester.getSize(panel).width;
    await tester.drag(
      find.byKey(const Key('inspector-resize-handle')),
      const Offset(-80, 0),
    );
    await tester.pumpAndSettle();
    final after = tester.getSize(panel).width;

    expect(
      after,
      greaterThan(before),
      reason: 'dragging the handle wider did nothing',
    );
    expect(
      tester.takeException(),
      isNull,
      reason: 'resizing the panel broke the shell',
    );
  });

  testWidgets('a narrow panel scrolls its tabs instead of overflowing', (
    tester,
  ) async {
    // What T052 kept hitting: a fifth tab in a narrow column, where the tab bar
    // could not fit the labels and overflowed by the width of the one that did
    // not fit. The bar scrolls now, and the shell says so.
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final storage = MemoryEditorStorage();
    final controller = EditorController(storage: storage);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: EditorShell(controller: controller)),
    );
    await tester.pumpAndSettle();

    final bar = tester.widget<TabBar>(find.byType(TabBar).last);
    expect(
      bar.isScrollable,
      isTrue,
      reason: 'a tab bar of words in a narrow panel has to scroll',
    );
    expect(
      tester.takeException(),
      isNull,
      reason: 'the panel overflowed on a narrow window',
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

  test('asset import service reloads the manifest from storage', () async {
    final storage = MemoryEditorStorage();
    final service = AssetImportService(storage: storage);
    await service.commit(
      bytes: await _pngBytes(2, 2),
      fileName: 'idle_s.png',
      request: const AssetImportRequest(
        category: 'character',
        subject: 'hero',
        animation: 'idle',
        direction: 's',
      ),
    );

    final manifest = await service.loadManifest();
    expect(manifest.getAsset('character.hero.idle.s'), isNotNull);
  });

  test('TSX parser reads tileset geometry, image and tile metadata', () {
    const source = '''
<tileset version="1.10" name="castle" tilewidth="64" tileheight="32" tilecount="4" columns="2">
 <image source="castle.png" width="128" height="64"/>
 <tile id="1" type="door">
  <properties>
   <property name="locked" type="bool" value="true"/>
   <property name="hits" type="int" value="3"/>
  </properties>
 </tile>
 <tile id="2" class="hazard"/>
</tileset>
''';

    final tileset = TsxTilesetDefinition.parse(source);
    expect(tileset.name, 'castle');
    expect(tileset.tileWidth, 64);
    expect(tileset.tileHeight, 32);
    expect(tileset.tileCount, 4);
    expect(tileset.columns, 2);
    expect(tileset.rows, 2);
    expect(tileset.imageSource, 'castle.png');
    expect(tileset.tileById(1)?.type, 'door');
    expect(tileset.tileById(1)?.properties['locked'], isTrue);
    expect(tileset.tileById(1)?.properties['hits'], 3);
    expect(tileset.tileById(2)?.className, 'hazard');

    final first = tileset.alignmentForTile(0);
    final third = tileset.alignmentForTile(2);
    expect(first.x, lessThan(0));
    expect(third.y, greaterThan(0));
  });

  test('TSX catalog indexes tilesets by name', () {
    const source = '''
<tileset name="dungeon" tilewidth="32" tileheight="16" tilecount="2" columns="2">
 <image source="dungeon.png" width="64" height="16"/>
</tileset>
''';
    final catalog = TsxCatalog([TsxTilesetDefinition.parse(source)]);
    expect(catalog.byName('dungeon')?.imageSource, 'dungeon.png');
    expect(catalog.byName('missing'), isNull);
    expect(catalog.tileCount, 2);
  });

  test('file gateway returns picked content and records saved text', () async {
    final gateway = MemoryEditorFileGateway(
      textFile: EditorPickedFile(
        name: 'room.tmx',
        bytes: Uint8List.fromList('<map/>'.codeUnits),
      ),
    );

    final picked = await gateway.pickText(label: 'Tiled map');
    expect(picked?.name, 'room.tmx');
    expect(picked?.extension, 'tmx');

    final path = await gateway.saveText(
      suggestedName: 'demo.tmx',
      contents: '<map/>',
      label: 'Tiled map',
    );
    expect(path, 'demo.tmx');
    expect(gateway.savedText['demo.tmx'], '<map/>');
  });

  testWidgets('TSX browser lists tiles and reports selection', (tester) async {
    const source = '''
<tileset name="castle" tilewidth="64" tileheight="32" tilecount="2" columns="2">
 <image source="castle.png" width="128" height="32"/>
 <tile id="1" type="door"/>
</tileset>
''';
    int? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: TsxBrowser(
              catalog: TsxCatalog([TsxTilesetDefinition.parse(source)]),
              onTileSelected: (tile) => selected = tile.id,
            ),
          ),
        ),
      ),
    );

    expect(find.text('castle: 2 tiles, 64x32'), findsOneWidget);
    await tester.tap(find.text('1'));
    await tester.pump();
    expect(selected, 1);
  });

  testWidgets('shell loads a TSX tileset through the file gateway', (
    tester,
  ) async {
    const source = '''
<tileset name="loaded" tilewidth="64" tileheight="32" tilecount="2" columns="2">
 <image source="loaded.png" width="128" height="32"/>
 <tile id="1" type="door"/>
</tileset>
''';
    final gateway = MemoryEditorFileGateway(
      textFile: EditorPickedFile(
        name: 'loaded.tsx',
        bytes: Uint8List.fromList(source.codeUnits),
      ),
    );
    final controller = EditorController(storage: MemoryEditorStorage());
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: EditorShell(controller: controller, fileGateway: gateway),
      ),
    );

    // The tab bar scrolls, so a tab past the panel's edge is off it rather

    // than missing: it has to be scrolled to before it can be tapped.

    await tester.ensureVisible(find.text('Palette'));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Palette'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('load-tsx-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tsx-browser')), findsOneWidget);
    expect(find.text('loaded: 2 tiles, 64x32'), findsOneWidget);
  });

  testWidgets('shell renders tileset images on the map canvas', (tester) async {
    const source = '''
<tileset name="preview" tilewidth="64" tileheight="32" tilecount="2" columns="2">
 <image source="preview.png" width="128" height="32"/>
</tileset>
''';
    final controller = EditorController(
      storage: MemoryEditorStorage(),
      document: EditorDocument(
        projectName: 'demo',
        theme: 'default',
        width: 2,
        height: 2,
        layers: [TileLayer(name: 'floor', cells: const {})],
      ),
    );
    addTearDown(controller.dispose);
    controller.setTool(EditorTool.tile);
    controller.applyCell(const CellAddress(1, 1), tileId: 1);

    await tester.pumpWidget(
      MaterialApp(
        home: MapEditorView(
          document: controller.document,
          selectedTileId: 1,
          tileset: TsxTilesetDefinition.parse(source),
          resolveImagePath: (source) => 'assets/tilesets/$source',
          onCellSelected: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shell imports a sprite through the file gateway', (
    tester,
  ) async {
    final storage = MemoryEditorStorage();
    final controller = EditorController(storage: storage);
    addTearDown(controller.dispose);
    final gateway = MemoryEditorFileGateway(
      binaryFile: EditorPickedFile(name: 'idle_s.png', bytes: spritePng),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EditorShell(
          controller: controller,
          fileGateway: gateway,
          assetsBasePath: 'assets/sprites',
        ),
      ),
    );

    // The tab bar scrolls, so a tab past the panel's edge is off it rather

    // than missing: it has to be scrolled to before it can be tapped.

    await tester.ensureVisible(find.text('Sprites'));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Sprites'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('import-sprite-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('sprite-subject-field')),
      'guard',
    );
    await tester.tap(find.byKey(const Key('confirm-sprite-import')));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();

    final manifest = AssetManifest.fromYaml(
      await storage.readText('assets/sprites/manifest.yaml'),
    );
    expect(manifest.getAsset('entity.guard.idle.down'), isNotNull);
    expect(find.text('1 assets'), findsOneWidget);
  });

  test('manifest service updates and removes entries', () async {
    final storage = MemoryEditorStorage();
    final service = AssetManifestService(storage: storage);
    final manifest = AssetManifest(
      version: '1.0',
      assets: const [
        AssetEntry(
          id: 'entity.guard.idle.down',
          file: 'entity/guard/idle_0.png',
          category: 'entity',
          runtimeSize: {'width': 4, 'height': 4},
          anchor: {'x': 2, 'y': 3},
          alpha: 'opaque',
          palette: 'base',
          scale: 1,
        ),
      ],
    );
    await service.save(manifest);

    final updated = await service.update(
      await service.load(),
      'entity.guard.idle.down',
      (entry) => entry.copyWith(anchor: const {'x': 1, 'y': 1}),
    );
    expect(updated.getAsset('entity.guard.idle.down')?.anchorX, 1);

    final removed = await service.remove(updated, 'entity.guard.idle.down');
    expect(removed.getAsset('entity.guard.idle.down'), isNull);
    expect((await service.load()).assets, isEmpty);
  });

  test('manifest service returns an empty manifest when none exists', () async {
    final service = AssetManifestService(storage: MemoryEditorStorage());
    final manifest = await service.load();
    expect(manifest.assets, isEmpty);
    expect(manifest.version, '1.0');
  });

  test('frame import writes every frame and declares the count', () async {
    final storage = MemoryEditorStorage();
    final service = AssetImportService(storage: storage);

    final entry = await service.commitFrames(
      frames: [
        (name: 'walk_0.png', bytes: await _pngBytes(4, 4)),
        (name: 'walk_1.png', bytes: await _pngBytes(4, 4)),
      ],
      request: const AssetImportRequest(
        category: 'entity',
        subject: 'guard',
        animation: 'walk',
        direction: 'down',
        frameDurationMs: 80,
      ),
    );

    expect(entry.frames, 2);
    expect(entry.frameDuration, 80);
    expect(AssetManifestService.frameFilesOf(entry), [
      'entity/guard/walk_0.png',
      'entity/guard/walk_1.png',
    ]);
    expect(
      await storage.exists('assets/sprites/entity/guard/walk_1.png'),
      isTrue,
    );
  });

  test('frame import rejects mismatched frame dimensions', () async {
    final service = AssetImportService(storage: MemoryEditorStorage());
    expect(
      () => service.commitFrames(
        frames: [
          (name: 'a.png', bytes: png4x4),
          (name: 'b.png', bytes: png8x8),
        ],
        request: const AssetImportRequest(
          category: 'entity',
          subject: 'guard',
          animation: 'walk',
        ),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('appending frames extends an existing animation', () async {
    final storage = MemoryEditorStorage();
    final service = AssetImportService(storage: storage);
    final entry = await service.commit(
      bytes: png4x4,
      fileName: 'idle_0.png',
      request: const AssetImportRequest(
        category: 'entity',
        subject: 'guard',
        animation: 'idle',
        direction: 'down',
      ),
    );

    final updated = await service.appendFrames(
      entry: entry,
      frames: [(name: 'idle_1.png', bytes: png4x4)],
    );

    expect(updated.file, 'entity/guard/idle_0.png');
    expect(updated.frames, 2);
    expect(AssetManifestService.frameFilesOf(updated), [
      'entity/guard/idle_0.png',
      'entity/guard/idle_1.png',
    ]);

    final reloaded = AssetManifest.fromYaml(
      await storage.readText('assets/sprites/manifest.yaml'),
    );
    expect(
      AssetManifestService.frameFilesOf(
        reloaded.getAsset('entity.guard.idle.down')!,
      ),
      hasLength(2),
    );
  });

  test('appending frames rejects a different frame size', () async {
    final service = AssetImportService(storage: MemoryEditorStorage());
    final entry = await service.commit(
      bytes: png4x4,
      fileName: 'idle_0.png',
      request: const AssetImportRequest(
        category: 'entity',
        subject: 'guard',
        animation: 'idle',
      ),
    );
    expect(
      () => service.appendFrames(
        entry: entry,
        frames: [(name: 'idle_1.png', bytes: png8x8)],
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('copyWith keeps semantic fields while overriding frame data', () {
    const entry = AssetEntry(
      id: 'character.hero.idle.s',
      file: 'character/hero/idle_s.png',
      category: 'character',
      character: 'hero',
      animation: 'idle',
      direction: 's',
      frames: 1,
      frameDuration: 100,
      loop: false,
      runtimeSize: {'width': 8, 'height': 8},
      anchor: {'x': 4, 'y': 7},
      alpha: 'opaque',
      palette: 'base',
      scale: 1,
    );

    final updated = entry.copyWith(frames: 4, frameDuration: 50, loop: true);
    expect(updated.frames, 4);
    expect(updated.frameDuration, 50);
    expect(updated.loop, isTrue);
    expect(updated.character, 'hero');
    expect(updated.direction, 's');
  });

  testWidgets('sprite animator steps frames and flags count mismatch', (
    tester,
  ) async {
    final entry = AssetEntry(
      id: 'entity.guard.idle.down',
      file: 'entity/guard/idle_0.png',
      category: 'entity',
      entity: 'guard',
      animation: 'idle',
      direction: 'down',
      frames: 3,
      frameDuration: 100,
      loop: true,
      runtimeSize: const {'width': 4, 'height': 4},
      anchor: const {'x': 2, 'y': 3},
      alpha: 'opaque',
      palette: 'base',
      scale: 1,
      metadata: const {
        'frame_files': ['entity/guard/idle_0.png', 'entity/guard/idle_1.png'],
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpriteAnimator(entry: entry, assetsBasePath: 'assets/sprites'),
        ),
      ),
    );

    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('Declared 3 frames but 2 available'), findsOneWidget);

    await tester.tap(find.byKey(const Key('animator-next')));
    await tester.pump();
    expect(find.text('2/2'), findsOneWidget);
  });

  testWidgets('sprite manager edits an entry and reports changes', (
    tester,
  ) async {
    AssetEntry? saved;
    final manifest = AssetManifest(
      version: '1.0',
      assets: const [
        AssetEntry(
          id: 'entity.guard.idle.down',
          file: 'entity/guard/idle_0.png',
          category: 'entity',
          entity: 'guard',
          animation: 'idle',
          direction: 'down',
          frames: 1,
          runtimeSize: {'width': 4, 'height': 4},
          anchor: {'x': 2, 'y': 3},
          alpha: 'opaque',
          palette: 'base',
          scale: 1,
        ),
        AssetEntry(
          id: 'prop.door.idle.down',
          file: 'prop/door/idle_0.png',
          category: 'prop',
          entity: 'door',
          runtimeSize: {'width': 8, 'height': 8},
          anchor: {'x': 4, 'y': 7},
          alpha: 'opaque',
          palette: 'base',
          scale: 1,
        ),
      ],
    );

    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpriteManager(
            manifest: manifest,
            assetsBasePath: 'assets/sprites',
            onImport: () async {},
            onSave: (entry) async => saved = entry,
            onDelete: (_) async {},
            onAddFrames: (_) async {},
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const Key('asset-tile-entity.guard.idle.down')),
    );
    await tester.pumpAndSettle();
    expect(find.text('entity/guard/idle_0.png'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('asset-field-anchor x')), '1');
    await tester.tap(find.byKey(const Key('asset-save-button')));
    await tester.pumpAndSettle();

    expect(saved?.id, 'entity.guard.idle.down');
    expect(saved?.anchorX, 1);
  });

  testWidgets('sprite manager filters by category', (tester) async {
    final manifest = AssetManifest(
      version: '1.0',
      assets: const [
        AssetEntry(
          id: 'entity.guard.idle.down',
          file: 'entity/guard/idle_0.png',
          category: 'entity',
          runtimeSize: {'width': 4, 'height': 4},
          anchor: {'x': 2, 'y': 3},
          alpha: 'opaque',
          palette: 'base',
          scale: 1,
        ),
        AssetEntry(
          id: 'prop.door.idle.down',
          file: 'prop/door/idle_0.png',
          category: 'prop',
          runtimeSize: {'width': 8, 'height': 8},
          anchor: {'x': 4, 'y': 7},
          alpha: 'opaque',
          palette: 'base',
          scale: 1,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpriteManager(
            manifest: manifest,
            assetsBasePath: 'assets/sprites',
            onImport: () async {},
            onSave: (_) async {},
            onDelete: (_) async {},
            onAddFrames: (_) async {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('asset-tile-entity.guard.idle.down')),
      findsOne,
    );
    expect(find.byKey(const Key('asset-tile-prop.door.idle.down')), findsOne);

    await tester.tap(find.byKey(const Key('sprite-category-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('prop').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('asset-tile-prop.door.idle.down')), findsOne);
    expect(
      find.byKey(const Key('asset-tile-entity.guard.idle.down')),
      findsNothing,
    );
  });

  testWidgets('shell appends frames to an imported sprite', (tester) async {
    tester.view.physicalSize = const Size(1400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final storage = await _seededStorage(seededManifest, seededFile, png4x4);
    final gateway = MemoryEditorFileGateway(
      binaryFiles: [EditorPickedFile(name: 'idle_1.png', bytes: png4x4)],
    );
    final controller = EditorController(storage: storage);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: EditorShell(
          controller: controller,
          fileGateway: gateway,
          manifest: AssetManifest.fromYaml(
            await storage.readText('assets/sprites/manifest.yaml'),
          ),
        ),
      ),
    );

    // The tab bar scrolls, so a tab past the panel's edge is off it rather

    // than missing: it has to be scrolled to before it can be tapped.

    await tester.ensureVisible(find.text('Sprites'));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Sprites'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('asset-tile-entity.guard.idle.down')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('asset-frames-button')));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pumpAndSettle();

    final manifest = AssetManifest.fromYaml(
      await storage.readText('assets/sprites/manifest.yaml'),
    );
    expect(
      AssetManifestService.frameFilesOf(
        manifest.getAsset('entity.guard.idle.down')!,
      ),
      hasLength(2),
    );
  });

  test('world graph layout places rooms in theme columns', () {
    final graph = WorldGraph.fromJson({
      'startRoom': 'a',
      'rooms': {
        'a': {'file': 'a.tmx', 'theme': 'castle'},
        'b': {'file': 'b.tmx', 'theme': 'castle'},
        'c': {'file': 'c.tmx', 'theme': 'moonbase'},
      },
    });

    final layout = layoutWorldGraph(graph);
    expect(layout.positions.keys, hasLength(3));
    expect(layout.positionOf('a')!.dx, layout.positionOf('b')!.dx);
    expect(layout.positionOf('c')!.dx, greaterThan(layout.positionOf('a')!.dx));
    expect(layout.positionOf('a')!.dy, lessThan(layout.positionOf('b')!.dy));
  });

  testWidgets('graph panel lists rooms, edits exits and validates', (
    tester,
  ) async {
    final storage = MemoryEditorStorage();
    await storage.writeText(
      'assets/levels/world.json',
      jsonEncode({
        'startRoom': 'a',
        'rooms': {
          'a': {
            'file': 'a.tmx',
            'theme': 'castle',
            'exits': [
              {'direction': 'east', 'room': 'ghost', 'entrance': 'west'},
            ],
          },
          'b': {'file': 'b.tmx', 'theme': 'castle'},
        },
      }),
    );

    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: WorldGraphPanel(
          source: () => storage.readText('assets/levels/world.json'),
          onSave: (json) => storage.writeText('assets/levels/world.json', json),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('world-graph-view')), findsOneWidget);
    expect(find.text('2 rooms · 1 exits'), findsOneWidget);
    expect(find.text('1 error(s) · 1 warning(s)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('world-issue-unknownTarget')));
    await tester.pumpAndSettle();
    expect(find.text('a.tmx · castle'), findsOneWidget);
    expect(find.byKey(const Key('exit-target')), findsOneWidget);

    await tester.tap(find.byKey(const Key('exit-target')).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('b').last);
    await tester.pumpAndSettle();

    expect(find.text('0 error(s) · 1 warning(s)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('world-save-button')));
    await tester.pumpAndSettle();

    final saved = WorldGraph.fromJson(
      jsonDecode(await storage.readText('assets/levels/world.json'))
          as Map<String, dynamic>,
    );
    expect(saved.getRoom('a')!.exits.single.room, 'b');
  });

  testWidgets('graph panel removes and adds exits', (tester) async {
    final storage = MemoryEditorStorage();
    await storage.writeText(
      'assets/levels/world.json',
      jsonEncode({
        'startRoom': 'a',
        'rooms': {
          'a': {
            'file': 'a.tmx',
            'theme': 'castle',
            'exits': [
              {'direction': 'east', 'room': 'b', 'entrance': 'west'},
            ],
          },
          'b': {'file': 'b.tmx', 'theme': 'castle'},
        },
      }),
    );

    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: WorldGraphPanel(
          source: () => storage.readText('assets/levels/world.json'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(105, 53));
    await tester.pumpAndSettle();
    expect(find.text('a.tmx · castle'), findsOneWidget);
    await tester.tap(find.byKey(const Key('exit-remove')));
    await tester.pumpAndSettle();
    expect(find.textContaining('0 exits'), findsOneWidget);

    await tester.tap(find.byKey(const Key('world-add-exit-button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 exits'), findsOneWidget);
  });

  testWidgets('graph panel shows and edits puzzle triggers', (tester) async {
    final storage = MemoryEditorStorage();
    await storage.writeText(
      'assets/levels/world.json',
      jsonEncode({
        'startRoom': 'a',
        'rooms': {
          'a': {
            'file': 'a.tmx',
            'theme': 'castle',
            'triggers': [
              {
                'id': 'switch_1',
                'type': 'switch',
                'position': {'x': 3, 'y': 3, 'z': 0},
                'size': {'width': 1, 'height': 1},
                'properties': {'targetId': 'door_secret_1'},
              },
            ],
          },
          'b': {'file': 'b.tmx', 'theme': 'castle'},
        },
      }),
    );

    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: WorldGraphPanel(
          source: () => storage.readText('assets/levels/world.json'),
          onSave: (json) => storage.writeText('assets/levels/world.json', json),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(105, 53));
    await tester.pumpAndSettle();
    expect(find.text('Triggers (1)'), findsOneWidget);
    expect(find.text('switch · switch_1'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('trigger-target-switch_1')))
          .controller
          ?.text,
      'door_secret_1',
    );

    await tester.enterText(
      find.byKey(const Key('trigger-target-switch_1')),
      'door_open_1',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('world-save-button')));
    await tester.pumpAndSettle();

    final saved = WorldGraph.fromJson(
      jsonDecode(await storage.readText('assets/levels/world.json'))
          as Map<String, dynamic>,
    );
    final trigger = saved.getRoom('a')!.triggers.single;
    expect(trigger.id, 'switch_1');
    expect(
      (trigger.properties['properties'] as Map)['targetId'],
      'door_open_1',
    );
  });

  testWidgets('graph panel removes a trigger', (tester) async {
    final storage = MemoryEditorStorage();
    await storage.writeText(
      'assets/levels/world.json',
      jsonEncode({
        'startRoom': 'a',
        'rooms': {
          'a': {
            'file': 'a.tmx',
            'theme': 'castle',
            'triggers': [
              {
                'id': 'crown_1',
                'type': 'crown',
                'position': {'x': 1, 'y': 1, 'z': 0},
                'size': {'width': 1, 'height': 1},
              },
            ],
          },
        },
      }),
    );

    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: WorldGraphPanel(
          source: () => storage.readText('assets/levels/world.json'),
          onSave: (json) => storage.writeText('assets/levels/world.json', json),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(105, 53));
    await tester.pumpAndSettle();
    expect(find.text('Triggers (1)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('trigger-remove-crown_1')));
    await tester.pumpAndSettle();
    expect(find.text('Triggers (0)'), findsOneWidget);
  });

  testWidgets('graph panel reports an unreadable world file', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WorldGraphPanel(source: () => throw StateError('no world.json')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('World could not be read'), findsOneWidget);
    expect(find.byKey(const Key('world-reload-button')), findsOneWidget);
  });

  testWidgets('editor shell shows the world graph tab', (tester) async {
    final storage = MemoryEditorStorage();
    await storage.writeText(
      'assets/levels/world.json',
      jsonEncode({
        'startRoom': 'a',
        'rooms': {
          'a': {
            'file': 'a.tmx',
            'theme': 'castle',
            'exits': [
              {'direction': 'east', 'room': 'b', 'entrance': 'west'},
            ],
          },
          'b': {
            'file': 'b.tmx',
            'theme': 'castle',
            'exits': [
              {'direction': 'west', 'room': 'a', 'entrance': 'east'},
            ],
          },
        },
      }),
    );
    final controller = EditorController(storage: storage);
    addTearDown(controller.dispose);

    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: EditorShell(controller: controller)),
    );

    // The tab bar scrolls, so a tab past the panel's edge is off it rather

    // than missing: it has to be scrolled to before it can be tapped.

    await tester.ensureVisible(find.text('Graph'));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Graph'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('world-graph-panel')), findsOneWidget);
    expect(find.text('2 rooms · 2 exits'), findsOneWidget);
    expect(find.text('0 error(s) · 0 warning(s)'), findsOneWidget);
  });

  testWidgets('shell deletes an asset after confirmation', (tester) async {
    tester.view.physicalSize = const Size(1400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final storage = await _seededStorage(seededManifest, seededFile, png4x4);
    final controller = EditorController(storage: storage);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: EditorShell(
          controller: controller,
          manifest: AssetManifest.fromYaml(
            await storage.readText('assets/sprites/manifest.yaml'),
          ),
        ),
      ),
    );

    // The tab bar scrolls, so a tab past the panel's edge is off it rather

    // than missing: it has to be scrolled to before it can be tapped.

    await tester.ensureVisible(find.text('Sprites'));

    await tester.pumpAndSettle();

    await tester.tap(find.text('Sprites'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('asset-tile-entity.guard.idle.down')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('asset-delete-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-asset-delete')));
    await tester.pumpAndSettle();

    final manifest = AssetManifest.fromYaml(
      await storage.readText('assets/sprites/manifest.yaml'),
    );
    expect(manifest.assets, isEmpty);
    expect(find.text('0 assets'), findsOneWidget);
  });
}

Future<MemoryEditorStorage> _seededStorage(
  String manifest,
  String file,
  Uint8List bytes,
) async {
  final storage = MemoryEditorStorage();
  await storage.writeText('assets/sprites/manifest.yaml', manifest);
  await storage.writeBinary(file, bytes);
  return storage;
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
