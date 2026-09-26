import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

enum AssetAlphaMode { opaque, binary, smooth }

AssetAlphaMode assetAlphaModeFromName(String value) {
  return AssetAlphaMode.values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => AssetAlphaMode.opaque,
  );
}

class AssetManifest {
  AssetManifest({required this.version, required Iterable<AssetEntry> assets})
    : assets = List.unmodifiable(assets) {
    for (final asset in this.assets) {
      _byId[asset.id] = asset;
    }
  }

  factory AssetManifest.fromYaml(String source) {
    final document = loadYaml(source);
    if (document is! YamlMap) {
      throw const FormatException('Asset manifest must be a YAML map');
    }
    final rawAssets = document['assets'];
    if (rawAssets is! YamlList) {
      throw const FormatException('Asset manifest must contain an assets list');
    }
    return AssetManifest(
      version: document['version']?.toString() ?? '1.0',
      assets: rawAssets
          .whereType<YamlMap>()
          .map(AssetEntry.fromYaml)
          .toList(growable: false),
    );
  }

  static Future<AssetManifest> load(
    String key, {
    required AssetBundle bundle,
  }) async {
    return AssetManifest.fromYaml(await bundle.loadString(key));
  }

  final String version;
  final List<AssetEntry> assets;
  final Map<String, AssetEntry> _byId = {};

  AssetEntry? getAsset(String id) => _byId[id];

  List<AssetEntry> getAssetsByCategory(String category) {
    return assets.where((asset) => asset.category == category).toList();
  }

  List<AssetEntry> getAssetsByTheme(String theme) {
    return assets.where((asset) => asset.theme == theme).toList();
  }

  AssetManifest upsert(AssetEntry entry) {
    final next = [...assets.where((asset) => asset.id != entry.id), entry];
    return AssetManifest(version: version, assets: next);
  }

  AssetManifest remove(String id) {
    return AssetManifest(
      version: version,
      assets: assets.where((asset) => asset.id != id),
    );
  }

  String toYaml() {
    final document = <String, Object?>{
      'version': version,
      'assets': assets.map((asset) => asset.toMap()).toList(growable: false),
    };
    return '${_encodeYaml(document)}\n';
  }

  static String _encodeYaml(Object? value, [int indent = 0]) {
    final padding = ' ' * indent;
    if (value is Map) {
      if (value.isEmpty) return '$padding{}';
      final lines = <String>[];
      for (final entry in value.entries) {
        final child = entry.value;
        if (_isScalar(child)) {
          lines.add('$padding${entry.key}: ${encodeYamlScalar(child)}');
        } else if (child is List && child.isEmpty) {
          lines.add('$padding${entry.key}: []');
        } else if (child is Map && child.isEmpty) {
          lines.add('$padding${entry.key}: {}');
        } else {
          lines.add('$padding${entry.key}:');
          lines.add(_encodeYaml(child, indent + 2));
        }
      }
      return lines.join('\n');
    }
    if (value is List) {
      if (value.isEmpty) return '$padding[]';
      final lines = <String>[];
      for (final child in value) {
        if (_isScalar(child)) {
          lines.add('$padding- ${encodeYamlScalar(child)}');
        } else {
          lines.add('$padding-');
          lines.add(_encodeYaml(child, indent + 2));
        }
      }
      return lines.join('\n');
    }
    return '$padding${encodeYamlScalar(value)}';
  }

  static bool _isScalar(Object? value) =>
      value == null || value is num || value is bool || value is String;

  static String encodeYamlScalar(Object? value) {
    if (value == null) return 'null';
    if (value is num || value is bool) return value.toString();
    return jsonEncode(value.toString());
  }
}

class AssetEntry {
  const AssetEntry({
    required this.id,
    required this.file,
    required this.category,
    required this.runtimeSize,
    required this.anchor,
    required this.alpha,
    required this.palette,
    required this.scale,
    this.character,
    this.animation,
    this.direction,
    this.entity,
    this.theme,
    this.family,
    this.variant,
    this.tileId,
    this.frames,
    this.frameDuration,
    this.loop,
    this.master,
    this.sourceRegion,
    this.metadata = const {},
  });

  factory AssetEntry.fromYaml(YamlMap yaml) {
    return AssetEntry(
      id: yaml['id']?.toString() ?? '',
      file: yaml['file']?.toString() ?? '',
      category: yaml['category']?.toString() ?? '',
      character: yaml['character']?.toString(),
      animation: yaml['animation']?.toString(),
      direction: yaml['direction']?.toString(),
      entity: yaml['entity']?.toString(),
      theme: yaml['theme']?.toString(),
      family: yaml['family']?.toString(),
      variant: yaml['variant']?.toString(),
      tileId: (yaml['tile_id'] as num?)?.toInt(),
      frames: (yaml['frames'] as num?)?.toInt(),
      frameDuration: (yaml['frame_duration'] as num?)?.toInt(),
      loop: yaml['loop'] as bool?,
      master: yaml['master']?.toString(),
      runtimeSize: _intMap(yaml['runtime_size']),
      anchor: _intMap(yaml['anchor']),
      alpha: yaml['alpha']?.toString() ?? 'opaque',
      palette: yaml['palette']?.toString() ?? 'base',
      scale: (yaml['scale'] as num?)?.toInt() ?? 1,
      sourceRegion: yaml['source_region'] == null
          ? null
          : _intMap(yaml['source_region']),
      metadata: Map<String, dynamic>.from(yaml['metadata'] ?? const {}),
    );
  }

