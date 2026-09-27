/// Knight Lore, the second example game on the reusable `iso_core` runtime.
///
/// This package holds the game specific data and rules only: the knight
/// classes, the spells, the sixteen slot inventory, the curse rules and the
/// world definition. Everything generic (coordinates, physics, world graph,
/// assets, rendering helpers) lives in `iso_core`.
library;

export 'src/curse.dart';
export 'src/inventory.dart';
export 'src/knight.dart';
export 'src/spells.dart';
export 'src/world/knight_lore_world.dart';
export 'src/world/room_maps.dart';
export 'src/game/room_session.dart';
export 'src/game/terrain.dart';
export 'src/assets/knight_lore_manifest.dart';
export 'src/game/knight_lore_game.dart';
export 'src/render/room_view.dart';
export 'src/ui/knight_lore_screen.dart';
export 'src/world/items.dart';
export 'src/game/hazards.dart';
