/// A game the editor can open.
///
/// The editor is built for one game at a time, but both games on this platform
/// keep the same layout, so which game is open is data: a name, where its world
/// is, where its sprite manifest is, and where its maps and tilesets live.
///
/// The paths here are the ones the games themselves use. A test reads the files
/// at these keys, so a project that points at a file nobody writes fails
/// instead of silently opening nothing.
class EditorProject {
  const EditorProject({
    required this.id,
    required this.label,
    required this.worldKey,
    this.manifestKey = 'assets/sprites/manifest.yaml',
    this.assetsBasePath = 'assets/sprites',
    this.roomsBasePath = 'assets/levels/rooms',
    this.tilesetImageBasePath = 'assets/tilesets',
  });

  /// A stable name, used in keys and in tests.
  final String id;

  /// What the picker shows.
  final String label;

  /// The world graph, in the shared `world.json` format.
  final String worldKey;

  /// The sprite manifest, in the shared `manifest.yaml` format.
  final String manifestKey;

  /// Where the sprite sheets are, relative to the manifest.
  final String assetsBasePath;

  /// Where the room maps are.
  final String roomsBasePath;

  /// Where the tileset images are.
  final String tilesetImageBasePath;

  EditorProject copyWith({String? label}) => EditorProject(
    id: id,
    label: label ?? this.label,
    worldKey: worldKey,
    manifestKey: manifestKey,
    assetsBasePath: assetsBasePath,
    roomsBasePath: roomsBasePath,
    tilesetImageBasePath: tilesetImageBasePath,
  );

  /// The first game on the platform, in its own package under games/.
  static const EditorProject headoverheels = EditorProject(
    id: 'headoverheels',
    label: 'Head over Heels',
    worldKey: 'games/headoverheels/assets/levels/world.json',
    manifestKey: 'games/headoverheels/assets/sprites/manifest.yaml',
    assetsBasePath: 'games/headoverheels/assets/sprites',
    roomsBasePath: 'games/headoverheels/assets/levels/rooms',
    tilesetImageBasePath: 'games/headoverheels/assets/images',
  );

  /// The second game, the one that proves the editor is not tailored to one.
  ///
  /// Its files live inside the game package, so every key is prefixed with the
  /// game directory. That is also what makes the two projects differ by one
  /// string, which the test checks.
  static const EditorProject knightLore = EditorProject(
    id: 'knightlore',
    label: 'Knight Lore',
    worldKey: 'games/knightlore/assets/world/knightlore_world.json',
    manifestKey: 'games/knightlore/assets/sprites/manifest.yaml',
    assetsBasePath: 'games/knightlore/assets/sprites',
    roomsBasePath: 'games/knightlore/assets/world/rooms',
    tilesetImageBasePath: 'games/knightlore/assets/world/tiles',
  );

  /// Both games, in the order the picker shows them.
  static const List<EditorProject> shipped = [headoverheels, knightLore];

  /// The project with [id], or the first one.
  static EditorProject byId(String? id) => shipped.firstWhere(
    (project) => project.id == id,
    orElse: () => shipped.first,
  );
}
