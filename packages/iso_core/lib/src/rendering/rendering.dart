import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:path/path.dart' as p;

import '../assets/assets.dart';

class VisualState {
  const VisualState({
    required this.category,
    required this.subject,
    required this.animation,
    this.direction = '',
    this.variant = '',
  });

  final String category;
  final String subject;
  final String animation;
  final String direction;
  final String variant;

  String get assetId {
    final parts = <String>[category, subject, animation];
    if (direction.isNotEmpty) parts.add(direction);
    if (variant.isNotEmpty) parts.add(variant);
    return parts.join('.');
  }
}

class SpriteAnimationData {
  const SpriteAnimationData({
    required this.assetId,
    required this.category,
    required this.subject,
    required this.animation,
    required this.direction,
    required this.frameCount,
    required this.stepTime,
    required this.loop,
    required this.isComplete,
    required this.entry,
  });

  final String assetId;
  final String category;
  final String subject;
  final String animation;
  final String direction;
  final int frameCount;
  final double stepTime;
  final bool loop;
  final bool isComplete;
  final AssetEntry entry;
}

class SpriteRegistry {
  SpriteRegistry({
    required this.manifest,
    required this.images,
    this.assetsBasePath = 'assets/sprites',
  });

  final AssetManifest manifest;
  final Images images;
  final String assetsBasePath;

  final Map<String, SpriteAnimation> _animations = {};
  final Map<String, SpriteAnimationData> _data = {};
  final List<String> _loadErrors = [];

  Iterable<String> get animationIds => _animations.keys;
  List<String> get loadErrors => List.unmodifiable(_loadErrors);

  bool hasAnimation(String assetId) => _animations.containsKey(assetId);

  SpriteAnimation? getAnimation(String assetId) => _animations[assetId];

  SpriteAnimationData? getData(String assetId) => _data[assetId];

  SpriteAnimation? resolve(VisualState state) => _animations[state.assetId];

  Future<void> load({
    Set<String> categories = const {'character', 'entity', 'prop'},
  }) async {
    for (final entry in manifest.assets) {
      if (!categories.contains(entry.category)) continue;
      if (entry.isTileset) continue;
      await _loadEntry(entry);
    }
  }

  Future<void> _loadEntry(AssetEntry entry) async {
    try {
      final frameFiles = _frameFiles(entry);
      final sprites = <Sprite>[];
      for (final file in frameFiles) {
        sprites.add(await _loadSprite(entry, file));
      }
      if (sprites.isEmpty) return;

      final declaredFrames = entry.frames ?? sprites.length;
      final stepTime = (entry.frameDuration ?? 100) / 1000;
      _animations[entry.id] = SpriteAnimation.spriteList(
        sprites,
        stepTime: stepTime,
        loop: entry.loop ?? false,
      );
      _data[entry.id] = SpriteAnimationData(
        assetId: entry.id,
        category: entry.category,
        subject: entry.subject,
        animation: entry.animation ?? 'default',
        direction: entry.direction ?? '',
        frameCount: sprites.length,
        stepTime: stepTime,
        loop: entry.loop ?? false,
        isComplete: sprites.length == declaredFrames,
        entry: entry,
      );
    } catch (error) {
      _loadErrors.add('${entry.id}: $error');
    }
  }

  Future<Sprite> _loadSprite(AssetEntry entry, String file) async {
    final key = p.posix.join(assetsBasePath, file);
    final image = await images.load(key);
    final region = entry.sourceRegion;
    if (region != null) {
      return Sprite(
        image,
        srcPosition: Vector2(
          (region['x'] ?? 0).toDouble(),
          (region['y'] ?? 0).toDouble(),
        ),
        srcSize: Vector2(
          (region['width'] ?? entry.width).toDouble(),
          (region['height'] ?? entry.height).toDouble(),
        ),
      );
    }
    return Sprite(image);
  }

  List<String> _frameFiles(AssetEntry entry) {
    final raw = entry.metadata['frame_files'];
    if (raw is List) {
      return raw.map((value) => value.toString()).toList(growable: false);
    }
    return [entry.file];
  }
}

extension on AssetEntry {
  String get subject {
    if (character != null) return character!;
    if (entity != null) return entity!;
    final parts = file.split('/').where((part) => part.isNotEmpty).toList();
    if (parts.length < 2) return category;
    return parts[parts.length - 2];
  }
}
