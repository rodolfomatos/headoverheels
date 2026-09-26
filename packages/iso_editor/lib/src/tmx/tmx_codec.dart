import 'dart:convert';
import 'dart:math' as math;

import 'package:vector_math/vector_math.dart' show Vector2, Vector3;
import 'package:xml/xml.dart';

import '../document/editor_document.dart';

enum TmxCoordinateMode { tiledIsometric, grid }

class TmxTilesetReference {
  const TmxTilesetReference({
    required this.firstGid,
    required this.source,
    this.tileCount = 256,
    this.name = '',
  });

  factory TmxTilesetReference.fromMapElement(
    XmlElement element, {
    String? fallbackSource,
  }) {
    return TmxTilesetReference(
      firstGid: int.parse(element.getAttribute('firstgid') ?? '1'),
      source: element.getAttribute('source') ?? fallbackSource ?? '',
      tileCount: int.parse(element.getAttribute('tilecount') ?? '256'),
      name: element.getAttribute('name') ?? '',
    );
  }

  factory TmxTilesetReference.fromTsx(String source, {required int firstGid}) {
    final document = XmlDocument.parse(source);
    final element = document.rootElement;
    return TmxTilesetReference(
      firstGid: firstGid,
      source: element.getAttribute('source') ?? '',
      tileCount: int.parse(element.getAttribute('tilecount') ?? '256'),
      name: element.getAttribute('name') ?? '',
    );
  }

  final int firstGid;
  final String source;
  final int tileCount;
  final String name;

  Map<String, dynamic> toMap() => {
    'first_gid': firstGid,
    'source': source,
    'tile_count': tileCount,
    'name': name,
  };

  static TmxTilesetReference fromMap(Map<String, dynamic> map) {
    return TmxTilesetReference(
      firstGid: (map['first_gid'] as num?)?.toInt() ?? 1,
      source: map['source'] as String? ?? '',
      tileCount: (map['tile_count'] as num?)?.toInt() ?? 256,
      name: map['name'] as String? ?? '',
    );
  }
}

class TmxCodec {
  const TmxCodec();

  EditorDocument import(
    String source, {
    String projectName = 'imported',
    String theme = 'default',
    TmxCoordinateMode coordinateMode = TmxCoordinateMode.tiledIsometric,
  }) {
    final document = XmlDocument.parse(source);
    final map = document.rootElement;
    if (map.name.local != 'map') {
      throw const FormatException('TMX root element must be map');
    }
    final orientation = map.getAttribute('orientation') ?? 'orthogonal';
    if (orientation != 'isometric') {
      throw FormatException('Unsupported TMX orientation: $orientation');
    }
    final tileWidth = int.parse(map.getAttribute('tilewidth') ?? '64');
    final tileHeight = int.parse(map.getAttribute('tileheight') ?? '32');
    final width = int.parse(map.getAttribute('width') ?? '0');
    final height = int.parse(map.getAttribute('height') ?? '0');
    if (width <= 0 || height <= 0) {
      throw const FormatException('TMX map must have positive dimensions');
    }

    final tilesets =
        map
            .findElements('tileset')
            .map(TmxTilesetReference.fromMapElement)
            .toList(growable: false)
          ..sort((a, b) => a.firstGid.compareTo(b.firstGid));

    final layers = <TileLayer>[];
    for (final element in map.findElements('layer')) {
      final data = element.getElement('data');
      if (data == null) continue;
      final encoding = data.getAttribute('encoding');
      if (encoding != null && encoding != 'csv') {
        throw FormatException('Unsupported TMX layer encoding: $encoding');
      }
      final values = _parseCsv(data.innerText);
      final expected = width * height;
      if (values.length != expected) {
        throw FormatException(
          'Layer ${element.getAttribute('name')} has ${values.length} cells; expected $expected',
        );
      }
      final cells = <CellAddress, int>{};
      for (var index = 0; index < values.length; index++) {
        final gid = values[index];
        if (gid == 0) continue;
        final tileId = _toLocalTileId(gid, tilesets);
        if (tileId == null) {
          throw FormatException('GID $gid does not belong to a tileset');
        }
        cells[CellAddress(index % width, index ~/ width)] = tileId;
      }
      layers.add(
        TileLayer(
          name: element.getAttribute('name') ?? 'tiles',
          visible:
              (int.tryParse(element.getAttribute('visible') ?? '1') ?? 1) != 0,
          locked: false,
          cells: cells,
        ),
      );
    }

    final objects = <ObjectPlacement>[];
    var objectId = 1;
    for (final group in map.findElements('objectgroup')) {
      for (final element in group.findElements('object')) {
        final pixelX = double.parse(element.getAttribute('x') ?? '0');
        final pixelY = double.parse(element.getAttribute('y') ?? '0');
        final position = _toGridPosition(
          pixelX,
          pixelY,
          mode: coordinateMode,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          mapWidth: width,
          mapHeight: height,
        );
        final pixelWidth = double.parse(element.getAttribute('width') ?? '0');
        final pixelHeight = double.parse(element.getAttribute('height') ?? '0');
        objects.add(
          ObjectPlacement(
            id: element.getAttribute('name')?.isNotEmpty == true
                ? element.getAttribute('name')!
                : 'object_$objectId',
            name: element.getAttribute('name') ?? '',
            type:
                element.getAttribute('class') ??
                element.getAttribute('type') ??
                '',
            position: position,
            size: CellAddress(
              math.max(1, (pixelWidth / tileWidth).round()),
              math.max(1, (pixelHeight / tileHeight).round()),
            ),
            properties: _readProperties(element),
          ),
        );
        objectId++;
      }
    }

    return EditorDocument(
      projectName: projectName,
      theme: theme,
      width: width,
      height: height,
      layers: layers.isEmpty
          ? [TileLayer(name: 'floor', cells: const {})]
          : layers,
      objects: objects,
      metadata: {
        'tmx.orientation': orientation,
        'tmx.render_order': map.getAttribute('renderorder') ?? 'right-down',
        'tmx.coordinate_mode': coordinateMode.name,
        'tmx.tilesets': tilesets.map((tileset) => tileset.toMap()).toList(),
      },
    );
  }

