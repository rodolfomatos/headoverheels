// Sprite Registry for Head over Heels
// Central registry for all sprite animations and atlas frames.

import 'dart:async';

import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';
import 'package:headoverheels/entities/character_state.dart';

/// Central registry for all sprite animations and atlas frames.
class SpriteRegistry {
  final Map<String, SpriteAnimation> _animations = {};
  final Map<String, Sprite> _sprites = {};

  // Asset ID -> SpriteAnimationData mapping
  final Map<String, SpriteAnimationData> _animationData = {};

  static final SpriteRegistry _instance = SpriteRegistry._internal();
  factory SpriteRegistry() => _instance;
  SpriteRegistry._internal();

  /// Initialize the registry with all sprite assets.
  Future<void> initialize() async {
    await _loadCharacterAnimations();
    await _loadEntityAnimations();
    await _loadTileAnimations();
    await _loadUIAnimations();
    await _loadEffectAnimations();
  }

  Future<void> _loadCharacterAnimations() async {
    // Head animations
    await _loadCharacterAnimationsForType('head', CharacterType.head);
    // Heels animations
    await _loadCharacterAnimationsForType('heels', CharacterType.heels);
    // Combined/Duo animations
    await _loadCharacterAnimationsForType('duo', CharacterType.combined);
  }

  Future<void> _loadCharacterAnimationsForType(
    String character,
    CharacterType type,
  ) async {
    final animations = <String, List<String>>{
      'idle': ['n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw'],
      'walk': ['n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw'],
      'run': ['n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw'],
      'jump': ['n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw'],
      'jumpRise': ['n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw'],
      'jumpPeak': ['n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw'],
      'jumpFall': ['n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw'],
      'land': ['n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw'],
      'climb': ['n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw'],
      'carry': ['n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw'],
      'fire': ['n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw'],
      'swop': ['n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw'],
      'hurt': ['n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw'],
      'death': ['n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw'],
    };

    for (final entry in animations.entries) {
      final animName = entry.key;
      final directions = entry.value;

      for (final direction in directions) {
        final assetId = 'character.$character.$animName.$direction';
        await _loadAnimation(assetId, character, animName, direction);
      }
    }
  }

  Future<void> _loadAnimation(
    String assetId,
    String character,
    String animName,
    String direction,
  ) async {
    // Try to load from individual frames first
    final frames = <Sprite>[];
    int frameIndex = 1;

    while (true) {
      // assetId format: character.head.idle.n -> extract base name
      final parts = assetId.split('.');
      final baseName = parts.sublist(1, parts.length - 1).join('_');
      final frameName =
          'assets/sprites/characters/$character/frames/${character}_${animName}_${direction}_${frameIndex.toString().padLeft(2, '0')}.png';

      try {
        final image = await Flame.images.load(frameName);
        final sprite = Sprite(image);
        frames.add(sprite);
        frameIndex++;
      } catch (e) {
        break; // No more frames
      }
    }

    if (frames.isNotEmpty) {
      final animation = SpriteAnimation.spriteList(
        frames,
        stepTime: _getStepTime(animName),
      );
      _animations[assetId] = animation;
      _animationData[assetId] = SpriteAnimationData(
        assetId: assetId,
        character: character,
        animation: animName,
        direction: direction,
        frameCount: frames.length,
        stepTime: _getStepTime(animName),
        loop: _shouldLoop(animName),
      );
    }
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

  Future<void> _loadEntityAnimations() async {
    // TODO: Implement entity animations loading
  }

  Future<void> _loadTileAnimations() async {
    // TODO: Implement tile animations loading
  }

  Future<void> _loadUIAnimations() async {
    // TODO: Implement UI animations loading
  }

  Future<void> _loadEffectAnimations() async {
    // TODO: Implement effect animations loading
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