  final String id;
  final String file;
  final String category;
  final String? character;
  final String? animation;
  final String? direction;
  final String? entity;
  final String? theme;
  final String? family;
  final String? variant;
  final int? tileId;
  final int? frames;
  final int? frameDuration;
  final bool? loop;
  final String? master;
  final Map<String, int> runtimeSize;
  final Map<String, int> anchor;
  final String alpha;
  final String palette;
  final int scale;
  final Map<String, int>? sourceRegion;
  final Map<String, dynamic> metadata;

  int get width => runtimeSize['width'] ?? 0;
  int get height => runtimeSize['height'] ?? 0;
  int get anchorX => anchor['x'] ?? 0;
  int get anchorY => anchor['y'] ?? 0;
  AssetAlphaMode get alphaMode => assetAlphaModeFromName(alpha);

  bool get isCharacter => category == 'character';
  bool get isEntity => category == 'entity';
  bool get isTile => category == 'tile';
  bool get isTileset => category == 'tileset';
  bool get isProp => category == 'prop';
  bool get isUI => category == 'ui';
  bool get isEffect => category == 'fx';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file': file,
      'category': category,
      if (character != null) 'character': character,
      if (animation != null) 'animation': animation,
      if (direction != null) 'direction': direction,
      if (entity != null) 'entity': entity,
      if (theme != null) 'theme': theme,
      if (family != null) 'family': family,
      if (variant != null) 'variant': variant,
      if (tileId != null) 'tile_id': tileId,
      if (frames != null) 'frames': frames,
      if (frameDuration != null) 'frame_duration': frameDuration,
      if (loop != null) 'loop': loop,
      if (master != null) 'master': master,
      'runtime_size': runtimeSize,
      'anchor': anchor,
      'alpha': alpha,
      'palette': palette,
      'scale': scale,
      if (sourceRegion != null) 'source_region': sourceRegion,
      if (metadata.isNotEmpty) 'metadata': metadata,
    };
  }

  AssetEntry copyWith({
    String? file,
    String? category,
    String? character,
    String? entity,
    String? animation,
    String? direction,
    String? theme,
    String? family,
    String? variant,
    int? tileId,
    int? frames,
    int? frameDuration,
    bool? loop,
    String? master,
    Map<String, int>? runtimeSize,
    Map<String, int>? anchor,
    String? alpha,
    String? palette,
    int? scale,
    Map<String, int>? sourceRegion,
    Map<String, dynamic>? metadata,
  }) {
    return AssetEntry(
      id: id,
      file: file ?? this.file,
      category: category ?? this.category,
      character: character ?? this.character,
      entity: entity ?? this.entity,
      animation: animation ?? this.animation,
      direction: direction ?? this.direction,
      theme: theme ?? this.theme,
      family: family ?? this.family,
      variant: variant ?? this.variant,
      tileId: tileId ?? this.tileId,
      frames: frames ?? this.frames,
      frameDuration: frameDuration ?? this.frameDuration,
      loop: loop ?? this.loop,
      master: master ?? this.master,
      runtimeSize: runtimeSize ?? this.runtimeSize,
      anchor: anchor ?? this.anchor,
      alpha: alpha ?? this.alpha,
      palette: palette ?? this.palette,
      scale: scale ?? this.scale,
      sourceRegion: sourceRegion ?? this.sourceRegion,
      metadata: metadata ?? this.metadata,
    );
  }
}

class PaletteManager {
  const PaletteManager({
    required this.baseColors,
    required this.themeColors,
    required this.extendedColors,
  });

  factory PaletteManager.fromJson(Map<String, dynamic> json) {
    final rawThemes = json['themes'];
    final themes = rawThemes is Map
        ? rawThemes.map(
            (key, value) => MapEntry(
              key.toString(),
              Map<String, String>.from(value as Map),
            ),
          )
        : <String, Map<String, String>>{};

    return PaletteManager(
      baseColors: Map<String, String>.from(json['base'] as Map? ?? const {}),
      themeColors: Map<String, Map<String, String>>.from(themes),
      extendedColors: Map<String, String>.from(themes['extended'] ?? const {}),
    );
  }

  static Future<PaletteManager> load(
    String key, {
    required AssetBundle bundle,
  }) async {
    final content = await bundle.loadString(key);
    return PaletteManager.fromJson(
      json.decode(content) as Map<String, dynamic>,
    );
  }

