import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:iso_core/iso_core.dart';
import 'package:path/path.dart' as p;

import '../storage/editor_storage.dart';

class ImportedImageInfo {
  const ImportedImageInfo({
    required this.width,
    required this.height,
    required this.hasAlpha,
  });

  final int width;
  final int height;
  final bool hasAlpha;
}

class AssetImportRequest {
  const AssetImportRequest({
    required this.category,
    required this.subject,
    required this.animation,
    this.direction = '',
    this.variant = '',
    this.anchorX,
    this.anchorY,
    this.alpha = AssetAlphaMode.opaque,
    this.palette = 'base',
    this.frameDurationMs = 100,
    this.loop = true,
  });

  final String category;
  final String subject;
  final String animation;
  final String direction;
  final String variant;
  final int? anchorX;
  final int? anchorY;
  final AssetAlphaMode alpha;
  final String palette;
  final int frameDurationMs;
  final bool loop;

  String get assetId {
    final state = VisualState(
      category: category,
      subject: subject,
      animation: animation,
      direction: direction,
      variant: variant,
    );
    return state.assetId;
  }
}

class AssetImportService {
  AssetImportService({
    required this.storage,
    this.manifestKey = 'assets/sprites/manifest.yaml',
    this.assetsBasePath = 'assets/sprites',
  });

  final EditorStorage storage;
  final String manifestKey;
  final String assetsBasePath;

  Future<AssetManifest> loadManifest() async {
    if (!await storage.exists(manifestKey)) {
      throw StateError('Asset manifest not found at $manifestKey');
    }
    return AssetManifest.fromYaml(await storage.readText(manifestKey));
  }

  String storageKey(AssetEntry entry) => storageKeyFor(entry.file);

  String storageKeyFor(String relativeFile) =>
      p.posix.join(assetsBasePath, relativeFile);

