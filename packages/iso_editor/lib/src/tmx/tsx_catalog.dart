import 'dart:math' as math;

import 'package:xml/xml.dart';

class TsxTileDefinition {
  const TsxTileDefinition({
    required this.id,
    required this.type,
    required this.className,
    required this.properties,
  });

  final int id;
  final String type;
  final String className;
  final Map<String, dynamic> properties;
}

class TsxTilesetDefinition {
  const TsxTilesetDefinition({
    required this.name,
    required this.tileWidth,
    required this.tileHeight,
    required this.tileCount,
    required this.columns,
    required this.imageSource,
    required this.imageWidth,
    required this.imageHeight,
    required this.tiles,
  });

  factory TsxTilesetDefinition.parse(String source) {
    final document = XmlDocument.parse(source);
    final element = document.rootElement;
    if (element.name.local != 'tileset') {
      throw const FormatException('TSX root element must be tileset');
    }
    final image = element.getElement('image');
    final tiles = <TsxTileDefinition>[];
    for (final tile in element.findElements('tile')) {
      final id = int.tryParse(tile.getAttribute('id') ?? '');
      if (id == null) continue;
      final properties = <String, dynamic>{};
      final propertiesElement = tile.getElement('properties');
      if (propertiesElement != null) {
        for (final property in propertiesElement.findElements('property')) {
          final name = property.getAttribute('name');
          if (name == null) continue;
          properties[name] = _propertyValue(property);
        }
      }
      tiles.add(
        TsxTileDefinition(
          id: id,
          type: tile.getAttribute('type') ?? '',
          className: tile.getAttribute('class') ?? '',
          properties: properties,
        ),
      );
    }
    tiles.sort((a, b) => a.id.compareTo(b.id));
    final tileWidth = int.parse(element.getAttribute('tilewidth') ?? '64');
    final tileHeight = int.parse(element.getAttribute('tileheight') ?? '32');
    final tileCount = int.parse(element.getAttribute('tilecount') ?? '0');
    final columns = int.parse(element.getAttribute('columns') ?? '0');
    return TsxTilesetDefinition(
      name: element.getAttribute('name') ?? 'tileset',
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      tileCount: tileCount,
      columns: columns,
      imageSource: image?.getAttribute('source') ?? '',
      imageWidth: int.tryParse(image?.getAttribute('width') ?? '') ?? 0,
      imageHeight: int.tryParse(image?.getAttribute('height') ?? '') ?? 0,
      tiles: List.unmodifiable(tiles),
    );
  }

  final String name;
  final int tileWidth;
  final int tileHeight;
  final int tileCount;
  final int columns;
  final String imageSource;
  final int imageWidth;
  final int imageHeight;
  final List<TsxTileDefinition> tiles;

  int get rows => columns <= 0 ? 0 : (tileCount + columns - 1) ~/ columns;

  TsxTileDefinition? tileById(int id) {
    for (final tile in tiles) {
      if (tile.id == id) return tile;
    }
    return null;
  }

  ({double x, double y}) alignmentForTile(int id) {
    if (columns <= 0 || rows <= 0) return (x: 0, y: 0);
    final column = id % columns;
    final row = id ~/ columns;
    return (
      x: ((column + 0.5) / columns) * 2 - 1,
      y: ((row + 0.5) / rows) * 2 - 1,
    );
  }

  static dynamic _propertyValue(XmlElement property) {
    final value = property.getAttribute('value') ?? '';
    return switch (property.getAttribute('type') ?? 'string') {
      'bool' => value.toLowerCase() == 'true',
      'int' => int.tryParse(value) ?? 0,
      'float' => double.tryParse(value) ?? 0.0,
      _ => value,
    };
  }
}

class TsxCatalog {
  TsxCatalog(Iterable<TsxTilesetDefinition> tilesets)
    : tilesets = List.unmodifiable(tilesets);

  final List<TsxTilesetDefinition> tilesets;

  TsxTilesetDefinition? byName(String name) {
    for (final tileset in tilesets) {
      if (tileset.name == name) return tileset;
    }
    return null;
  }

  int get tileCount => tilesets.fold(
    0,
    (total, tileset) => total + math.max(0, tileset.tileCount),
  );
}
