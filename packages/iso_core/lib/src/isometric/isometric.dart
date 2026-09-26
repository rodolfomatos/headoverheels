// Isometric coordinate system for 2:1 dimetric projection.
// Based on classic 8-bit isometric games (Head over Heels, Knight Lore, etc.)
// Tile dimensions: 64x32 logical pixels (2:1 ratio)

import 'dart:math' as math;
import 'dart:ui' show Rect;
import 'package:vector_math/vector_math.dart';

/// Logical tile dimensions
const double kTileWidth = 64.0;
const double kTileHeight = 32.0;
const double kLevelHeight = 32.0;

/// Convert grid coordinates to screen coordinates.
/// [grid] - Vector3(x, y, z) where x,y are tile coordinates, z is height level
/// Returns screen position (top-left of tile diamond)
Vector2 gridToScreen(Vector3 grid) {
  final x = (grid.x - grid.y) * kTileWidth / 2;
  final y = (grid.x + grid.y) * kTileHeight / 2 - grid.z * kLevelHeight;
  return Vector2(x, y);
}

/// Convert screen coordinates to grid coordinates (level 0).
Vector3 screenToGrid(Vector2 screen) {
  final halfTileW = kTileWidth / 2;
  final halfTileH = kTileHeight / 2;
  final gridX = (screen.x / halfTileW + screen.y / halfTileH) / 2;
  final gridY = (screen.y / halfTileH - screen.x / halfTileW) / 2;
  return Vector3(gridX.roundToDouble(), gridY.roundToDouble(), 0.0);
}

/// Convert screen to grid at specific height level.
Vector3 screenToGridAtLevel(Vector2 screen, int level) {
  final halfTileW = kTileWidth / 2;
  final halfTileH = kTileHeight / 2;
  final levelOffset = level * kLevelHeight;
  final adjustedY = screen.y + levelOffset;
  final gridX = (screen.x / halfTileW + adjustedY / halfTileH) / 2;
  final gridY = (adjustedY / halfTileH - screen.x / halfTileW) / 2;
  return Vector3(
    gridX.roundToDouble(),
    gridY.roundToDouble(),
    level.toDouble(),
  );
}

/// Get screen bounds of a tile at given grid position.
Rect getTileBounds(Vector3 grid) {
  final pos = gridToScreen(grid);
  return Rect.fromLTWH(pos.x, pos.y, kTileWidth, kTileHeight);
}

/// Get the four screen corners of a tile (for diamond drawing).
List<Vector2> getTileCorners(Vector3 grid) {
  final center = gridToScreen(grid);
  final hw = kTileWidth / 2;
  final hh = kTileHeight / 2;
  return [
    Vector2(center.x, center.y - hh), // Top
    Vector2(center.x + hw, center.y), // Right
    Vector2(center.x, center.y + hh), // Bottom
    Vector2(center.x - hw, center.y), // Left
  ];
}

/// Snap a world position to the nearest grid position.
Vector3 snapToGrid(Vector3 world) {
  return Vector3(
    world.x.roundToDouble(),
    world.y.roundToDouble(),
    world.z.roundToDouble(),
  );
}

/// Check if a grid position is within room bounds.
bool isInRoomBounds(Vector3 grid, {int roomWidth = 16, int roomHeight = 16}) {
  return grid.x >= 0 &&
      grid.x < roomWidth &&
      grid.y >= 0 &&
      grid.y < roomHeight;
}

/// Get neighbor grid position in given direction.
Vector3 neighbor(Vector3 grid, Direction8 dir) {
  final offset = _directionOffsets[dir.index];
  return grid + Vector3(offset.x.toDouble(), offset.y.toDouble(), 0);
}

/// 8-directional offsets for isometric grid.
final List<Vector2> _directionOffsets = [
  Vector2(0, -1), // N
  Vector2(1, -1), // NE
  Vector2(1, 0), // E
  Vector2(1, 1), // SE
  Vector2(0, 1), // S
  Vector2(-1, 1), // SW
  Vector2(-1, 0), // W
  Vector2(-1, -1), // NW
];

/// 8-directional movement for isometric grid.
enum Direction8 {
  north,
  northEast,
  east,
  southEast,
  south,
  southWest,
  west,
  northWest;

  /// Convert from angle (radians) to nearest direction.
  static Direction8 fromAngle(double angle) {
    while (angle < 0) {
      angle += 2 * 3.14159265359;
    }
    while (angle >= 2 * 3.14159265359) {
      angle -= 2 * 3.14159265359;
    }
    final index =
        ((angle + math.pi / 2 + math.pi / 8) / (math.pi / 4)).floor() % 8;
    return Direction8.values[index];
  }

  static Direction8 fromVector(Vector2 v) {
    if (v.length2 <= 0.0001) return Direction8.south;
    final angle = math.atan2(v.x, -v.y);
    final index = ((angle / (math.pi / 4)).round() + 8) % 8;
    return Direction8.values[index];
  }

  static Direction8 fromVectorAngle(Vector2 v) => fromVector(v);

  Vector2 get vector {
    switch (this) {
      case Direction8.north:
        return Vector2(0, -1);
      case Direction8.northEast:
        return Vector2(1, -1);
      case Direction8.east:
        return Vector2(1, 0);
      case Direction8.southEast:
        return Vector2(1, 1);
      case Direction8.south:
        return Vector2(0, 1);
      case Direction8.southWest:
        return Vector2(-1, 1);
      case Direction8.west:
        return Vector2(-1, 0);
      case Direction8.northWest:
        return Vector2(-1, -1);
    }
  }

  Direction8 get opposite => Direction8.values[(index + 4) % 8];
}

/// Facing direction for character sprites (8 directional).
enum FacingDirection {
  north,
  northEast,
  east,
  southEast,
  south,
  southWest,
  west,
  northWest;

  static FacingDirection fromDirection8(Direction8 dir) =>
      FacingDirection.values[dir.index];

  int get spriteRow => index;
}
