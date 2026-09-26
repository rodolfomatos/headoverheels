import 'dart:convert';

import 'package:flutter/services.dart' hide AssetManifest;
import 'package:flutter_test/flutter_test.dart';
import 'package:iso_core/iso_core.dart';
import 'package:vector_math/vector_math.dart';

void main() {
  group('isometric coordinates', () {
    test('round trips grid and screen positions', () {
      final grid = Vector3(7, 5, 1);
      final gridAgain = screenToGridAtLevel(gridToScreen(grid), 1);

      expect(gridAgain.x, closeTo(grid.x, 0.001));
      expect(gridAgain.y, closeTo(grid.y, 0.001));
      expect(gridAgain.z, closeTo(grid.z, 0.001));
    });

    test('converts movement vectors to eight-way directions', () {
      expect(Direction8.fromVector(Vector2(0, -1)), Direction8.north);
      expect(Direction8.fromVector(Vector2(1, 0)), Direction8.east);
      expect(Direction8.fromVector(Vector2(-1, 1)), Direction8.southWest);
      expect(Direction8.north.opposite, Direction8.south);
    });
  });

  group('physics', () {
    test('detects and separates overlapping bodies', () {
      final a = AABB(minX: 0, minY: 0, maxX: 2, maxY: 2);
      final b = AABB(minX: 1, minY: 1, maxX: 3, maxY: 3);

      expect(a.overlaps(b), isTrue);
      expect(a.movedBy(Vector2(-1, 0)).overlaps(b), isFalse);
    });
  });

  group('assets', () {
    const manifestYaml = '''
version: "1.0"
assets:
  - id: "character.hero.idle.s"
    file: "characters/hero/idle_s.png"
    category: "character"
    character: "hero"
    animation: "idle"
    direction: "s"
    frames: 4
    frame_duration: 120
    loop: true
    runtime_size: { width: 48, height: 48 }
    anchor: { x: 24, y: 43 }
    alpha: "opaque"
    palette: "base"
    scale: 1
''';

    test('parses and serializes manifest entries', () {
      final manifest = AssetManifest.fromYaml(manifestYaml);
      final entry = manifest.getAsset('character.hero.idle.s');

      expect(entry, isNotNull);
      expect(entry!.width, 48);
      expect(entry.anchorY, 43);
      expect(entry.alphaMode, AssetAlphaMode.opaque);

      final roundTrip = AssetManifest.fromYaml(manifest.toYaml());
      expect(roundTrip.getAsset(entry.id)?.file, entry.file);
    });

    test('loads palette and geometry from an asset bundle', () async {
      final bundle = _MemoryAssetBundle({
        'assets/sprites/manifest.yaml': manifestYaml,
        'style/palette.json': '''
{"base":{"black":"#000000"},"themes":{"extended":{"orange":"#FF9800"},"castle":{"stone":"#4A4A4A"}}}
''',
        'style/geometry.json': '''
{"tile_geometry":{"logical_width":64,"logical_height":32}}
''',
        'assets/sprites/characters/hero/idle_s.png': 'png',
      });

      final pipeline = await AssetPipeline.load(bundle);
      final report = await pipeline.validate();

      expect(report.isValid, isTrue);
      expect(
        pipeline.palette.getAllowedColors('extended'),
        contains('#ff9800'),
      );
      expect(pipeline.geometry.tileWidth, 64);
      expect(pipeline.geometry.tileHeight, 32);
    });
  });

  group('levels', () {
    test('parses world graph without inventing room metadata', () {
      final graph = WorldGraph.fromJson({
        'startRoom': 'start',
        'rooms': {
          'start': {
            'file': 'start.tmx',
            'theme': 'castle',
            'spawnPoint': {'x': 1, 'y': 2, 'z': 0},
            'exits': [
              {'direction': 'east', 'room': 'next', 'entrance': 'west'},
            ],
            'triggers': [
              {
                'id': 'door_1',
                'type': 'door',
                'position': {'x': 3, 'y': 4, 'z': 0},
                'size': {'width': 1, 'height': 1},
              },
            ],
          },
        },
        'planets': [
          {'id': 'castle', 'name': 'Castle'},
        ],
      });

      expect(graph.getRoom('start')?.spawnPosition, Vector3(1, 2, 0));
      expect(graph.getRoom('start')?.exits.single.room, 'next');
      expect(graph.getRoomsByTheme('castle'), hasLength(1));
      expect(graph.groups.single.name, 'Castle');
    });
  });

  group('entities', () {
    test('creates registered entity types and rejects unknown types', () {
      final factory = EntityFactory(
        registry: EntityRegistry(const [
          EntityTypeDefinition(id: 'crystal', category: 'item'),
        ]),
      );
      factory.register(
        'crystal',
        (id, position, properties) =>
            _TestEntity(id: id, typeId: 'crystal', position: position),
      );

      final entity = factory.create(
        'crystal_1',
        'crystal',
        Vector3(2, 3, 0),
        const {},
      );
      expect(entity.id, 'crystal_1');
      expect(
        () => factory.create('x', 'unknown', Vector3.zero(), const {}),
        throwsStateError,
      );
    });
  });

  group('input and visual state', () {
    test('routes the strongest movement source and merges actions', () {
      final router = InputRouter()
        ..add(_TestInputSource(InputState(move: Vector2(1, 0))))
        ..add(
          _TestInputSource(
            InputState(move: Vector2(0.5, 0.5), actions: {GameAction.jump}),
          ),
        );

      expect(router.state.direction, Direction8.east);
      expect(router.state.isPressed(GameAction.jump), isTrue);
    });

    test('builds semantic asset ids', () {
      const state = VisualState(
        category: 'character',
        subject: 'hero',
        animation: 'walk',
        direction: 'ne',
      );

      expect(state.assetId, 'character.hero.walk.ne');
    });
  });
}

class _MemoryAssetBundle extends CachingAssetBundle {
  _MemoryAssetBundle(Map<String, String> assets) : _assets = assets;

  final Map<String, String> _assets;

  @override
  Future<ByteData> load(String key) async {
    final value = _assets[key];
    if (value == null) {
      throw StateError('Asset not found: $key');
    }
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(value)));
  }
}

class _TestEntity extends GameEntity {
  _TestEntity({
    required super.id,
    required super.typeId,
    required super.position,
  });

  @override
  void updateEntity(double dt) {}
}

class _TestInputSource implements InputSource {
  _TestInputSource(this._state);

  final InputState _state;

  @override
  InputState get state => _state;

  @override
  Stream<InputState> get changes => const Stream.empty();

  @override
  void dispose() {}
}
