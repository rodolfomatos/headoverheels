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

    test('round trips a world graph through json', () {
      final graph = WorldGraph.fromJson({
        'startRoom': 'start',
        'rooms': {
          'start': {
            'file': 'start.tmx',
            'theme': 'castle',
            'spawnPoint': {'x': 1, 'y': 2, 'z': 0},
            'exits': [
              {
                'direction': 'east',
                'room': 'next',
                'entrance': 'west',
                'isLocked': true,
                'keyId': 'brass',
                'oneWay': true,
              },
            ],
            'triggers': [
              {
                'id': 'switch_1',
                'type': 'switch',
                'position': {'x': 3, 'y': 4, 'z': 0},
                'size': {'width': 1, 'height': 1},
                'room': 'next',
              },
            ],
          },
        },
        'planets': [
          {'id': 'castle', 'name': 'Castle'},
        ],
      });

      final decoded = WorldGraph.fromJson(
        jsonDecode(graph.toJsonString()) as Map<String, dynamic>,
      );

      expect(decoded.startRoom, 'start');
      expect(decoded.getRoom('start')?.spawnPosition, Vector3(1, 2, 0));
      final exit = decoded.getRoom('start')!.exits.single;
      expect(exit.room, 'next');
      expect(exit.isLocked, isTrue);
      expect(exit.keyId, 'brass');
      expect(exit.oneWay, isTrue);
      final trigger = decoded.getRoom('start')!.triggers.single;
      expect(trigger.type, 'switch');
      expect(trigger.position, Vector3(3, 4, 0));
      expect(trigger.properties['room'], 'next');
      expect(decoded.groups.single.id, 'castle');
    });

    test('edits rooms and exits without losing triggers', () {
      final graph = WorldGraph.fromJson({
        'startRoom': 'start',
        'rooms': {
          'start': {
            'file': 'start.tmx',
            'theme': 'castle',
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
      });

      final room = graph.getRoom('start')!;
      final edited = graph.upsertRoom(
        room.copyWith(
          exits: [room.exits.single.copyWith(isLocked: true, keyId: 'gold')],
        ),
      );

      expect(edited.getRoom('start')!.exits.single.isLocked, isTrue);
      expect(edited.getRoom('start')!.exits.single.keyId, 'gold');
      expect(edited.getRoom('start')!.triggers, hasLength(1));

      final without = edited.removeRoom('start');
      expect(without.rooms, isEmpty);
    });
  });

  group('world validation', () {
    WorldGraph graphWith(Map<String, dynamic> rooms, {String start = 'a'}) =>
        WorldGraph.fromJson({'startRoom': start, 'rooms': rooms});

    test('accepts a symmetric graph', () {
      final validation = validateWorld(
        graphWith({
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
        }),
      );

      expect(validation.isValid, isTrue);
      expect(validation.issues, isEmpty);
    });

    test('reports unknown targets, duplicates and unreachable rooms', () {
      final validation = validateWorld(
        graphWith({
          'a': {
            'file': 'a.tmx',
            'theme': 'castle',
            'exits': [
              {'direction': 'east', 'room': 'ghost', 'entrance': 'west'},
              {'direction': 'east', 'room': 'c', 'entrance': 'west'},
            ],
          },
          'c': {
            'file': 'c.tmx',
            'theme': 'castle',
            'exits': [
              {'direction': 'west', 'room': 'a', 'entrance': 'east'},
            ],
          },
          'island': {'file': 'island.tmx', 'theme': 'castle'},
        }),
      );

      expect(
        validation.issues.where((i) => i.kind == WorldIssueKind.unknownTarget),
        hasLength(1),
      );
      expect(
        validation.issues.where(
          (i) => i.kind == WorldIssueKind.duplicateDirection,
        ),
        hasLength(1),
      );
      expect(
        validation.issues.where((i) => i.kind == WorldIssueKind.unreachable),
        hasLength(1),
      );
      expect(validation.isValid, isFalse);
    });

    test('reports a missing start room, missing file and dead ends', () {
      final validation = validateWorld(
        graphWith({
          'a': {
            'file': '',
            'theme': '',
            'exits': [
              {'direction': 'east', 'room': 'a', 'entrance': 'west'},
            ],
          },
        }, start: 'nowhere'),
      );

      expect(
        validation.issues.where(
          (i) => i.kind == WorldIssueKind.missingStartRoom,
        ),
        hasLength(1),
      );
      expect(
        validation.issues.where((i) => i.kind == WorldIssueKind.missingFile),
        hasLength(1),
      );
      expect(
        validation.issues.where((i) => i.kind == WorldIssueKind.emptyTheme),
        hasLength(1),
      );
      expect(
        validation.issues.where((i) => i.kind == WorldIssueKind.selfLoop),
        hasLength(1),
      );
    });

    test('flags one-way and asymmetric exits', () {
      final validation = validateWorld(
        graphWith({
          'a': {
            'file': 'a.tmx',
            'theme': 'castle',
            'exits': [
              {
                'direction': 'east',
                'room': 'b',
                'entrance': 'west',
                'oneWay': true,
              },
            ],
          },
          'b': {'file': 'b.tmx', 'theme': 'castle'},
        }),
      );

      expect(
        validation.issues.where((i) => i.kind == WorldIssueKind.asymmetricExit),
        isEmpty,
      );
      expect(
        validation.issues.where((i) => i.kind == WorldIssueKind.deadEnd),
        hasLength(1),
      );
    });

    test('resolves trigger targets from nested properties', () {
      final trigger = RoomTrigger(
        id: 'switch_1',
        type: 'switch',
        position: Vector3(1, 1, 0),
        size: Vector2(1, 1),
        properties: {
          'id': 'switch_1',
          'type': 'switch',
          'properties': {'targetId': 'door_secret_1'},
        },
      );
      expect(localTargetOf(trigger), 'door_secret_1');
      expect(roomTargetOf(trigger), isNull);

      final toRoom = RoomTrigger(
        id: 'teleporter_1',
        type: 'teleport',
        position: Vector3(1, 1, 0),
        size: Vector2(1, 1),
        properties: {
          'id': 'teleporter_1',
          'properties': {'room': 'moonbase_hq'},
        },
      );
      expect(roomTargetOf(toRoom), 'moonbase_hq');
      expect(localTargetOf(toRoom), isNull);
    });

    test('ignores triggers that only point at local objects', () {
      final validation = validateWorld(
        graphWith({
          'a': {
            'file': 'a.tmx',
            'theme': 'castle',
            'exits': [
              {'direction': 'east', 'room': 'b', 'entrance': 'west'},
            ],
            'triggers': [
              {
                'id': 'switch_1',
                'type': 'switch',
                'position': {'x': 1, 'y': 1, 'z': 0},
                'size': {'width': 1, 'height': 1},
                'properties': {'targetId': 'door_secret_1'},
              },
            ],
          },
          'b': {
            'file': 'b.tmx',
            'theme': 'castle',
            'exits': [
              {'direction': 'west', 'room': 'a', 'entrance': 'east'},
            ],
          },
        }),
      );

      expect(validation.issues, isEmpty);
    });

    test('flags trigger targets and empty graphs', () {
      final validation = validateWorld(
        graphWith({
          'a': {
            'file': 'a.tmx',
            'theme': 'castle',
            'triggers': [
              {
                'id': 'switch_1',
                'type': 'switch',
                'position': {'x': 1, 'y': 1, 'z': 0},
                'size': {'width': 1, 'height': 1},
                'room': 'nowhere',
              },
              {
                'id': 'door_1',
                'type': 'door',
                'position': {'x': 2, 'y': 1, 'z': 0},
                'size': {'width': 1, 'height': 1},
              },
            ],
          },
        }),
      );

      expect(
        validation.issues.where(
          (i) => i.kind == WorldIssueKind.triggerUnknownRoom,
        ),
        hasLength(1),
      );
      expect(validateWorld(WorldGraph.fromJson({})).isValid, isFalse);
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