  String export(
    EditorDocument document, {
    String? projectName,
    TmxCoordinateMode? coordinateMode,
  }) {
    final mapWidth = document.width;
    final mapHeight = document.height;
    if (mapWidth <= 0 || mapHeight <= 0) {
      throw StateError('Cannot export a map with non-positive dimensions');
    }
    final tilesets = _readTilesets(document);
    if (tilesets.isEmpty) {
      throw StateError('No tilesets configured in document metadata');
    }
    final mode =
        coordinateMode ??
        TmxCoordinateMode.values.firstWhere(
          (value) => value.name == document.metadata['tmx.coordinate_mode'],
          orElse: () => TmxCoordinateMode.tiledIsometric,
        );

    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(
      'map',
      attributes: {
        'version': '1.10',
        'tiledversion': '1.10.0',
        'orientation': 'isometric',
        'renderorder': document.metadata['tmx.render_order'] ?? 'right-down',
        'width': '$mapWidth',
        'height': '$mapHeight',
        'tilewidth': '64',
        'tileheight': '32',
        'infinite': '0',
        'nextobjectid': '${document.objects.length + 1}',
      },
      nest: () {
        for (final tileset in tilesets) {
          if (tileset.source.isEmpty) {
            throw StateError(
              'Tileset at firstgid ${tileset.firstGid} has no source',
            );
          }
          builder.element(
            'tileset',
            attributes: {
              'firstgid': '${tileset.firstGid}',
              'source': tileset.source,
            },
          );
        }

        var layerId = 1;
        for (final layer in document.layers) {
          final values = <int>[];
          for (var y = 0; y < mapHeight; y++) {
            for (var x = 0; x < mapWidth; x++) {
              final tileId = layer.cells[CellAddress(x, y)] ?? 0;
              values.add(tileId == 0 ? 0 : _toGid(tileId, tilesets));
            }
          }
          builder.element(
            'layer',
            attributes: {
              'id': '${layerId++}',
              'name': layer.name,
              'width': '$mapWidth',
              'height': '$mapHeight',
              if (!layer.visible) 'visible': '0',
            },
            nest: () {
              builder.element(
                'data',
                attributes: {'encoding': 'csv'},
                nest: () {
                  for (var y = 0; y < mapHeight; y++) {
                    builder.text(
                      '${values.sublist(y * mapWidth, (y + 1) * mapWidth).join(',')}'
                      '${y == mapHeight - 1 ? '' : ','}\n',
                    );
                  }
                },
              );
            },
          );
        }

        if (document.objects.isNotEmpty) {
          builder.element(
            'objectgroup',
            attributes: {
              'id': '${layerId++}',
              'name': 'Objects',
              'width': '$mapWidth',
              'height': '$mapHeight',
            },
            nest: () {
              var nextId = 1;
              for (final object in document.objects) {
                final pixel = _toPixelPosition(
                  object.position,
                  mode: mode,
                  tileWidth: 64,
                  tileHeight: 32,
                  mapWidth: mapWidth,
                  mapHeight: mapHeight,
                );
                builder.element(
                  'object',
                  attributes: {
                    'id': '${nextId++}',
                    'name': object.name,
                    'type': object.type,
                    'x': pixel.x.toStringAsFixed(1),
                    'y': pixel.y.toStringAsFixed(1),
                    'width': (object.size.x * 64).toStringAsFixed(1),
                    'height': (object.size.y * 32).toStringAsFixed(1),
                  },
                  nest: () {
                    if (object.properties.isEmpty) return;
                    builder.element(
                      'properties',
                      nest: () {
                        for (final entry in object.properties.entries) {
                          final value = _encodePropertyValue(entry.value);
                          builder.element(
                            'property',
                            attributes: {
                              'name': entry.key,
                              'type': value.type,
                              'value': value.value,
                            },
                          );
                        }
                      },
                    );
                  },
                );
              }
            },
          );
        }
      },
    );
    return builder.buildDocument().toXmlString(pretty: true);
  }

