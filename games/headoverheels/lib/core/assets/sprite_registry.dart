// Sprite Registry for Head over Heels
// Central registry for all sprite animations and atlas frames.

import 'dart:async';

import 'dart:ui' show Image;

import 'package:flame/cache.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:iso_core/iso_core.dart' show AssetEntry, AssetManifest;

/// Where the sprites are, and the file that says which ones there are. Both are
/// the paths the pubspec publishes and a person reads.
const String spritesRoot = 'assets/sprites';
const String manifestKey = '$spritesRoot/manifest.yaml';

/// Central registry for all sprite animations and atlas frames.
class SpriteRegistry {
  final Map<String, SpriteAnimation> _animations = {};
  final Map<String, Sprite> _sprites = {};

  // Asset ID -> SpriteAnimationData mapping
  final Map<String, SpriteAnimationData> _animationData = {};

  /// The manifest ids that are loaded, so nothing is asked for twice.
  final Set<String> _loaded = {};

  /// The images this game loads, with no prefix of their own.
  ///
  /// Flame's shared [Flame.images] prefixes `assets/images/`, and the frames
  /// below are named from the bundle root, so every sprite asked for
  /// `assets/images/assets/sprites/...`: a file that has never existed. The
  /// catch that ends the frame loop then hid it, and the animations came out
  /// empty, so the party drew nothing at all.
  final Images _images = Images(prefix: '');

  static final SpriteRegistry _instance = SpriteRegistry._internal();
  factory SpriteRegistry() => _instance;
  SpriteRegistry._internal();

  /// Loads every sprite the manifest lists.
  ///
  /// The manifest is the truth: it names the file for each sprite, the
  /// animation, the direction and the timing, and the editor reads the same one.
  /// This used to rebuild that knowledge in Dart: it guessed file names from the
  /// character, the animation and the direction, with `n`, `ne`, `e` and `s` in
  /// the name where the art says `front`, `3q`, `side` and `back`. Every one of
  /// those guesses missed, the frame loop ended on the first miss, and the party
  /// had no sprites at all. The four other loaders below were empty, so entities,
  /// props, tiles, UI and effects were never loaded either.
  Future<void> initialize() async {
    await _loadWhere((_) => true);
  }

  /// Loads the sprites of one character: `head`, `heels` or `duo`.
  ///
  /// The party waits for this and for nothing else. Waiting for all 65 entries
  /// meant the first frame of the game came after every sprite in the project,
  /// which on a slow machine is a minute of black screen: `GameWidget` draws
  /// nothing until the game's load is finished, so the room the player is
  /// standing in waited for props and effects nobody is looking at.
  Future<void> loadCharacter(String character) async {
    await _loadWhere((entry) => entry.character == character);
  }

  /// Loads the sprites of one entity type, for the same reason: a room asks for
  /// what is in it.
  Future<void> loadEntity(String entity) async {
    await _loadWhere((entry) => entry.entity == entity);
  }

  /// Loads every entry [wanted] accepts, skipping the ones already loaded.
  ///
  /// Loading is idempotent on purpose: the party loads its own sprites while the
  /// room loads, and the rest of the manifest arrives afterwards without asking
  /// for the same file twice.
  Future<void> _loadWhere(bool Function(AssetEntry entry) wanted) async {
    final manifest = await _readManifest();
    for (final entry in manifest.assets) {
      if (!wanted(entry)) continue;
      if (_loaded.contains(entry.id)) continue;
      await _load(entry);
    }
  }

  Future<AssetManifest> _readManifest() async {
    final source = await rootBundle.loadString(manifestKey);
    return AssetManifest.fromYaml(source);
  }

  /// Loads one manifest entry, as a sprite and, when it is an animation, as an
  /// animation too.
  Future<void> _load(AssetEntry entry) async {
    final path = '$spritesRoot/${entry.file}';
    final Image image;
    try {
      image = await _images.load(path);
    } catch (error) {
      // A file the manifest names but the bundle does not have is a real fault,
      // and a silent one: an animation with no frames draws nothing, which looks
      // exactly like a game that has not loaded.
      throw StateError(
        'The manifest names $path for ${entry.id}, and it is '
        'not there: $error',
      );
    }

    _sprites[entry.id] = Sprite(image);
    _loaded.add(entry.id);

    final animation = entry.animation;
    final character = entry.character;
    if (animation == null || character == null) return;

    // The manifest says how many frames an animation has. The art has one image
    // per animation and direction, so that is what an animation is here: one
    // frame, the file the manifest names. The frames it promises are T063.
    final frames = <Sprite>[Sprite(image)];
    _animations[entry.id] = SpriteAnimation.spriteList(
      frames,
      stepTime: _getStepTime(animation),
    );
    _animationData[entry.id] = SpriteAnimationData(
      assetId: entry.id,
      character: character,
      animation: animation,
      direction: entry.direction ?? '',
      frameCount: frames.length,
      stepTime: _getStepTime(animation),
      loop: entry.loop ?? _shouldLoop(animation),
    );
  }

  double _getStepTime(String animation) {
    switch (animation) {
      case 'idle':
        return 0.2;
      case 'walk':
        return 0.1;
      case 'run':
        return 0.075;
      case 'jump':
      case 'jumpRise':
      case 'jumpPeak':
      case 'jumpFall':
        return 0.15;
      case 'land':
        return 0.1;
      case 'climb':
        return 0.2;
      case 'carry':
        return 0.2;
      case 'fire':
        return 0.1;
      case 'swop':
        return 0.15;
      case 'hurt':
        return 0.1;
      case 'death':
        return 0.2;
      default:
        return 0.1;
    }
  }

  bool _shouldLoop(String animation) {
    switch (animation) {
      case 'idle':
      case 'walk':
      case 'run':
      case 'climb':
      case 'carry':
        return true;
      case 'jump':
      case 'jumpRise':
      case 'jumpPeak':
      case 'jumpFall':
      case 'land':
      case 'fire':
      case 'swop':
      case 'hurt':
      case 'death':
        return false;
      default:
        return true;
    }
  }

  /// Get a character animation by asset ID.
  SpriteAnimation? getCharacterAnimation(String assetId) {
    return _animations[assetId];
  }

  /// Get animation data by asset ID.
  SpriteAnimationData? getAnimationData(String assetId) {
    return _animationData[assetId];
  }

  /// Get a single sprite by ID.
  Sprite? getSprite(String assetId) {
    return _sprites[assetId];
  }

  /// Get all registered animation IDs.
  Iterable<String> get animationIds => _animations.keys;

  /// Check if an animation exists.
  bool hasAnimation(String assetId) => _animations.containsKey(assetId);

  /// Get animation data for debugging.
  Map<String, SpriteAnimationData> get animationData =>
      Map.unmodifiable(_animationData);
}

/// Data class for sprite animation metadata.
class SpriteAnimationData {
  final String assetId;
  final String character;
  final String animation;
  final String direction;
  final int frameCount;
  final double stepTime;
  final bool loop;

  const SpriteAnimationData({
    required this.assetId,
    required this.character,
    required this.animation,
    required this.direction,
    required this.frameCount,
    required this.stepTime,
    required this.loop,
  });

  @override
  String toString() {
    return 'SpriteAnimationData(assetId: $assetId, frames: $frameCount, stepTime: ${stepTime}s, loop: $loop)';
  }
}
