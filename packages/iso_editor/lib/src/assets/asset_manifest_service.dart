import 'package:iso_core/iso_core.dart';

import '../storage/editor_storage.dart';

class AssetManifestService {
  const AssetManifestService({
    required this.storage,
    this.manifestKey = 'assets/sprites/manifest.yaml',
  });

  final EditorStorage storage;
  final String manifestKey;

  Future<AssetManifest> load() async {
    if (!await storage.exists(manifestKey)) {
      return AssetManifest(version: '1.0', assets: const []);
    }
    return AssetManifest.fromYaml(await storage.readText(manifestKey));
  }

  Future<AssetManifest> save(AssetManifest manifest) async {
    await storage.writeText(manifestKey, manifest.toYaml());
    return manifest;
  }

  Future<AssetManifest> update(
    AssetManifest manifest,
    String id,
    AssetEntry Function(AssetEntry entry) transform,
  ) async {
    final entry = manifest.getAsset(id);
    if (entry == null) {
      throw StateError('Unknown asset id: $id');
    }
    return save(manifest.upsert(transform(entry)));
  }

  Future<AssetManifest> remove(
    AssetManifest manifest,
    String id, {
    bool deleteFile = false,
    bool deleteFrameFiles = false,
  }) async {
    final entry = manifest.getAsset(id);
    if (deleteFile && entry != null) {
      await _deleteIfPresent(joinAssetsPath(entry.file));
      if (deleteFrameFiles) {
        for (final frame in frameFilesOf(entry)) {
          await _deleteIfPresent(joinAssetsPath(frame));
        }
      }
    }
    return save(manifest.remove(id));
  }

  Future<void> _deleteIfPresent(String key) async {
    if (await storage.exists(key)) {
      await storage.delete(key);
    }
  }

  String joinAssetsPath(String relativeFile) => 'assets/sprites/$relativeFile';

  static List<String> frameFilesOf(AssetEntry entry) {
    final raw = entry.metadata['frame_files'];
    if (raw is List) {
      return [for (final value in raw) value.toString()];
    }
    return const [];
  }
}
