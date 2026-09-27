import 'dart:math' as math;

import 'package:xml/xml.dart';

/// One tile of a tileset: its id, the type the game looks for, and its
/// properties.
///
/// Immutable, with [copyWith] for editing. The editor changes a tile and the
/// tileset around it has to agree, so a change is a new value rather than a
/// mutation somebody else can miss.
class TsxTileDefinition {
  const TsxTileDefinition({
    required this.id,
    this.type = '',
    this.className = '',
    this.properties = const {},
  });

  /// Reads one `<tile>`, the same way Tiled writes it.
  factory TsxTileDefinition.parse(XmlElement element) {
    final id = int.tryParse(element.getAttribute('id') ?? '');
    if (id == null) {
      throw const FormatException('A tile needs an id');
    }
    final properties = <String, dynamic>{};
    final propertiesElement = element.getElement('properties');
    if (propertiesElement != null) {
      for (final property in propertiesElement.findElements('property')) {
        final name = property.getAttribute('name');
        if (name == null || name.isEmpty) continue;
        properties[name] = propertyValue(property);
      }
    }
    return TsxTileDefinition(
      id: id,
      type: element.getAttribute('type') ?? '',
      className: element.getAttribute('class') ?? '',
      properties: Map.unmodifiable(properties),
    );
  }

  final int id;

  /// The name the game looks up, such as `floor` or `chest`.
  final String type;

  /// Tiled's own class field, kept apart so editing one is not mistaken for
  /// editing the other.
  final String className;

  final Map<String, dynamic> properties;

  /// The same tile with the given fields replaced.
  TsxTileDefinition copyWith({
    int? id,
    String? type,
    String? className,
    Map<String, dynamic>? properties,
  }) => TsxTileDefinition(
    id: id ?? this.id,
    type: type ?? this.type,
    className: className ?? this.className,
    properties: properties == null
        ? this.properties
        : Map.unmodifiable(properties),
  );

  /// The same tile with one property set, read as the type it already has so
  /// editing a number does not quietly turn it into text.
  TsxTileDefinition withProperty(String name, String value) {
    if (name.trim().isEmpty) return this;
    final next = Map<String, dynamic>.of(properties);
    next[name.trim()] = coerceValue(value, properties[name.trim()]);
    return copyWith(properties: next);
  }

  /// The same tile with one property removed.
  TsxTileDefinition withoutProperty(String name) {
    if (!properties.containsKey(name)) return this;
    final next = Map<String, dynamic>.of(properties)..remove(name);
    return copyWith(properties: next);
  }

  /// The property type Tiled spells for a value.
  static String typeOf(dynamic value) => switch (value) {
    bool() => 'bool',
    int() => 'int',
    double() => 'float',
    _ => 'string',
  };

  /// Reads [value] as the type [current] already has.
  static dynamic coerceValue(String value, dynamic current) =>
      switch (current) {
        bool() => value.toLowerCase() == 'true' || value == '1',
        int() => int.tryParse(value.trim()) ?? 0,
        double() => double.tryParse(value.trim()) ?? 0.0,
        _ => value,
      };

  /// The value of a property, read as the type Tiled declared.
  static dynamic propertyValue(XmlElement property) {
    final value = property.getAttribute('value') ?? '';
    return switch (property.getAttribute('type') ?? 'string') {
      'bool' => value.toLowerCase() == 'true',
      'int' => int.tryParse(value) ?? 0,
      'float' => double.tryParse(value) ?? 0.0,
      _ => value,
    };
  }

  /// The tile as Tiled reads it.
  XmlElement toXml() {
    final element = XmlElement(XmlName('tile'), [
      XmlAttribute(XmlName('id'), id.toString()),
      if (type.isNotEmpty) XmlAttribute(XmlName('type'), type),
      if (className.isNotEmpty) XmlAttribute(XmlName('class'), className),
    ]);
    if (properties.isEmpty) return element;
    element.children.add(
      XmlElement(XmlName('properties'), [], [
        for (final entry in properties.entries)
          XmlElement(XmlName('property'), [
            XmlAttribute(XmlName('name'), entry.key),
            XmlAttribute(XmlName('type'), typeOf(entry.value)),
            XmlAttribute(XmlName('value'), entry.value.toString()),
          ]),
      ]),
    );
    return element;
  }

