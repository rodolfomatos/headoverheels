import 'dart:io';

import 'package:iso_core/iso_core.dart';

import '../knight.dart';
import '../world/knight_lore_world.dart';

/// The asset manifest for Knight Lore, written in the same format the
/// Head over Heels assets use so `iso_core`'s registry and the editor's sprite
/// manager can both read it.
class KnightLoreManifest {
  const KnightLoreManifest._();

  static const String manifestKey = 'assets/sprites/manifest.yaml';
  static const String spritesBasePath = 'assets/sprites';
  static const String tilesBasePath = 'assets/world/tiles';

  /// Every trigger type that has art, in the order the manifest lists them.
  static const List<String> propTypes = [
    'ball',
    'cauldron',
    'chest',
    'diamond',
    'portcullis',
    'statue',
    'witch',
    'wizard',
  ];

  static AssetManifest build() {
    final assets = <AssetEntry>[
      AssetEntry(
        id: 'character.sabreman.idle.down',
        file: 'knights/sabreman_idle.png',
        category: 'character',
        character: 'sabreman',
        animation: 'idle',
        direction: 'down',
        runtimeSize: const {'width': 80, 'height': 32},
        anchor: const {'x': 40, 'y': 31},
        alpha: AssetAlphaMode.smooth.name,
        palette: 'base',
        scale: 1,
        frames: 4,
        frameDuration: 160,
        loop: true,
      ),
      for (final knight in splitKnights)
        AssetEntry(
          id: 'character.${knight.id}.walk.down',
          file: 'knights/${knight.id}_walk.png',
          category: 'character',
          character: knight.id,
          animation: 'walk',
          direction: 'down',
          runtimeSize: const {'width': 80, 'height': 32},
          anchor: const {'x': 40, 'y': 31},
          alpha: AssetAlphaMode.smooth.name,
          palette: 'base',
          scale: 1,
          frames: 4,
          frameDuration: 120,
          loop: true,
        ),
      for (final area in KlAreas.all)
        for (final prop in propTypes)
          AssetEntry(
            id: 'prop.$prop.${area == 'tower' ? 'static' : 'idle'}.down',
            file: 'props/${prop}_$area.png',
            category: 'prop',
            entity: prop,
            theme: area,
            runtimeSize: const {'width': 32, 'height': 32},
            anchor: const {'x': 16, 'y': 31},
            alpha: AssetAlphaMode.smooth.name,
            palette: 'base',
            scale: 1,
            metadata: {'variant': area},
          ),
    ];
    return AssetManifest(version: '1.0', assets: assets);
  }

  /// The tileset image for an area, keyed by the area id used in the world.
  static String tilesetFor(String area) => '$tilesBasePath/$area.png';

  /// The sprite sheet for a prop in an area.
  static String spriteFor(String prop, String area) =>
      '$spritesBasePath/props/${prop}_$area.png';

  /// The character sheet for a knight class.
  static String characterFor(KnightClass knight) =>
      '$spritesBasePath/knights/${knight.id}_${knight == KnightClass.sabreman ? 'idle' : 'walk'}.png';

  /// Writes the manifest next to the game.
  static String write({String? path}) {
    final file = File(path ?? manifestKey);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(build().toYaml());
    return file.path;
  }
}
