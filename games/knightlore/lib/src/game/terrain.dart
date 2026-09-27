/// Walkable/blocked map for a room, in grid tiles.
///
/// The renderer reads the TMX tile layer; the simulation only needs to know
/// which tiles block movement, so both sides share this value object and the
/// rules stay testable without loading a map.
class RoomTerrain {
  RoomTerrain(this.width, this.height, List<bool> blocked)
      : blocked = List<bool>.unmodifiable(blocked) {
    if (blocked.length != width * height) {
      throw ArgumentError(
        'blocked must hold width*height entries, '
        'got ${blocked.length} for ${width}x$height',
      );
    }
  }

  final int width;
  final int height;
  final List<bool> blocked;

  bool isBlocked(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return true;
    return blocked[y * width + x];
  }

  /// A room with no obstacles.
  factory RoomTerrain.open(int width, int height) =>
      RoomTerrain(width, height, List<bool>.filled(width * height, false));

  /// Builds a terrain from rows of `#` (blocked) and `.` (walkable).
  factory RoomTerrain.fromRows(List<String> rows) {
    final height = rows.length;
    final width = rows.isEmpty ? 0 : rows.first.length;
    final blocked = <bool>[];
    for (final row in rows) {
      if (row.length != width) {
        throw ArgumentError('every row must be $width characters wide');
      }
      for (final code in row.codeUnits) {
        blocked.add(code == 0x23); // '#'
      }
    }
    return RoomTerrain(width, height, blocked);
  }
}
