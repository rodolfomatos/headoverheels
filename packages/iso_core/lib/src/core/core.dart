import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import '../assets/assets.dart';
import '../input/input.dart';
import '../levels/levels.dart';
import '../physics/physics.dart';
import '../rendering/rendering.dart';

class IsoRuntimeConfig {
  const IsoRuntimeConfig({
    this.manifestKey = 'assets/sprites/manifest.yaml',
    this.paletteKey = 'style/palette.json',
    this.geometryKey = 'style/geometry.json',
    this.worldKey = 'assets/levels/world.json',
    this.roomsBasePath = 'assets/levels/rooms',
    this.assetsBasePath = 'assets/sprites',
  });

  final String manifestKey;
  final String paletteKey;
  final String geometryKey;
  final String worldKey;
  final String roomsBasePath;
  final String assetsBasePath;
}

class IsoRuntime {
  IsoRuntime._({
    required this.bundle,
    required this.assets,
    required this.sprites,
    required this.worldGraph,
    required this.worldLoader,
    required this.physics,
    required this.input,
  });

  static Future<IsoRuntime> load(
    AssetBundle bundle,
    Component parent, {
    IsoRuntimeConfig config = const IsoRuntimeConfig(),
  }) async {
    final assets = await AssetPipeline.load(
      bundle,
      manifestKey: config.manifestKey,
      paletteKey: config.paletteKey,
      geometryKey: config.geometryKey,
      assetsBasePath: config.assetsBasePath,
    );
    final sprites = SpriteRegistry(
      manifest: assets.manifest,
      images: Images(prefix: '', bundle: bundle),
      assetsBasePath: config.assetsBasePath,
    );
    final worldGraph = await WorldGraph.load(
      config.worldKey,
      source: AssetBundleWorldDataSource(bundle),
    );
    return IsoRuntime._(
      bundle: bundle,
      assets: assets,
      sprites: sprites,
      worldGraph: worldGraph,
      worldLoader: WorldLoader(
        worldGraph: worldGraph,
        roomsBasePath: config.roomsBasePath,
        parent: parent,
      ),
      physics: PhysicsWorld(),
      input: InputRouter(),
    );
  }

  final AssetBundle bundle;
  final AssetPipeline assets;
  final SpriteRegistry sprites;
  final WorldGraph worldGraph;
  final WorldLoader worldLoader;
  final PhysicsWorld physics;
  final InputRouter input;

  Future<void> loadSprites() => sprites.load();
}