  final Map<String, String> baseColors;
  final Map<String, Map<String, String>> themeColors;
  final Map<String, String> extendedColors;

  Set<String> getAllowedColors(String paletteName) {
    return {
      ...baseColors.values.map(_normalize),
      ...?themeColors[paletteName]?.values.map(_normalize),
      if (paletteName == 'extended') ...extendedColors.values.map(_normalize),
    };
  }

  String? getColor(String paletteName, String colorName) {
    return baseColors[colorName] ??
        themeColors[paletteName]?[colorName] ??
        extendedColors[colorName];
  }

  static String _normalize(String value) => value.toLowerCase();
}

class GeometrySpec {
  const GeometrySpec({
    required this.projection,
    required this.tileGeometry,
    required this.characterGeometry,
    required this.entityGeometry,
    required this.uiGeometry,
    required this.scaling,
    required this.enforcement,
  });

  factory GeometrySpec.fromJson(Map<String, dynamic> json) {
    return GeometrySpec(
      projection: Map<String, dynamic>.from(
        json['projection'] as Map? ?? const {},
      ),
      tileGeometry: Map<String, dynamic>.from(
        json['tile_geometry'] as Map? ?? const {},
      ),
      characterGeometry: Map<String, dynamic>.from(
        json['character_geometry'] as Map? ?? const {},
      ),
      entityGeometry: Map<String, dynamic>.from(
        json['entity_geometry'] as Map? ?? const {},
      ),
      uiGeometry: Map<String, dynamic>.from(
        json['ui_geometry'] as Map? ?? const {},
      ),
      scaling: Map<String, dynamic>.from(json['scaling'] as Map? ?? const {}),
      enforcement: Map<String, dynamic>.from(
        json['enforcement'] as Map? ?? const {},
      ),
    );
  }

  static Future<GeometrySpec> load(
    String key, {
    required AssetBundle bundle,
  }) async {
    final content = await bundle.loadString(key);
    return GeometrySpec.fromJson(json.decode(content) as Map<String, dynamic>);
  }

  final Map<String, dynamic> projection;
  final Map<String, dynamic> tileGeometry;
  final Map<String, dynamic> characterGeometry;
  final Map<String, dynamic> entityGeometry;
  final Map<String, dynamic> uiGeometry;
  final Map<String, dynamic> scaling;
  final Map<String, dynamic> enforcement;

  int get tileWidth => (tileGeometry['logical_width'] as num?)?.toInt() ?? 64;
  int get tileHeight => (tileGeometry['logical_height'] as num?)?.toInt() ?? 32;
}

class AssetValidationReport {
  const AssetValidationReport({required this.errors, required this.warnings});

  final List<String> errors;
  final List<String> warnings;

  bool get isValid => errors.isEmpty;
}

class AssetPipeline {
  const AssetPipeline({
    required this.bundle,
    required this.manifest,
    required this.palette,
    required this.geometry,
    this.assetsBasePath = 'assets/sprites',
  });

  static Future<AssetPipeline> load(
    AssetBundle bundle, {
    String manifestKey = 'assets/sprites/manifest.yaml',
    String paletteKey = 'style/palette.json',
    String geometryKey = 'style/geometry.json',
    String assetsBasePath = 'assets/sprites',
  }) async {
    return AssetPipeline(
      bundle: bundle,
      manifest: await AssetManifest.load(manifestKey, bundle: bundle),
      palette: await PaletteManager.load(paletteKey, bundle: bundle),
      geometry: await GeometrySpec.load(geometryKey, bundle: bundle),
      assetsBasePath: assetsBasePath,
    );
  }

  final AssetBundle bundle;
  final AssetManifest manifest;
  final PaletteManager palette;
  final GeometrySpec geometry;
  final String assetsBasePath;

  String assetKey(AssetEntry entry) => p.posix.join(assetsBasePath, entry.file);

  Future<AssetValidationReport> validate() async {
    final errors = <String>[];
    final warnings = <String>[];

    for (final asset in manifest.assets) {
      if (asset.id.isEmpty) {
        errors.add('Asset with empty id');
        continue;
      }
      if (asset.file.isEmpty) {
        errors.add('${asset.id}: empty file path');
        continue;
      }
      if (asset.width < 0 || asset.height < 0) {
        errors.add('${asset.id}: invalid runtime size ${asset.runtimeSize}');
      }
      if (asset.alphaMode == AssetAlphaMode.opaque &&
          asset.category != 'tileset') {
        warnings.add('${asset.id}: opaque alpha declared');
      }
      try {
        await bundle.load(assetKey(asset));
      } catch (_) {
        errors.add('${asset.id}: asset not found at ${assetKey(asset)}');
      }
    }

    return AssetValidationReport(errors: errors, warnings: warnings);
  }
}

Map<String, int> _intMap(Object? value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries)
      entry.key.toString(): (entry.value as num?)?.toInt() ?? 0,
  };
}