  @override
  String toString() => 'tile $id ${type.isEmpty ? '(no type)' : type}';
}

/// A tileset: the sheet it points at, how it is cut up, and what each tile means.
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
    final tiles = <TsxTileDefinition>[
      for (final tile in element.findElements('tile'))
        TsxTileDefinition.parse(tile),
    ]..sort((a, b) => a.id.compareTo(b.id));
    return TsxTilesetDefinition(
      name: element.getAttribute('name') ?? 'tileset',
      tileWidth: int.parse(element.getAttribute('tilewidth') ?? '64'),
      tileHeight: int.parse(element.getAttribute('tileheight') ?? '32'),
      tileCount: int.parse(element.getAttribute('tilecount') ?? '0'),
      columns: int.parse(element.getAttribute('columns') ?? '0'),
      imageSource: image?.getAttribute('source') ?? '',
      imageWidth: int.tryParse(image?.getAttribute('width') ?? '') ?? 0,
      imageHeight: int.tryParse(image?.getAttribute('height') ?? '') ?? 0,
      tiles: List.unmodifiable(tiles),
    );
  }

  /// A new tileset, sized from the sheet it points at.
  ///
  /// Authoring starts here: name it, point it at an image, and the count and
  /// the columns follow from the image rather than from a guess.
  factory TsxTilesetDefinition.create({
    required String name,
    required String imageSource,
    required int imageWidth,
    required int imageHeight,
    int tileWidth = 64,
    int tileHeight = 32,
  }) {
    if (tileWidth <= 0 || tileHeight <= 0) {
      throw ArgumentError('A tile has to be bigger than nothing');
    }
    if (imageWidth <= 0 || imageHeight <= 0) {
      throw ArgumentError('$imageSource has no pixels');
    }
    final columns = imageWidth ~/ tileWidth;
    final rows = imageHeight ~/ tileHeight;
    if (columns <= 0 || rows <= 0) {
      throw ArgumentError(
        '$imageSource is $imageWidth by $imageHeight, which holds no '
        '${tileWidth}x$tileHeight tile',
      );
    }
    return TsxTilesetDefinition(
      name: name,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      tileCount: columns * rows,
      columns: columns,
      imageSource: imageSource,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      tiles: const [],
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

  /// The same tileset with the given fields replaced. The tile list stays sorted
  /// by id, which is what Tiled writes and what [parse] expects back.
  TsxTilesetDefinition copyWith({
    String? name,
    int? tileWidth,
    int? tileHeight,
    int? tileCount,
    int? columns,
    String? imageSource,
    int? imageWidth,
    int? imageHeight,
    List<TsxTileDefinition>? tiles,
  }) {
    final next = List<TsxTileDefinition>.of(tiles ?? this.tiles)
      ..sort((a, b) => a.id.compareTo(b.id));
    return TsxTilesetDefinition(
      name: name ?? this.name,
      tileWidth: tileWidth ?? this.tileWidth,
      tileHeight: tileHeight ?? this.tileHeight,
      tileCount: tileCount ?? this.tileCount,
      columns: columns ?? this.columns,
      imageSource: imageSource ?? this.imageSource,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      tiles: List.unmodifiable(next),
    );
  }

  /// The same tileset with a tile added or replaced, by id.
  TsxTilesetDefinition upsertTile(TsxTileDefinition tile) => copyWith(
    tiles: [
      for (final existing in tiles)
        if (existing.id != tile.id) existing,
      tile,
    ],
  );

  /// The same tileset without the tile of that id.
  TsxTilesetDefinition removeTile(int id) => copyWith(
    tiles: [
      for (final tile in tiles)
        if (tile.id != id) tile,
    ],
  );

  /// The tile at [id], or a new empty one, so describing a tile that has never
  /// been described starts from a value rather than from null.
  TsxTileDefinition tileOrNew(int id) =>
      tileById(id) ?? TsxTileDefinition(id: id);

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

  /// The tileset as Tiled reads it.
  String toXmlString() {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"?');
    builder.element(
      'tileset',
      attributes: {
        'version': '1.10',
        'tiledversion': '1.10.2',
        'name': name,
        'tilewidth': tileWidth.toString(),
        'tileheight': tileHeight.toString(),
        'tilecount': tileCount.toString(),
        'columns': columns.toString(),
      },
      nest: [
        if (imageSource.isNotEmpty)
          XmlElement(XmlName('image'), [
            XmlAttribute(XmlName('source'), imageSource),
            XmlAttribute(XmlName('width'), imageWidth.toString()),
            XmlAttribute(XmlName('height'), imageHeight.toString()),
          ]),
        for (final tile in tiles) tile.toXml(),
      ],
    );
    return builder.buildDocument().toXmlString();
  }
}

/// What is wrong with a tileset, in words an author can act on.
///
/// The same shape as the world graph's validation, so the editor reports
/// problems from a map and from a tileset the same way.
class TsxValidation {
  const TsxValidation(this.errors, this.warnings);

  factory TsxValidation.of(Iterable<TsxTilesetDefinition> tilesets) {
    final errors = <String>[];
    final warnings = <String>[];
    for (final tileset in tilesets) {
      errors.addAll(_errorsFor(tileset));
      warnings.addAll(_warningsFor(tileset));
    }
    return TsxValidation(
      List.unmodifiable(errors),
      List.unmodifiable(warnings),
    );
  }

  static List<String> _errorsFor(TsxTilesetDefinition tileset) {
    final errors = <String>[];
    if (tileset.name.trim().isEmpty) {
      errors.add('A tileset needs a name');
    }
    if (tileset.tileWidth <= 0 || tileset.tileHeight <= 0) {
      errors.add('${tileset.name} has no tile size');
    }
    if (tileset.columns <= 0) {
      errors.add('${tileset.name} has no columns, so nothing can be placed');
    }
    if (tileset.imageSource.isEmpty) {
      errors.add('${tileset.name} points at no image');
    }
    final seen = <int>{};
    for (final tile in tileset.tiles) {
      if (tile.id < 0) {
        errors.add('${tileset.name} has a tile with a negative id');
      }
      if (!seen.add(tile.id)) {
        errors.add('${tileset.name} describes tile ${tile.id} twice');
      }
      if (tileset.tileCount > 0 && tile.id >= tileset.tileCount) {
        errors.add(
          '${tileset.name} has ${tileset.tileCount} tiles, so tile '
          '${tile.id} is off the sheet',
        );
      }
    }
    return errors;
  }

  static List<String> _warningsFor(TsxTilesetDefinition tileset) {
    final warnings = <String>[];
    for (final tile in tileset.tiles) {
      // A tile with neither a type nor a property is a tile the game cannot
      // tell apart from any other.
      if (tile.type.isEmpty && tile.properties.isEmpty) {
        warnings.add(
          '${tileset.name} tile ${tile.id} has no type and no properties',
        );
      }
    }
    if (tileset.columns > 0 &&
        tileset.imageWidth > 0 &&
        tileset.imageWidth ~/ tileset.columns < tileset.tileWidth) {
      warnings.add(
        '${tileset.name}: the sheet is narrower than ${tileset.columns} tiles',
      );
    }
    return warnings;
  }

  final List<String> errors;
  final List<String> warnings;

  bool get isValid => errors.isEmpty;
}

/// Every tileset the editor has open.
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

  /// The catalog with a tileset added or replaced, by name.
  TsxCatalog upsert(TsxTilesetDefinition tileset) => TsxCatalog([
    for (final existing in tilesets)
      if (existing.name != tileset.name) existing,
    tileset,
  ]);

  /// The catalog without the tileset of that name.
  TsxCatalog remove(String name) => TsxCatalog([
    for (final tileset in tilesets)
      if (tileset.name != name) tileset,
  ]);

  /// What is wrong with every tileset here.
  TsxValidation get validation => TsxValidation.of(tilesets);
}