  Future<ImportedImageInfo> inspectPng(Uint8List bytes) async {
    _validateSignature(bytes);
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final width = image.width;
      final height = image.height;
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      var hasAlpha = false;
      if (data != null) {
        for (var index = 3; index < data.lengthInBytes; index += 4) {
          if (data.getUint8(index) != 255) {
            hasAlpha = true;
            break;
          }
        }
      }
      image.dispose();
      return ImportedImageInfo(
        width: width,
        height: height,
        hasAlpha: hasAlpha,
      );
    } finally {
      codec.dispose();
    }
  }

  Future<AssetEntry> commit({
    required Uint8List bytes,
    required String fileName,
    required AssetImportRequest request,
  }) async {
    final info = await inspectPng(bytes);
    final relativeFile = p.posix.join(
      request.category,
      request.subject,
      fileName,
    );
    await storage.writeBinary(storageKeyFor(relativeFile), bytes);

    final manifest = await storage.exists(manifestKey)
        ? AssetManifest.fromYaml(await storage.readText(manifestKey))
        : AssetManifest(version: '1.0', assets: const []);
    final entry = AssetEntry(
      id: request.assetId,
      file: relativeFile,
      category: request.category,
      character: request.category == 'character' ? request.subject : null,
      entity: request.category == 'entity' ? request.subject : null,
      animation: request.animation,
      direction: request.direction.isEmpty ? null : request.direction,
      runtimeSize: {'width': info.width, 'height': info.height},
      anchor: {
        'x': request.anchorX ?? info.width ~/ 2,
        'y': request.anchorY ?? info.height - 1,
      },
      alpha: request.alpha.name,
      palette: request.palette,
      scale: 1,
      frames: 1,
      frameDuration: 100,
      loop: false,
      metadata: {'imported': true},
    );
    await storage.writeText(manifestKey, manifest.upsert(entry).toYaml());
    return entry;
  }

  Future<AssetEntry> commitFrames({
    required List<({String name, Uint8List bytes})> frames,
    required AssetImportRequest request,
  }) async {
    if (frames.isEmpty) {
      throw const FormatException('At least one frame is required');
    }
    if (frames.length == 1) {
      return commit(
        bytes: frames.single.bytes,
        fileName: frames.single.name,
        request: request,
      );
    }

    final infos = <ImportedImageInfo>[];
    for (final frame in frames) {
      final info = await inspectPng(frame.bytes);
      if (infos.isNotEmpty &&
          (info.width != infos.first.width ||
              info.height != infos.first.height)) {
        throw const FormatException(
          'All frames of an animation must share the same dimensions',
        );
      }
      infos.add(info);
    }

    final relativeFiles = <String>[];
    for (final frame in frames) {
      final relative = p.posix.join(
        request.category,
        request.subject,
        frame.name,
      );
      await storage.writeBinary(storageKeyFor(relative), frame.bytes);
      relativeFiles.add(relative);
    }

    final manifest = await storage.exists(manifestKey)
        ? AssetManifest.fromYaml(await storage.readText(manifestKey))
        : AssetManifest(version: '1.0', assets: const []);
    final entry = AssetEntry(
      id: request.assetId,
      file: relativeFiles.first,
      category: request.category,
      character: request.category == 'character' ? request.subject : null,
      entity: request.category == 'entity' ? request.subject : null,
      animation: request.animation,
      direction: request.direction.isEmpty ? null : request.direction,
      runtimeSize: {'width': infos.first.width, 'height': infos.first.height},
      anchor: {
        'x': request.anchorX ?? infos.first.width ~/ 2,
        'y': request.anchorY ?? infos.first.height - 1,
      },
      alpha: request.alpha.name,
      palette: request.palette,
      scale: 1,
      frames: relativeFiles.length,
      frameDuration: request.frameDurationMs,
      loop: request.loop,
      metadata: {'imported': true, 'frame_files': relativeFiles},
    );
    await storage.writeText(manifestKey, manifest.upsert(entry).toYaml());
    return entry;
  }

  Future<AssetEntry> appendFrames({
    required AssetEntry entry,
    required List<({String name, Uint8List bytes})> frames,
  }) async {
    if (frames.isEmpty) {
      throw const FormatException('At least one frame is required');
    }
    for (final frame in frames) {
      final info = await inspectPng(frame.bytes);
      if (entry.width > 0 &&
          (info.width != entry.width || info.height != entry.height)) {
        throw FormatException(
          'Frame ${frame.name} is ${info.width}x${info.height} but '
          '${entry.id} is ${entry.width}x${entry.height}',
        );
      }
    }

    final declared = entry.metadata['frame_files'];
    final paths = declared is List
        ? [for (final value in declared) value.toString()]
        : <String>[];
    final base = paths.isEmpty && entry.file.isNotEmpty
        ? <String>[entry.file]
        : paths;
    final incoming = <String, String>{};
    for (final frame in frames) {
      final relative = p.posix.join(
        entry.category,
        entrySubject(entry),
        frame.name,
      );
      await storage.writeBinary(storageKeyFor(relative), frame.bytes);
      incoming[relative] = relative;
    }
    final merged = <String>[
      for (final path in base)
        if (!incoming.containsKey(path)) path,
      ...incoming.keys,
    ];

    final updated = entry.copyWith(
      frames: merged.length,
      metadata: {...entry.metadata, 'frame_files': merged},
    );
    final manifest = await storage.exists(manifestKey)
        ? AssetManifest.fromYaml(await storage.readText(manifestKey))
        : AssetManifest(version: '1.0', assets: const []);
    await storage.writeText(manifestKey, manifest.upsert(updated).toYaml());
    return updated;
  }

  String entrySubject(AssetEntry entry) =>
      entry.entity ?? entry.character ?? entry.animation ?? entry.id;

  void _validateSignature(Uint8List bytes) {
    const signature = [137, 80, 78, 71, 13, 10, 26, 10];
    if (bytes.length < signature.length) {
      throw const FormatException('File is too small to be a PNG');
    }
    for (var index = 0; index < signature.length; index++) {
      if (bytes[index] != signature[index]) {
        throw const FormatException('Only PNG uploads are supported');
      }
    }
  }
}
