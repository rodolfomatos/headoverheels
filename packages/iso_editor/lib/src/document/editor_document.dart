import 'dart:convert';

import 'package:vector_math/vector_math.dart' show Vector3;

class EditorDocument {
  EditorDocument({
    required this.projectName,
    required this.theme,
    required this.width,
    required this.height,
    Iterable<TileLayer> layers = const [],
    Iterable<ObjectPlacement> objects = const [],
    this.metadata = const {},
  }) : layers = List.unmodifiable(layers),
       objects = List.unmodifiable(objects);

  factory EditorDocument.empty() {
    return EditorDocument(
      projectName: 'untitled',
      theme: 'default',
      width: 16,
      height: 16,
      layers: [TileLayer(name: 'floor', cells: const {})],
    );
  }

  factory EditorDocument.fromJson(Map<String, dynamic> json) {
    final rawLayers = json['layers'];
    final rawObjects = json['objects'];
    return EditorDocument(
      projectName: json['project_name'] as String? ?? 'untitled',
      theme: json['theme'] as String? ?? 'default',
      width: (json['width'] as num?)?.toInt() ?? 16,
      height: (json['height'] as num?)?.toInt() ?? 16,
      layers: rawLayers is List
          ? rawLayers.whereType<Map>().map(
              (value) => TileLayer.fromJson(Map<String, dynamic>.from(value)),
            )
          : const [],
      objects: rawObjects is List
          ? rawObjects.whereType<Map>().map(
              (value) =>
                  ObjectPlacement.fromJson(Map<String, dynamic>.from(value)),
            )
          : const [],
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
    );
  }

  final String projectName;
  final String theme;
  final int width;
  final int height;
  final List<TileLayer> layers;
  final List<ObjectPlacement> objects;
  final Map<String, dynamic> metadata;

  EditorDocument copyWith({
    String? projectName,
    String? theme,
    int? width,
    int? height,
    Iterable<TileLayer>? layers,
    Iterable<ObjectPlacement>? objects,
    Map<String, dynamic>? metadata,
  }) {
    return EditorDocument(
      projectName: projectName ?? this.projectName,
      theme: theme ?? this.theme,
      width: width ?? this.width,
      height: height ?? this.height,
      layers: layers ?? this.layers,
      objects: objects ?? this.objects,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'project_name': projectName,
    'theme': theme,
    'width': width,
    'height': height,
    'layers': layers.map((layer) => layer.toJson()).toList(),
    'objects': objects.map((object) => object.toJson()).toList(),
    'metadata': metadata,
  };

  String encode() => jsonEncode(toJson());
}

class TileLayer {
  TileLayer({
    required this.name,
    required this.cells,
    this.visible = true,
    this.locked = false,
  });

  factory TileLayer.fromJson(Map<String, dynamic> json) {
    final rawCells = json['cells'];
    final cells = <CellAddress, int>{};
    if (rawCells is Map) {
      for (final entry in rawCells.entries) {
        final parts = entry.key.toString().split(':');
        if (parts.length != 2) continue;
        final x = int.tryParse(parts[0]);
        final y = int.tryParse(parts[1]);
        final value = (entry.value as num?)?.toInt();
        if (x == null || y == null || value == null) continue;
        cells[CellAddress(x, y)] = value;
      }
    }
    return TileLayer(
      name: json['name'] as String? ?? 'tiles',
      visible: json['visible'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
      cells: cells,
    );
  }

  final String name;
  final bool visible;
  final bool locked;
  final Map<CellAddress, int> cells;

  TileLayer setCell(CellAddress address, int? tileId) {
    final next = Map<CellAddress, int>.from(cells);
    if (tileId == null) {
      next.remove(address);
    } else {
      next[address] = tileId;
    }
    return TileLayer(name: name, visible: visible, locked: locked, cells: next);
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'visible': visible,
    'locked': locked,
    'cells': {
      for (final entry in cells.entries)
        '${entry.key.x}:${entry.key.y}': entry.value,
    },
  };
}

class CellAddress {
  const CellAddress(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) =>
      other is CellAddress && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

class ObjectPlacement {
  const ObjectPlacement({
    required this.id,
    required this.type,
    required this.position,
    this.name = '',
    this.size = const CellAddress(1, 1),
    this.properties = const {},
  });

  factory ObjectPlacement.fromJson(Map<String, dynamic> json) {
    final rawPosition = json['position'];
    final rawSize = json['size'];
    return ObjectPlacement(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      position: rawPosition is List && rawPosition.length >= 3
          ? Vector3(
              (rawPosition[0] as num).toDouble(),
              (rawPosition[1] as num).toDouble(),
              (rawPosition[2] as num).toDouble(),
            )
          : Vector3.zero(),
      size: rawSize is List && rawSize.length >= 2
          ? CellAddress(
              (rawSize[0] as num).toInt(),
              (rawSize[1] as num).toInt(),
            )
          : const CellAddress(1, 1),
      properties: Map<String, dynamic>.from(
        json['properties'] as Map? ?? const {},
      ),
    );
  }

  final String id;
  final String name;
  final String type;
  final Vector3 position;
  final CellAddress size;
  final Map<String, dynamic> properties;

  ObjectPlacement copyWith({
    String? name,
    String? type,
    Vector3? position,
    CellAddress? size,
    Map<String, dynamic>? properties,
  }) {
    return ObjectPlacement(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      position: position ?? this.position,
      size: size ?? this.size,
      properties: properties ?? this.properties,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'position': [position.x, position.y, position.z],
    'size': [size.x, size.y],
    'properties': properties,
  };
}