  int? _toLocalTileId(int gid, List<TmxTilesetReference> tilesets) {
    final normalized = gid & 0x1FFFFFFF;
    for (var index = tilesets.length - 1; index >= 0; index--) {
      final tileset = tilesets[index];
      if (normalized >= tileset.firstGid) {
        return normalized - tileset.firstGid;
      }
    }
    return null;
  }

  int _toGid(int tileId, List<TmxTilesetReference> tilesets) {
    for (final tileset in tilesets) {
      if (tileId < tileset.tileCount) return tileset.firstGid + tileId;
    }
    throw StateError('Tile id $tileId is outside the configured tilesets');
  }

  Vector3 _toGridPosition(
    double x,
    double y, {
    required TmxCoordinateMode mode,
    required int tileWidth,
    required int tileHeight,
    required int mapWidth,
    required int mapHeight,
  }) {
    if (mode == TmxCoordinateMode.grid) {
      return Vector3(
        (x / tileWidth).roundToDouble(),
        (y / tileHeight).roundToDouble(),
        0,
      );
    }
    final originX = mapHeight * tileWidth / 2;
    final dx = x - originX;
    final dy = y;
    final gridX = dy / tileHeight - dx / tileWidth;
    final gridY = dy / tileHeight + dx / tileWidth;
    return Vector3(gridX.roundToDouble(), gridY.roundToDouble(), 0);
  }

  Vector2 _toPixelPosition(
    Vector3 position, {
    required TmxCoordinateMode mode,
    required int tileWidth,
    required int tileHeight,
    required int mapWidth,
    required int mapHeight,
  }) {
    if (mode == TmxCoordinateMode.grid) {
      return Vector2(position.x * tileWidth, position.y * tileHeight);
    }
    final originX = mapHeight * tileWidth / 2;
    return Vector2(
      (position.y - position.x) * tileWidth / 2 + originX,
      (position.x + position.y) * tileHeight / 2,
    );
  }

  List<TmxTilesetReference> _readTilesets(EditorDocument document) {
    final raw = document.metadata['tmx.tilesets'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (value) =>
              TmxTilesetReference.fromMap(Map<String, dynamic>.from(value)),
        )
        .toList(growable: false);
  }

  Map<String, dynamic> _readProperties(XmlElement object) {
    final propertiesElement = object.getElement('properties');
    if (propertiesElement == null) return {};
    final result = <String, dynamic>{};
    for (final property in propertiesElement.findElements('property')) {
      final name = property.getAttribute('name');
      if (name == null) continue;
      result[name] = _decodePropertyValue(
        property.getAttribute('value') ?? '',
        property.getAttribute('type') ?? 'string',
      );
    }
    return result;
  }

  dynamic _decodePropertyValue(String value, String type) {
    return switch (type) {
      'bool' => value.toLowerCase() == 'true',
      'int' => int.tryParse(value) ?? 0,
      'float' => double.tryParse(value) ?? 0.0,
      'string' || 'file' || 'object' || 'color' => value,
      _ => _tryDecodeStructured(value),
    };
  }

  dynamic _tryDecodeStructured(String value) {
    try {
      return jsonDecode(value);
    } catch (_) {
      return value;
    }
  }

  ({String type, String value}) _encodePropertyValue(dynamic value) {
    if (value is bool) return (type: 'bool', value: '$value');
    if (value is int) return (type: 'int', value: '$value');
    if (value is double) return (type: 'float', value: '$value');
    if (value is Map || value is List) {
      return (type: 'string', value: jsonEncode(value));
    }
    return (type: 'string', value: value?.toString() ?? '');
  }

  List<int> _parseCsv(String source) {
    return source
        .trim()
        .split(RegExp(r'[,\s]+'))
        .where((value) => value.isNotEmpty)
        .map(int.parse)
        .toList(growable: false);
  }
}
